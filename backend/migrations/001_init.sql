-- AquaPulse backend: schema, functions, views, RLS, Realtime, Storage (document sections 7.2 - 7.5)
create extension if not exists postgis;

-- ---------- enums ----------
create type user_role as enum ('ADMIN','OPERATOR','ENGINEER');
create type data_source as enum ('HARDWARE','TWIN');
create type monitoring_mode as enum ('HARDWARE','SIMULATED');
create type pipe_state as enum ('NORMAL','WARNING','LEAK','ISOLATED','UNDER_REPAIR','PENDING_VERIFICATION');
create type severity_level as enum ('NONE','MINOR','MODERATE','MAJOR','CRITICAL');
create type priority_level as enum ('P1','P2','P3','P4');
create type event_status as enum ('DETECTED','ACKNOWLEDGED','DISPATCHED','IN_PROGRESS','REPAIR_SUBMITTED','CLOSED','FALSE_ALARM');
create type wo_status as enum ('UNASSIGNED','ASSIGNED','ACCEPTED','EN_ROUTE','ON_SITE','SUBMITTED','REWORK','COMPLETED','CANCELLED');
create type engineer_status as enum ('AVAILABLE','ASSIGNED','EN_ROUTE','ON_SITE','OFF_DUTY');
create type device_status as enum ('PROVISIONED','ONLINE','OFFLINE','MAINTENANCE','RETIRED');
create type valve_state as enum ('OPEN','CLOSED','PARTIAL');
create type valve_kind as enum ('ISOLATION','PRV','CHECK','OTHER');
create type node_kind as enum ('JUNCTION','RESERVOIR','TANK');
create type pipe_material as enum ('PVC','HDPE','DI','CI','GI','STEEL','AC','OTHER');
create type advisory_status as enum ('OPEN','ACKNOWLEDGED','ISOLATED','RESTORED','DISMISSED');
create type advisory_urgency as enum ('IMMEDIATE','RECOMMENDED','ADVISORY');
create type evidence_kind as enum ('BEFORE_PHOTO','AFTER_PHOTO');
create type twin_cmd_type as enum ('SET_PIPE_STATE','SET_VALVE_STATE','INJECT_LEAK','CLEAR_LEAK','RESET_PIPE_NORMAL');
create type twin_cmd_status as enum ('PENDING','DELIVERED','APPLIED','FAILED');
create type notif_type as enum ('LEAK_DETECTED','SEVERITY_ESCALATED','ISOLATION_ADVISORY','WO_ASSIGNED','WO_SUBMITTED','WO_APPROVED','WO_REJECTED','DEVICE_OFFLINE');

create sequence leak_event_seq;
create sequence work_order_seq;

create function set_updated_at() returns trigger language plpgsql as
$$ begin new.updated_at = now(); return new; end $$;

-- ---------- people ----------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null, role user_role not null, phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table engineers (
  profile_id uuid primary key references profiles(id) on delete cascade,
  employee_code text not null unique,
  status engineer_status not null default 'OFF_DUTY',
  skills text[] not null default '{}',               -- e.g. {PIPE_REPAIR,HDPE_WELD,VALVE}
  max_active_jobs smallint not null default 1 check (max_active_jobs > 0),
  shift_start time, shift_end time,
  last_location geography(Point,4326), last_location_at timestamptz
);

create table device_tokens (                          -- mobile push tokens (FCM)
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('ANDROID','IOS','WEB')),
  created_at timestamptz not null default now()
);

-- ---------- network master data ----------
create table dmas (
  id uuid primary key default gen_random_uuid(),
  code text not null unique, name text not null,
  boundary geography(Polygon,4326)
);

create table network_nodes (
  id uuid primary key default gen_random_uuid(),
  dma_id uuid not null references dmas(id),
  code text not null unique, kind node_kind not null default 'JUNCTION',
  geom geography(Point,4326) not null,
  elevation_m numeric(7,2), base_demand_lps numeric(9,4) not null default 0,
  served_connections integer not null default 0
);

create table pipe_segments (
  id uuid primary key default gen_random_uuid(),
  dma_id uuid not null references dmas(id),
  code text not null unique,
  from_node uuid not null references network_nodes(id),
  to_node uuid not null references network_nodes(id),
  geom geography(LineString,4326) not null,
  length_m numeric(9,2) not null, diameter_mm integer not null,
  material pipe_material not null, install_year smallint,
  pressure_class text, hazen_williams_c smallint,
  design_flow_lpm numeric(10,2) not null,
  monitoring monitoring_mode not null default 'SIMULATED',
  state pipe_state not null default 'NORMAL',
  state_since timestamptz not null default now(),
  active_event_id uuid,                               -- FK added after leak_events
  check (from_node <> to_node)
);
create index pipe_segments_geom_gix on pipe_segments using gist (geom);

create table valves (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  pipe_id uuid not null references pipe_segments(id),
  at_node uuid not null references network_nodes(id), -- valve sits on pipe_id at this end
  kind valve_kind not null default 'ISOLATION',
  geom geography(Point,4326) not null,
  state valve_state not null default 'OPEN',
  remote_controllable boolean not null default false, -- reserved; remote actuation disabled in v1
  state_updated_at timestamptz not null default now()
);

-- ---------- Tunnel A: hardware ----------
create table devices (
  id uuid primary key default gen_random_uuid(),
  device_uid text not null unique,
  pipe_id uuid not null references pipe_segments(id),
  status device_status not null default 'PROVISIONED',
  token_hash text not null,                           -- SHA-256 of the device token
  firmware_version text,
  report_interval_s smallint not null default 5 check (report_interval_s between 1 and 3600),
  position geography(Point,4326),
  calibration jsonb not null default '{}',            -- e.g. {"FLOW_IN":{"pulses_per_litre":450,"offset_lpm":0}}
  last_seen_at timestamptz,
  created_at timestamptz not null default now()
);
create index devices_token_hash_idx on devices (token_hash);

create table device_sensors (
  device_id uuid references devices(id) on delete cascade,
  sensor text check (sensor in ('FLOW_IN','FLOW_OUT','PRESSURE_IN','PRESSURE_OUT','ACOUSTIC_RMS')),
  model text, unit text not null,
  primary key (device_id, sensor)
);

create table hw_readings (
  id bigint generated always as identity primary key,
  device_id uuid not null references devices(id),
  pipe_id uuid not null references pipe_segments(id),
  boot_id text not null, seq bigint not null,
  recorded_at timestamptz not null, received_at timestamptz not null default now(),
  flow_in_lpm real, flow_out_lpm real, pressure_in_kpa real, pressure_out_kpa real, acoustic_rms real,
  quality jsonb not null default '{}',                -- per-sensor GOOD/UNCERTAIN/BAD
  edge jsonb, health jsonb,
  unique (device_id, boot_id, seq)
);
create index hw_readings_pipe_time on hw_readings (pipe_id, recorded_at desc);

-- ---------- Tunnel B: digital twin ----------
create table twin_runs (
  id uuid primary key default gen_random_uuid(),
  name text not null, scenario text, network_version text,
  status text not null default 'RUNNING' check (status in ('RUNNING','STOPPED')),
  started_at timestamptz not null default now(), stopped_at timestamptz
);

create table twin_pipe_readings (
  id bigint generated always as identity primary key,
  run_id uuid not null references twin_runs(id),
  pipe_id uuid not null references pipe_segments(id),
  sim_time timestamptz not null, received_at timestamptz not null default now(),
  flow_in_lpm real, flow_out_lpm real, pressure_in_kpa real, pressure_out_kpa real, velocity_mps real,
  injected_leak_lpm real                              -- ground truth: training/evaluation ONLY
);
create index twin_readings_pipe_time on twin_pipe_readings (pipe_id, sim_time desc);

-- ---------- signal support ----------
create table signal_latest (                          -- one row per pipe per source; drives live gauges
  pipe_id uuid not null references pipe_segments(id),
  source data_source not null,
  ts timestamptz not null,
  flow_in_lpm real, flow_out_lpm real, pressure_in_kpa real, pressure_out_kpa real, acoustic_rms real,
  primary key (pipe_id, source)
);

create table pipe_baselines (                         -- expected behaviour by day-of-week and hour
  pipe_id uuid not null references pipe_segments(id),
  source data_source not null,
  dow smallint not null check (dow between 0 and 6),
  hour smallint not null check (hour between 0 and 23),
  flow_in_mean_lpm real, flow_in_std_lpm real,
  delta_q_mean_lpm real, delta_q_std_lpm real,
  pressure_in_mean_kpa real, pressure_in_std_kpa real,
  samples integer not null default 0, updated_at timestamptz not null default now(),
  primary key (pipe_id, source, dow, hour)
);

-- ---------- ML ----------
create table ml_models (
  id uuid primary key default gen_random_uuid(),
  name text not null, version text not null,
  task text not null check (task in ('ANOMALY','SEVERITY')),
  artifact_path text not null,                        -- Storage bucket ml-models
  feature_spec jsonb not null, metrics jsonb, trained_on text,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  unique (name, version)
);
create unique index one_active_model_per_task on ml_models (task) where is_active;

create table ml_inferences (
  id bigint generated always as identity primary key,
  pipe_id uuid not null references pipe_segments(id),
  source data_source not null,
  window_end timestamptz not null,
  anomaly_model_id uuid references ml_models(id),
  severity_model_id uuid references ml_models(id),
  features jsonb not null,
  anomaly_score real not null, is_anomaly boolean not null,
  est_leak_rate_lpm real, severity_score real, severity severity_level,
  confidence real,
  created_at timestamptz not null default now()
);
create index ml_inferences_pipe_time on ml_inferences (pipe_id, window_end desc);

-- ---------- incidents ----------
create table leak_events (
  id uuid primary key default gen_random_uuid(),
  event_no text not null unique default ('LK-' || to_char(now(),'YYYY') || '-' || lpad(nextval('leak_event_seq')::text, 6, '0')),
  source data_source not null,
  pipe_id uuid not null references pipe_segments(id),
  device_id uuid references devices(id),
  twin_run_id uuid references twin_runs(id),
  status event_status not null default 'DETECTED',
  severity severity_level not null,
  severity_score real not null check (severity_score between 0 and 1),
  priority priority_level not null,
  est_leak_rate_lpm real, est_loss_pct real,
  confidence real check (confidence between 0 and 1),
  location geography(Point,4326) not null,
  search_geom geography(LineString,4326),
  chainage_m numeric(9,2),
  location_method text not null check (location_method in ('SEGMENT_MIDPOINT','SEGMENT_CHAINAGE','TWIN_RANKED')),
  candidate_pipes jsonb,                              -- ranked list when location comes from the twin
  trigger_inference_id bigint references ml_inferences(id),
  parameters jsonb not null,                          -- ML/physical parameters at detection (see 6.4)
  detected_at timestamptz not null default now(),
  acknowledged_at timestamptz, acknowledged_by uuid references profiles(id),
  closed_at timestamptz, false_alarm_reason text,
  recurrence_of uuid references leak_events(id),
  updated_at timestamptz not null default now()
);
create unique index one_open_event_per_pipe on leak_events (pipe_id)
  where status not in ('CLOSED','FALSE_ALARM');
create index leak_events_status_time on leak_events (status, detected_at desc);

alter table pipe_segments add constraint pipe_active_event_fk
  foreign key (active_event_id) references leak_events(id);

create table twin_commands (
  id uuid primary key default gen_random_uuid(),
  type twin_cmd_type not null,
  pipe_id uuid references pipe_segments(id),
  valve_id uuid references valves(id),
  params jsonb not null default '{}',
  leak_event_id uuid references leak_events(id),
  status twin_cmd_status not null default 'PENDING',
  created_by uuid references profiles(id),            -- null = system
  created_at timestamptz not null default now(),
  delivered_at timestamptz, applied_at timestamptz, error text
);
create index twin_commands_pending on twin_commands (created_at) where status in ('PENDING','DELIVERED');

create table isolation_advisories (
  id uuid primary key default gen_random_uuid(),
  leak_event_id uuid not null references leak_events(id),
  urgency advisory_urgency not null,
  status advisory_status not null default 'OPEN',
  affected_connections integer, message text not null,
  created_at timestamptz not null default now(),
  acknowledged_by uuid references profiles(id), acknowledged_at timestamptz,
  isolated_at timestamptz, restored_at timestamptz, dismiss_reason text
);

create table isolation_advisory_valves (
  advisory_id uuid not null references isolation_advisories(id) on delete cascade,
  valve_id uuid not null references valves(id),
  close_confirmed_at timestamptz, close_confirmed_by uuid references profiles(id),
  restore_confirmed_at timestamptz, restore_confirmed_by uuid references profiles(id),
  primary key (advisory_id, valve_id)
);

create table work_orders (
  id uuid primary key default gen_random_uuid(),
  wo_no text not null unique default ('WO-' || to_char(now(),'YYYY') || '-' || lpad(nextval('work_order_seq')::text, 6, '0')),
  leak_event_id uuid not null references leak_events(id),
  status wo_status not null default 'UNASSIGNED',
  priority priority_level not null,
  sla_due_at timestamptz not null,
  assigned_engineer_id uuid references engineers(profile_id),
  assigned_by uuid references profiles(id), assigned_at timestamptz,
  accepted_at timestamptz, en_route_at timestamptz, arrived_at timestamptz, submitted_at timestamptz,
  approved_by uuid references profiles(id), approved_at timestamptz,
  rejection_reason text, rework_count smallint not null default 0,
  repair_type text check (repair_type in ('CLAMP','COUPLING','JOINT_REPAIR','SECTION_REPLACE','VALVE_REPLACE','OTHER')),
  materials jsonb, labour_minutes integer, work_notes text,
  post_repair_check jsonb,                            -- automatic readings comparison shown to the approver
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index one_live_wo_per_event on work_orders (leak_event_id) where status <> 'CANCELLED';
create index work_orders_engineer on work_orders (assigned_engineer_id, status);

create table work_order_assignments (                 -- assignment history incl. the ranking score at the time
  id uuid primary key default gen_random_uuid(),
  work_order_id uuid not null references work_orders(id) on delete cascade,
  engineer_id uuid not null references engineers(profile_id),
  assigned_by uuid not null references profiles(id),
  assigned_at timestamptz not null default now(),
  response text not null default 'PENDING' check (response in ('PENDING','ACCEPTED','DECLINED','REASSIGNED','TIMED_OUT')),
  responded_at timestamptz, decline_reason text,
  score numeric(5,3), score_breakdown jsonb
);

create table repair_evidence (
  id uuid primary key default gen_random_uuid(),
  work_order_id uuid not null references work_orders(id) on delete cascade,
  kind evidence_kind not null,
  storage_path text not null unique,
  mime_type text not null, size_bytes integer, sha256 text,
  captured_at timestamptz, captured_location geography(Point,4326),
  distance_to_leak_m numeric(8,2), geo_valid boolean,  -- computed by the backend
  uploaded_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- ---------- support ----------
create table notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references profiles(id) on delete cascade,
  type notif_type not null, title text not null, body text,
  payload jsonb not null default '{}',                -- {leak_event_id, work_order_id, ...}
  read_at timestamptz, created_at timestamptz not null default now()
);
create index notifications_recipient on notifications (recipient_id, created_at desc);

create table event_log (                              -- append-only audit trail
  id bigint generated always as identity primary key,
  entity_type text not null check (entity_type in ('LEAK_EVENT','WORK_ORDER','ADVISORY','PIPE','DEVICE','TWIN_COMMAND')),
  entity_id uuid not null, action text not null,
  from_status text, to_status text,
  actor_kind text not null check (actor_kind in ('USER','SYSTEM','DEVICE','TWIN')),
  actor_id uuid references profiles(id), payload jsonb,
  created_at timestamptz not null default now()
);
create index event_log_entity on event_log (entity_type, entity_id, created_at);

create table pipe_state_history (
  id bigint generated always as identity primary key,
  pipe_id uuid not null references pipe_segments(id),
  from_state pipe_state, to_state pipe_state not null,
  reason text, leak_event_id uuid references leak_events(id),
  changed_by_kind text not null check (changed_by_kind in ('SYSTEM','USER','TWIN')),
  changed_at timestamptz not null default now()
);

create table app_settings (key text primary key, value jsonb not null, updated_at timestamptz not null default now());

create table public_impact (
  id boolean primary key default true check (id),
  status text not null default 'NORMAL' check (status in ('NORMAL','LEAK')),
  active_leaks integer not null default 0 check (active_leaks >= 0),
  water_lost_l bigint not null default 0 check (water_lost_l >= 0),
  households_affected integer not null default 0 check (households_affected >= 0),
  household_days numeric(12,2) not null default 0 check (household_days >= 0),
  updated_at timestamptz not null default now()
);
insert into public_impact (id) values (true);

create trigger trg_leak_events_updated before update on leak_events for each row execute function set_updated_at();
create trigger trg_work_orders_updated before update on work_orders for each row execute function set_updated_at();

insert into app_settings (key, value) values
 ('detection', '{"eval_interval_s":5,"gate_delta_q_pct":5,"gate_min_delta_q_lpm":1.0,"confirm_windows":3,"warn_score":0.4,"confirm_score":0.6,"burst_pressure_dev_pct":-30,"burst_delta_q_pct":30}'),
 ('severity_cutoffs_loss_pct', '{"MINOR":5,"MODERATE":10,"MAJOR":20,"CRITICAL":40}'),
 ('sla_arrive_minutes', '{"P1":60,"P2":240,"P3":1440,"P4":4320}'),
 ('dispatch', '{"accept_timeout_s":600,"location_max_age_s":900,"max_distance_m":20000}'),
 ('evidence', '{"max_distance_m":50,"max_size_mb":10,"arrival_geofence_m":100}'),
 ('retention_days', '{"hw_readings":90,"twin_pipe_readings":14,"ml_inferences":90}'),
 ('public_impact', '{"lpcd":135,"persons_per_household":4}');
-- All values in app_settings are starting points to be calibrated on the rig and the twin.

-- ======================= 7.3 Database functions =======================
-- Atomic pipe state change + history. All state changes go through this function.
create or replace function fn_set_pipe_state(p_pipe uuid, p_to pipe_state, p_reason text, p_event uuid, p_by text)
returns void language plpgsql as $$
declare v_from pipe_state;
begin
  select state into v_from from pipe_segments where id = p_pipe for update;
  if v_from is null then raise exception 'pipe % not found', p_pipe; end if;
  if v_from = p_to then return; end if;
  update pipe_segments
     set state = p_to, state_since = now(),
         active_event_id = case when p_to = 'NORMAL' then null else coalesce(p_event, active_event_id) end
   where id = p_pipe;
  insert into pipe_state_history (pipe_id, from_state, to_state, reason, leak_event_id, changed_by_kind)
  values (p_pipe, v_from, p_to, p_reason, p_event, p_by);
end $$;

-- Engineer ranking for dispatch (advisory: the operator makes the final choice).
create or replace function rank_engineers(p_event uuid, p_required_skill text default 'PIPE_REPAIR', p_limit int default 5)
returns table (engineer_id uuid, full_name text, status engineer_status, distance_m double precision,
               active_jobs int, has_skill boolean, score numeric)
language sql stable as $$
  with ev as (select location from leak_events where id = p_event),
  load as (
    select assigned_engineer_id as eid, count(*)::int as c
    from work_orders
    where status in ('ASSIGNED','ACCEPTED','EN_ROUTE','ON_SITE','REWORK')
    group by 1
  ),
  cand as (
    select e.profile_id, p.full_name, e.status, e.max_active_jobs,
           case when e.last_location_at > now() - interval '15 minutes'
                then st_distance(e.last_location, ev.location) end as dist,
           coalesce(l.c, 0) as jobs,
           (p_required_skill = any(e.skills)) as has_skill
    from engineers e
    join profiles p on p.id = e.profile_id and p.is_active
    cross join ev
    left join load l on l.eid = e.profile_id
    where e.status <> 'OFF_DUTY'
      and coalesce(l.c, 0) < e.max_active_jobs
      and (e.shift_start is null or e.shift_end is null
           or (now() at time zone 'Asia/Kolkata')::time between e.shift_start and e.shift_end)
  )
  select profile_id, full_name, status, dist, jobs, has_skill,
         round((0.50 * coalesce(greatest(0, 1 - dist / 20000.0), 0)
              + 0.25 * (case when status = 'AVAILABLE' then 1 else 0 end)
              + 0.15 * (1 - jobs::numeric / max_active_jobs)
              + 0.10 * (case when has_skill then 1 else 0 end))::numeric, 3) as score
  from cand order by score desc limit p_limit;
$$;
-- The 20 km proximity range and 15-minute position freshness are scoring constants.
-- Missing/stale GPS removes the proximity bonus but does not make an otherwise eligible engineer undispatchable.

-- ======================= 7.4 Views for the clients =======================
create view v_leak_events_enriched with (security_invoker = true) as
select le.id, le.event_no, le.source, (le.source = 'TWIN') as is_simulated,
       le.status, le.severity, le.priority,
       le.est_leak_rate_lpm, le.est_loss_pct, le.confidence, le.parameters, le.detected_at,
       st_x(le.location::geometry) as lon, st_y(le.location::geometry) as lat,
       ps.code as pipe_code, ps.diameter_mm, ps.material, d.code as dma_code,
       wo.id as work_order_id, wo.wo_no, wo.status as wo_status, wo.sla_due_at,
       wo.assigned_engineer_id, pr.full_name as engineer_name,
       ia.id as advisory_id, ia.status as advisory_status, ia.urgency as advisory_urgency
from leak_events le
join pipe_segments ps on ps.id = le.pipe_id
join dmas d on d.id = ps.dma_id
left join work_orders wo on wo.leak_event_id = le.id and wo.status <> 'CANCELLED'
left join profiles pr on pr.id = wo.assigned_engineer_id
left join lateral (select x.id, x.status, x.urgency from isolation_advisories x
                   where x.leak_event_id = le.id order by x.created_at desc limit 1) ia on true;

create view v_pipe_map with (security_invoker = true) as
select ps.id, ps.code, ps.state, ps.monitoring, ps.diameter_mm, ps.material,
       st_asgeojson(ps.geom::geometry)::jsonb as geometry,
       sl.ts as signal_ts, sl.flow_in_lpm, sl.flow_out_lpm, sl.pressure_in_kpa, sl.pressure_out_kpa
from pipe_segments ps
left join signal_latest sl on sl.pipe_id = ps.id
  and sl.source = case ps.monitoring when 'HARDWARE' then 'HARDWARE'::data_source else 'TWIN'::data_source end;

-- ======================= 7.5 Row-level security, Realtime, Storage =======================
create or replace function auth_role() returns user_role
language sql stable security definer set search_path = public as
$$ select role from public.profiles where id = auth.uid() and is_active $$;

do $$ declare t text; begin
  for t in select tablename from pg_tables where schemaname = 'public' and tablename <> 'spatial_ref_sys' loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- reference data: any signed-in user
create policy read_dmas   on dmas           for select to authenticated using (true);
create policy read_nodes  on network_nodes  for select to authenticated using (true);
create policy read_pipes  on pipe_segments  for select to authenticated using (true);
create policy read_valves on valves         for select to authenticated using (true);

-- staff (ADMIN, OPERATOR): operational data
create policy staff_read on leak_events               for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on isolation_advisories      for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on isolation_advisory_valves for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on work_orders               for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on work_order_assignments    for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on repair_evidence           for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on signal_latest             for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on ml_inferences             for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on twin_commands             for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on pipe_state_history        for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
create policy staff_read on event_log                 for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));

-- engineers: only their own jobs and what belongs to them
create policy own_wo on work_orders for select to authenticated using (assigned_engineer_id = auth.uid());
create policy own_event on leak_events for select to authenticated using (
  exists (select 1 from work_orders w where w.leak_event_id = leak_events.id and w.assigned_engineer_id = auth.uid()));
create policy own_evidence on repair_evidence for select to authenticated using (
  exists (select 1 from work_orders w where w.id = repair_evidence.work_order_id and w.assigned_engineer_id = auth.uid()));
create policy own_notifications on notifications for select to authenticated using (recipient_id = auth.uid());
create policy own_profile on profiles for select to authenticated using (id = auth.uid() or auth_role() in ('ADMIN','OPERATOR'));
create policy own_engineer on engineers for select to authenticated using (profile_id = auth.uid() or auth_role() in ('ADMIN','OPERATOR'));

-- devices: staff read, token_hash never exposed
create policy staff_read on devices for select to authenticated using (auth_role() in ('ADMIN','OPERATOR'));
revoke select on devices from authenticated, anon;
grant select (id, device_uid, pipe_id, status, firmware_version, report_interval_s, position, last_seen_at) on devices to authenticated;

-- Realtime (change events respect the policies above). Raw tables are NOT published.
alter publication supabase_realtime add table
  leak_events, work_orders, isolation_advisories, pipe_segments, valves, signal_latest, notifications, engineers;

-- Raw tables (hw_readings, twin_pipe_readings, pipe_baselines, ml_models, device_tokens, app_settings, twin_runs)
-- have RLS enabled and no policy: clients cannot read them.

-- Storage: two private buckets; no client-side storage policies.
insert into storage.buckets (id, name, public) values
  ('repair-evidence','repair-evidence', false),
  ('ml-models','ml-models', false)
on conflict (id) do nothing;
