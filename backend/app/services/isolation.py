"""Isolation advisory (10.2): which valves to close, and how many connections lose supply."""
from __future__ import annotations

from typing import Any
from uuid import UUID

import networkx as nx
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import fetchall
from app.services.severity import URGENCY_FOR


def compute_isolation(leak_pipe: Any, pipes: dict, nodes: dict, valves: list[dict]) -> tuple[set, set] | None:
    """pipes: id -> {from_node,to_node}; nodes: id -> {kind, served_connections};
    valves: [{id,pipe_id,at_node,kind,state}]. Returns (valve_ids_to_close, region_pipe_ids) or None when the
    traversal reaches a source (reservoir/tank) without finding a valve."""
    by_end = {(v["pipe_id"], v["at_node"]): v for v in valves if v["kind"] == "ISOLATION"}
    at_node: dict[Any, list] = {}
    for pid, p in pipes.items():
        at_node.setdefault(p["from_node"], []).append(pid)
        at_node.setdefault(p["to_node"], []).append(pid)

    def other_end(pid, node):
        p = pipes[pid]
        return p["to_node"] if p["from_node"] == node else p["from_node"]

    to_close: set = set()
    region = {leak_pipe}
    seen: set = set()
    frontier = [(leak_pipe, pipes[leak_pipe]["from_node"]), (leak_pipe, pipes[leak_pipe]["to_node"])]
    while frontier:
        pipe, node = frontier.pop()
        if (pipe, node) in seen:
            continue
        seen.add((pipe, node))
        v = by_end.get((pipe, node))
        if v:
            if v["state"] != "CLOSED":
                to_close.add(v["id"])
            continue                                    # this end is sealed
        if nodes[node]["kind"] in ("RESERVOIR", "TANK"):
            return None                                 # source reached with no valve in between
        for q in at_node.get(node, []):
            if q == pipe:
                continue
            vq = by_end.get((q, node))
            if vq:
                if vq["state"] != "CLOSED":
                    to_close.add(vq["id"])
                continue
            region.add(q)
            frontier.append((q, other_end(q, node)))
    return to_close, region


def affected_node_ids(region: set, pipes: dict, nodes: dict) -> set:
    """Remove region pipes from the graph; return the junction nodes that can no longer reach a source."""
    g = nx.Graph()
    g.add_nodes_from(nodes)
    for pid, p in pipes.items():
        if pid not in region:
            g.add_edge(p["from_node"], p["to_node"])
    sources = [n for n, d in nodes.items() if d["kind"] in ("RESERVOIR", "TANK")]
    fed: set = set()
    for src in sources:
        fed |= nx.node_connected_component(g, src)
    return {n for n, d in nodes.items() if n not in fed and d["kind"] == "JUNCTION"}


def affected_connections(region: set, pipes: dict, nodes: dict) -> int:
    """Sum served_connections for the nodes returned by affected_node_ids."""
    return int(sum(nodes[n]["served_connections"] or 0 for n in affected_node_ids(region, pipes, nodes)))


def build_message(pipe_code: str, valve_codes: list[str], connections: int, severity: str, rate: float | None) -> str:
    if not valve_codes:
        return "No isolation valve mapped, contact the field team."
    return (f"Close {', '.join(valve_codes)} to isolate {pipe_code} (about {connections} connections lose supply). "
            f"Severity {severity}, about {round(rate or 0):d} L/min.")


async def create_advisory(s: AsyncSession, event_id: UUID, pipe_id: UUID, pipe_code: str, severity: str,
                          rate_lpm: float | None) -> dict:
    """An advisory is always created for a confirmed leak; urgency comes from severity (8.5)."""
    pipes = {r["id"]: r for r in await fetchall(s, "select id, from_node, to_node from pipe_segments")}
    nodes = {r["id"]: r for r in await fetchall(s, "select id, kind::text as kind, served_connections from network_nodes")}
    valves = await fetchall(s, "select id, code, pipe_id, at_node, kind::text as kind, state::text as state from valves")
    codes = {v["id"]: v["code"] for v in valves}
    result = compute_isolation(pipe_id, pipes, nodes, valves) if pipe_id in pipes else None
    if result and result[0]:
        valve_ids, region = result
        conns = affected_connections(region, pipes, nodes)
    else:
        valve_ids, conns = set(), 0
    vcodes = sorted((codes[v] for v in valve_ids), key=lambda c: (len(c), c))
    msg = build_message(pipe_code, vcodes, conns, severity, rate_lpm)
    adv_id = (await s.execute(
        text("insert into isolation_advisories (leak_event_id, urgency, affected_connections, message) "
             "values (:e, CAST(:u AS advisory_urgency), :c, :m) returning id"),
        {"e": event_id, "u": URGENCY_FOR[severity], "c": conns, "m": msg})).scalar_one()
    for vid in valve_ids:
        await s.execute(text("insert into isolation_advisory_valves (advisory_id, valve_id) values (:a, :v)"),
                        {"a": adv_id, "v": vid})
    return {"id": adv_id, "urgency": URGENCY_FOR[severity], "valves": vcodes, "affected_connections": conns, "message": msg}
