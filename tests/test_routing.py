import json

from pipeline.routing import resolve_meeting_routing


def test_routing_uses_context_defaults():
    metadata = {
        "project": "Atlas",
        "workstream": "Payments",
        "customer": "Contoso",
        "meeting_name": "Weekly Sync",
    }

    route = resolve_meeting_routing(metadata, routing_json="[]")

    assert route["container"] == "requirements"
    assert route["requirements_blob"] == "contoso/atlas/payments/requirements_latest.md"
    assert route["version_prefix"] == "contoso/atlas/payments/versions"


def test_routing_selects_matching_rule_with_wildcards():
    rules = [
        {
            "match": {
                "project": "Atlas",
                "workstream": "Pay*",
                "customer": "Contoso",
                "meeting_name": "Sprint*",
            },
            "target": {
                "container": "reqs",
                "requirements_blob": "custom/latest.md",
                "version_prefix": "custom/versions",
            },
        }
    ]

    route = resolve_meeting_routing(
        {
            "project": "atlas",
            "workstream": "payments",
            "customer": "contoso",
            "meeting_name": "Sprint Planning",
        },
        routing_json=json.dumps(rules),
    )

    assert route == {
        "container": "reqs",
        "requirements_blob": "custom/latest.md",
        "version_prefix": "custom/versions",
    }
