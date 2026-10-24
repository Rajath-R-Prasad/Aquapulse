"""Aggregate public impact calculation: no pipe, valve, location or engineer details leave this module."""
from __future__ import annotations

from datetime import datetime
from typing import Any, Iterable

from app.services.isolation import affected_node_ids, compute_isolation


def _round_up_to(value: float, step: int) -> int:
    """Round a non-negative number to the nearest step, with halves going up."""
    return int((max(0.0, value) + step / 2) // step * step)


def active_advisory_node_ids(advisory_pipe_ids: Iterable[Any], pipes: dict, nodes: dict,
                             valves: list[dict]) -> set:
    """Union of nodes losing supply under every active advisory (deduplicated across advisories)."""
    affected: set = set()
    for pipe_id in set(advisory_pipe_ids):
        if pipe_id not in pipes:
            continue
        result = compute_isolation(pipe_id, pipes, nodes, valves)
        if result:
            _, region = result
            affected |= affected_node_ids(region, pipes, nodes)
    return affected


def compute_impact(open_events: list[dict], advisory_pipe_ids: Iterable[Any], pipes: dict, nodes: dict,
                   valves: list[dict], *, lpcd: float, persons_per_household: float,
                   now: datetime) -> dict:
    """Return the public_impact row values for the current open events and advisories."""
    active_leaks = len(open_events)
    if active_leaks == 0:
        return {"status": "NORMAL", "active_leaks": 0, "water_lost_l": 0,
                "households_affected": 0, "household_days": 0.0}

    water_raw = 0.0
    for event in open_events:
        rate = float(event.get("est_leak_rate_lpm") or 0)
        stop = event.get("isolated_at") or now
        minutes = max(0.0, (stop - event["detected_at"]).total_seconds() / 60.0)
        water_raw += rate * minutes

    affected = active_advisory_node_ids(advisory_pipe_ids, pipes, nodes, valves)
    connections = sum(int(nodes[n].get("served_connections") or 0) for n in affected)
    water_lost_l = _round_up_to(water_raw, 100)
    denominator = float(lpcd) * float(persons_per_household)
    household_days = round(water_lost_l / denominator, 2) if denominator > 0 else 0.0

    return {
        "status": "LEAK",
        "active_leaks": active_leaks,
        "water_lost_l": water_lost_l,
        "households_affected": _round_up_to(connections, 10),
        "household_days": household_days,
    }
