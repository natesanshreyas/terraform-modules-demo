from __future__ import annotations

import os
from dataclasses import dataclass
from datetime import UTC, datetime

from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from azure.storage.blob import BlobServiceClient


@dataclass
class BlobRoute:
    container: str
    requirements_blob: str
    version_prefix: str


class BlobRequirementsStore:
    def __init__(self, service_client: BlobServiceClient) -> None:
        self.service_client = service_client

    @classmethod
    def from_env(cls) -> "BlobRequirementsStore":
        return cls(BlobServiceClient.from_connection_string(os.environ["BLOB_CONNECTION_STRING"]))

    def _ensure_container(self, container_name: str) -> None:
        container_client = self.service_client.get_container_client(container_name)
        try:
            container_client.create_container()
        except ResourceExistsError:
            pass

    def read_latest(self, route: BlobRoute) -> str:
        self._ensure_container(route.container)
        blob_client = self.service_client.get_blob_client(route.container, route.requirements_blob)
        try:
            return blob_client.download_blob().readall().decode("utf-8")
        except ResourceNotFoundError:
            return ""

    def append_analysis(
        self,
        route: BlobRoute,
        analysis_markdown: str,
        meeting_name: str | None,
    ) -> dict[str, str]:
        self._ensure_container(route.container)
        existing = self.read_latest(route)

        timestamp = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        slug = (meeting_name or "meeting").strip().lower().replace(" ", "-")[:60] or "meeting"
        section = f"## {timestamp} — {meeting_name or 'Meeting'}\n\n{analysis_markdown.strip()}\n"

        combined = f"{existing.rstrip()}\n\n{section}" if existing.strip() else section

        latest_blob = self.service_client.get_blob_client(route.container, route.requirements_blob)
        latest_blob.upload_blob(combined.encode("utf-8"), overwrite=True)

        versioned_blob_name = f"{route.version_prefix}/{timestamp}-{slug}.md"
        versioned_blob = self.service_client.get_blob_client(route.container, versioned_blob_name)
        versioned_blob.upload_blob(combined.encode("utf-8"), overwrite=True)

        return {
            "container": route.container,
            "latest_blob": route.requirements_blob,
            "versioned_blob": versioned_blob_name,
        }
