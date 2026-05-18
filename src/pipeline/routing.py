from __future__ import annotations

import fnmatch
import json
import os
from typing import Any


DEFAULT_CONTAINER = "requirements"
DEFAULT_LATEST = "requirements_latest.md"
DEFAULT_VERSION_PREFIX = "versions"


def _norm(value: Any) -> str:
    return str(value or "").strip()


def _match_rule(actual: str, expected: str) -> bool:
    if not expected:
        return True
    return fnmatch.fnmatch(actual.lower(), expected.lower())


def resolve_meeting_routing(metadata: dict[str, Any], routing_json: str | None = None) -> dict[str, str]:
    routing_json = routing_json if routing_json is not None else os.getenv("MEETING_ROUTING", "[]")
    try:
        rules = json.loads(routing_json)
    except json.JSONDecodeError as exc:
        raise ValueError("MEETING_ROUTING must be valid JSON") from exc

    defaults = {
        "container": os.getenv("REQUIREMENTS_CONTAINER", DEFAULT_CONTAINER),
        "requirements_blob": os.getenv("REQUIREMENTS_LATEST_BLOB", DEFAULT_LATEST),
        "version_prefix": os.getenv("REQUIREMENTS_VERSION_PREFIX", DEFAULT_VERSION_PREFIX),
    }

    project = _norm(metadata.get("project"))
    workstream = _norm(metadata.get("workstream"))
    customer = _norm(metadata.get("customer"))

    if customer and project and workstream:
        defaults["requirements_blob"] = (
            f"{customer.lower()}/{project.lower()}/{workstream.lower()}/requirements_latest.md"
        )
        defaults["version_prefix"] = f"{customer.lower()}/{project.lower()}/{workstream.lower()}/versions"

    for rule in rules:
        match = rule.get("match", {})
        if (
            _match_rule(project, _norm(match.get("project")))
            and _match_rule(workstream, _norm(match.get("workstream")))
            and _match_rule(customer, _norm(match.get("customer")))
            and _match_rule(_norm(metadata.get("meeting_name")), _norm(match.get("meeting_name")))
        ):
            target = rule.get("target", {})
            return {
                "container": _norm(target.get("container")) or defaults["container"],
                "requirements_blob": _norm(target.get("requirements_blob"))
                or defaults["requirements_blob"],
                "version_prefix": _norm(target.get("version_prefix")) or defaults["version_prefix"],
            }

    return defaults
