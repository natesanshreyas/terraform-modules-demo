from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .blob_store import BlobRequirementsStore, BlobRoute
from .graph_client import GraphClient, parse_vtt_to_text
from .openai_merge import OpenAIMergeClient
from .routing import resolve_meeting_routing


@dataclass
class WorkItem:
    meeting_id: str
    transcript_id: str
    project: str = ""
    workstream: str = ""
    customer: str = ""
    meeting_name: str = ""

    def context(self) -> dict[str, str]:
        return {
            "meeting_id": self.meeting_id,
            "transcript_id": self.transcript_id,
            "project": self.project,
            "workstream": self.workstream,
            "customer": self.customer,
            "meeting_name": self.meeting_name,
        }


class PipelineOrchestrator:
    def __init__(
        self,
        graph_client: GraphClient,
        blob_store: BlobRequirementsStore,
        openai_client: OpenAIMergeClient,
    ) -> None:
        self.graph_client = graph_client
        self.blob_store = blob_store
        self.openai_client = openai_client

    @classmethod
    def from_env(cls) -> "PipelineOrchestrator":
        return cls(
            graph_client=GraphClient.from_env(),
            blob_store=BlobRequirementsStore.from_env(),
            openai_client=OpenAIMergeClient.from_env(),
        )

    def process(self, work_item: WorkItem) -> dict[str, Any]:
        routing = resolve_meeting_routing(work_item.context())
        route = BlobRoute(
            container=routing["container"],
            requirements_blob=routing["requirements_blob"],
            version_prefix=routing["version_prefix"],
        )

        vtt_content = self.graph_client.download_transcript_vtt(
            meeting_id=work_item.meeting_id,
            transcript_id=work_item.transcript_id,
        )
        transcript_text = parse_vtt_to_text(vtt_content)

        existing = self.blob_store.read_latest(route)
        merged_analysis = self.openai_client.merge_requirements(
            existing_requirements=existing,
            transcript_text=transcript_text,
            context=work_item.context(),
        )

        write_result = self.blob_store.append_analysis(
            route=route,
            analysis_markdown=merged_analysis,
            meeting_name=work_item.meeting_name,
        )

        return {
            "meeting_id": work_item.meeting_id,
            "transcript_id": work_item.transcript_id,
            **write_result,
        }
