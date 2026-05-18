import os

import pytest
import responses
from azure.storage.blob import BlobServiceClient

from pipeline.blob_store import BlobRequirementsStore
from pipeline.graph_client import GraphClient
from pipeline.pipeline import PipelineOrchestrator, WorkItem


class _FakeOpenAI:
    def merge_requirements(self, existing_requirements: str, transcript_text: str, context: dict[str, str]) -> str:
        return f"- Parsed for {context['meeting_name']}: {transcript_text[:40]}"


def _azurite_connection_string() -> str:
    return os.getenv(
        "AZURITE_CONNECTION_STRING",
        "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;"
        "AccountKey=Eby8vdM02xNOcqFeqCnf2mHB7fG8No0l5LQKBHBeksoGMGw==;"
        "BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;",
    )


@pytest.mark.integration
@responses.activate
def test_pipeline_e2e_with_azurite_and_mocked_graph(monkeypatch):
    try:
        BlobServiceClient.from_connection_string(_azurite_connection_string()).get_service_properties()
    except Exception as exc:
        pytest.skip(f"Azurite is not available: {exc}")

    monkeypatch.setenv("GRAPH_TENANT_ID", "tenant")
    monkeypatch.setenv("GRAPH_CLIENT_ID", "client")
    monkeypatch.setenv("GRAPH_CLIENT_SECRET", "secret")
    monkeypatch.setenv("BLOB_CONNECTION_STRING", _azurite_connection_string())

    graph_client = GraphClient.from_env()
    monkeypatch.setattr(graph_client, "get_access_token", lambda: "token")

    metadata_url = "https://graph.microsoft.com/v1.0/communications/onlineMeetings('m1')/transcripts('t1')?$select=transcriptContentUrl"
    content_url = "https://graph.microsoft.com/transcripts/t1/content"

    responses.add(
        responses.GET,
        metadata_url,
        json={"transcriptContentUrl": content_url},
        status=200,
    )
    responses.add(
        responses.GET,
        content_url,
        body="WEBVTT\n\n00:00:00.000 --> 00:00:01.000\n<v Sam>Add SSO requirement</v>",
        status=200,
    )

    orchestrator = PipelineOrchestrator(
        graph_client=graph_client,
        blob_store=BlobRequirementsStore.from_env(),
        openai_client=_FakeOpenAI(),  # type: ignore[arg-type]
    )

    result = orchestrator.process(
        WorkItem(
            meeting_id="m1",
            transcript_id="t1",
            project="atlas",
            workstream="identity",
            customer="contoso",
            meeting_name="Sprint 1",
        )
    )

    latest_blob = (
        BlobServiceClient.from_connection_string(_azurite_connection_string())
        .get_blob_client(result["container"], result["latest_blob"])
        .download_blob()
        .readall()
        .decode("utf-8")
    )
    assert "Parsed for Sprint 1" in latest_blob
