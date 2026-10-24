-- Keep available, under-capacity engineers dispatchable when GPS is unavailable or stale.
-- A fresh position contributes proximity scoring; a missing/stale position gets no proximity bonus.
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
