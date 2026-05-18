from __future__ import annotations

import os
from datetime import UTC, datetime, timedelta
from typing import Any

from .graph_client import GraphClient


class GraphSubscriptionManager:
    def __init__(self, graph_client: GraphClient) -> None:
        self.graph_client = graph_client

    @classmethod
    def from_env(cls) -> "GraphSubscriptionManager":
        return cls(GraphClient.from_env())

    def _expiration_timestamp(self) -> str:
        minutes = int(os.getenv("GRAPH_SUBSCRIPTION_EXPIRY_MINUTES", "60"))
        expires = datetime.now(UTC) + timedelta(minutes=minutes)
        return expires.replace(microsecond=0).isoformat().replace("+00:00", "Z")

    def create_subscription(self) -> dict[str, Any]:
        payload = {
            "changeType": "created",
            "notificationUrl": os.environ["GRAPH_NOTIFICATION_URL"],
            "resource": os.getenv(
                "GRAPH_SUBSCRIPTION_RESOURCE", "communications/onlineMeetings/getAllTranscripts"
            ),
            "expirationDateTime": self._expiration_timestamp(),
            "clientState": os.environ["GRAPH_CLIENT_STATE_SECRET"],
        }
        response = self.graph_client._request("POST", "/v1.0/subscriptions", json=payload)
        return response.json()

    def renew_subscription(self, subscription_id: str) -> dict[str, Any]:
        payload = {"expirationDateTime": self._expiration_timestamp()}
        response = self.graph_client._request(
            "PATCH", f"/v1.0/subscriptions/{subscription_id}", json=payload
        )
        if response.content:
            return response.json()
        return {"id": subscription_id, "expirationDateTime": payload["expirationDateTime"]}

    def ensure_subscription(self) -> dict[str, Any]:
        subscription_id = os.getenv("GRAPH_SUBSCRIPTION_ID", "").strip()
        if subscription_id:
            return self.renew_subscription(subscription_id)
        return self.create_subscription()
