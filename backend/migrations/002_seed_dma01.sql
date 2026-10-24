-- Seed data for DMA-01 (document section 7.6): 1 reservoir, 12 junctions, 18 pipes (P01-P18),
-- isolation valves at both ends of every pipe, P17 monitored by hardware, all others SIMULATED.
-- Users and the ESP32 device are created by scripts/seed_users.py and scripts/provision_device.py
-- (they need Supabase Auth and a generated device token).
do $seed$
declare v_dma uuid; v_i int := 0; r record;
begin
  insert into dmas (code, name, boundary) values
    ('DMA-01', 'DMA-01 Demo Area',
     ST_GeogFromText('POLYGON((76.6340 12.2925, 76.6450 12.2925, 76.6450 12.3005, 76.6340 12.3005, 76.6340 12.2925))'))
  returning id into v_dma;

  -- nodes: grid of 3 columns x 4 rows (J1..J12) plus reservoir R1; coordinates are lon/lat
  insert into network_nodes (dma_id, code, kind, geom, elevation_m, base_demand_lps, served_connections)
  select v_dma, n.code, n.kind::node_kind, ST_SetSRID(ST_MakePoint(n.lon, n.lat), 4326)::geography,
         n.elev, n.demand, n.conns
  from (values
    ('R1',  'RESERVOIR', 76.6394, 12.2995, 760.0, 0.0,   0),
    ('J1',  'JUNCTION',  76.6360, 12.2980, 752.0, 0.0150, 30),
    ('J2',  'JUNCTION',  76.6394, 12.2980, 751.5, 0.0200, 42),
    ('J3',  'JUNCTION',  76.6428, 12.2980, 751.0, 0.0140, 28),
    ('J4',  'JUNCTION',  76.6360, 12.2965, 750.5, 0.0170, 35),
    ('J5',  'JUNCTION',  76.6394, 12.2965, 750.0, 0.0210, 40),
    ('J6',  'JUNCTION',  76.6428, 12.2965, 749.5, 0.0160, 31),
    ('J7',  'JUNCTION',  76.6360, 12.2950, 749.0, 0.0130, 26),
    ('J8',  'JUNCTION',  76.6394, 12.2950, 748.5, 0.0190, 38),
    ('J9',  'JUNCTION',  76.6428, 12.2950, 748.0, 0.0165, 33),
    ('J10', 'JUNCTION',  76.6360, 12.2935, 747.5, 0.0110, 22),
    ('J11', 'JUNCTION',  76.6394, 12.2935, 747.0, 0.0120, 24),
    ('J12', 'JUNCTION',  76.6428, 12.2935, 746.5, 0.0100, 20)
  ) as n(code, kind, lon, lat, elev, demand, conns);

  -- pipes
  insert into pipe_segments (dma_id, code, from_node, to_node, geom, length_m, diameter_mm, material,
                             install_year, pressure_class, hazen_williams_c, design_flow_lpm, monitoring)
  select v_dma, p.code, a.id, b.id,
         ST_MakeLine(a.geom::geometry, b.geom::geometry)::geography,
         round(ST_Length(ST_MakeLine(a.geom::geometry, b.geom::geometry)::geography)::numeric, 2),
         p.dia, p.mat::pipe_material, p.yr, 'PN10', p.hw, p.design,
         case when p.code = 'P17' then 'HARDWARE' else 'SIMULATED' end::monitoring_mode
  from (values
    ('P01','R1','J2', 200,'DI', 2005,130, 600.0),
    ('P02','J1','J2', 150,'CI', 1998,110, 120.0),
    ('P03','J2','J3', 150,'CI', 1998,110, 120.0),
    ('P04','J4','J5', 100,'PVC',2010,140,  80.0),
    ('P05','J5','J6', 100,'PVC',2010,140,  80.0),
    ('P06','J7','J8', 100,'PVC',2012,140,  70.0),
    ('P07','J8','J9', 100,'PVC',2012,140,  70.0),
    ('P08','J10','J11',100,'HDPE',2015,150, 50.0),
    ('P09','J11','J12',100,'HDPE',2015,150, 50.0),
    ('P10','J1','J4', 100,'GI', 1995,100,  60.0),
    ('P11','J2','J5', 150,'DI', 2005,130, 150.0),
    ('P12','J3','J6', 100,'GI', 1995,100,  60.0),
    ('P13','J4','J7', 100,'PVC',2010,140,  60.0),
    ('P14','J5','J8', 150,'DI', 2005,130, 120.0),
    ('P15','J6','J9', 100,'PVC',2010,140,  60.0),
    ('P16','J7','J10',100,'HDPE',2015,150, 50.0),
    ('P17','J8','J11',150,'CI', 1998,110, 100.0),
    ('P18','J9','J12',100,'HDPE',2015,150, 50.0)
  ) as p(code, fcode, tcode, dia, mat, yr, hw, design)
  join network_nodes a on a.code = p.fcode
  join network_nodes b on b.code = p.tcode;

  -- isolation valves at both ends of every pipe (P17 first so it gets V1 and V2)
  for r in select ps.id, ps.from_node, ps.to_node, ps.geom::geometry as g
           from pipe_segments ps order by (ps.code <> 'P17'), ps.code loop
    v_i := v_i + 1;
    insert into valves (code, pipe_id, at_node, kind, geom)
    values ('V' || v_i, r.id, r.from_node, 'ISOLATION', ST_LineInterpolatePoint(r.g, 0.03)::geography);
    v_i := v_i + 1;
    insert into valves (code, pipe_id, at_node, kind, geom)
    values ('V' || v_i, r.id, r.to_node, 'ISOLATION', ST_LineInterpolatePoint(r.g, 0.97)::geography);
  end loop;
end
$seed$;
