"""Twin command queue (FastAPI -> Twin), section 6.3."""
from __future__ import annotations

from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import dumps


async def queue_command(s: AsyncSession, type_: str, *, pipe_id: UUID | None = None, valve_id: UUID | None = None,
                        params: dict | None = None, leak_event_id: UUID | None = None,
                        created_by: UUID | None = None) -> UUID:
    row = await s.execute(
        text("insert into twin_commands (type, pipe_id, valve_id, params, leak_event_id, created_by) "
             "values (CAST(:t AS twin_cmd_type), :p, :v, CAST(:pa AS jsonb), :e, :u) returning id"),
        {"t": type_, "p": pipe_id, "v": valve_id, "pa": dumps(params or {}), "e": leak_event_id, "u": created_by})
    return row.scalar_one()


async def mirror_leak(s: AsyncSession, pipe_id: UUID, event_id: UUID, rate_lpm: float | None,
                      position_fraction: float = 0.5) -> None:
    """Hardware-sourced event: make the simulated network react (INJECT_LEAK with the estimated rate)."""
    await queue_command(s, "INJECT_LEAK", pipe_id=pipe_id, leak_event_id=event_id,
                        params={"leak_rate_lpm": round(float(rate_lpm or 0), 2), "position_fraction": position_fraction})


async def clear_pipe(s: AsyncSession, pipe_id: UUID, event_id: UUID | None, created_by: UUID | None = None) -> None:
    await queue_command(s, "CLEAR_LEAK", pipe_id=pipe_id, leak_event_id=event_id, created_by=created_by)
    await queue_command(s, "RESET_PIPE_NORMAL", pipe_id=pipe_id, leak_event_id=event_id, created_by=created_by)


# ---------------------------------------------------------------- network model (GET /v1/twin/network, GET /v1/network)
async def network_geojson(s: AsyncSession) -> dict:
    """GeoJSON FeatureCollection of nodes, pipes and valves. Coordinates are [lon, lat] (RFC 7946)."""
    from app.db import as_json, fetchall

    nodes = await fetchall(s, """select n.code, n.kind::text as kind, n.elevation_m, n.base_demand_lps, n.served_connections,
                                 d.code as dma_code, ST_AsGeoJSON(n.geom::geometry)::jsonb as geometry
                                 from network_nodes n join dmas d on d.id = n.dma_id order by n.code""")
    pipes = await fetchall(s, """select p.code, p.diameter_mm, p.material::text as material, p.hazen_williams_c, p.length_m,
                                 p.design_flow_lpm, p.monitoring::text as monitoring, p.state::text as state,
                                 p.install_year, d.code as dma_code, fn.code as from_node, tn.code as to_node,
                                 ST_AsGeoJSON(p.geom::geometry)::jsonb as geometry
                                 from pipe_segments p join dmas d on d.id = p.dma_id
                                 join network_nodes fn on fn.id = p.from_node join network_nodes tn on tn.id = p.to_node
                                 order by p.code""")
    valves = await fetchall(s, """select v.code, v.kind::text as kind, v.state::text as state, p.code as pipe_code,
                                  n.code as node_code, v.remote_controllable, ST_AsGeoJSON(v.geom::geometry)::jsonb as geometry
                                  from valves v join pipe_segments p on p.id = v.pipe_id join network_nodes n on n.id = v.at_node
                                  order by v.code""")
    feats = []
    for kind, rows in (("NODE", nodes), ("PIPE", pipes), ("VALVE", valves)):
        for r in rows:
            geom = as_json(r.pop("geometry"))
            feats.append({"type": "Feature", "geometry": geom,
                          "properties": {"feature_type": kind, **{k: (float(v) if hasattr(v, "as_tuple") else v) for k, v in r.items()}}})
    return {"type": "FeatureCollection", "features": feats}
