from __future__ import annotations

import json
import logging
import os
from typing import Any

import azure.functions as func
from azure.storage.queue import QueueClient

from src.pipeline.graph_client import parse_graph_resource
from src.pipeline.pipeline import PipelineOrchestrator, WorkItem
from src.pipeline.subscription import GraphSubscriptionManager

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)
logger = logging.getLogger(__name__)

_WORK_QUEUE_NAME = os.getenv("WORK_QUEUE_NAME", "transcript-work-items")


def _queue_client() -> QueueClient:
    return QueueClient.from_connection_string(
        conn_str=os.environ["AzureWebJobsStorage"],
        queue_name=_WORK_QUEUE_NAME,
    )


def _extract_validation_token_raw(url: str) -> str | None:
    if "?" not in url:
        return None
    raw_query = url.split("?", 1)[1]
    for part in raw_query.split("&"):
        if part.startswith("validationToken="):
            # Graph expects the exact token echo as received in query string bytes; do not URL-decode.
            return part[len("validationToken=") :]
    return None


def _enqueue_work_items(items: list[dict[str, Any]]) -> None:
    queue = _queue_client()
    try:
        queue.create_queue()
    except Exception:
        pass
    for item in items:
        queue.send_message(json.dumps(item))


@app.route(route="webhook", methods=["GET", "POST"])
def webhook(req: func.HttpRequest) -> func.HttpResponse:
    if req.method == "GET":
        token = _extract_validation_token_raw(req.url)
        if token is None:
            return func.HttpResponse("Missing validationToken", status_code=400)
        return func.HttpResponse(token, status_code=200, mimetype="text/plain")

    try:
        body = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON body", status_code=400)

    if isinstance(body, dict) and "value" in body:
        secret = os.getenv("GRAPH_CLIENT_STATE_SECRET", "")
        notifications = body.get("value") or []
        if not isinstance(notifications, list):
            return func.HttpResponse("Invalid Graph notifications payload", status_code=400)

        work_items: list[dict[str, Any]] = []
        for notification in notifications:
            if notification.get("clientState") != secret:
                return func.HttpResponse("Invalid clientState", status_code=401)
            resource = str(notification.get("resource", ""))
            meeting_id, transcript_id = parse_graph_resource(resource)
            work_items.append(
                {
                    "meeting_id": meeting_id,
                    "transcript_id": transcript_id,
                    "project": notification.get("project", ""),
                    "workstream": notification.get("workstream", ""),
                    "customer": notification.get("customer", ""),
                    "meeting_name": notification.get("meeting_name", ""),
                }
            )

        # Queue-based handoff is used to ensure webhook returns fast and reliably; network calls to
        # Graph/OpenAI/Blob happen in QueueTrigger execution, not in this request path.
        _enqueue_work_items(work_items)
        return func.HttpResponse(status_code=202)

    required = {"meeting_id", "transcript_id", "project", "workstream", "customer", "meeting_name"}
    if not (isinstance(body, dict) and required.issubset(body.keys())):
        return func.HttpResponse("Unsupported payload", status_code=400)

    _enqueue_work_items([body])
    return func.HttpResponse(status_code=202)


@app.queue_trigger(arg_name="msg", queue_name=_WORK_QUEUE_NAME, connection="AzureWebJobsStorage")
def process_work_item(msg: func.QueueMessage) -> None:
    payload = json.loads(msg.get_body().decode("utf-8"))
    work_item = WorkItem(
        meeting_id=payload["meeting_id"],
        transcript_id=payload["transcript_id"],
        project=payload.get("project", ""),
        workstream=payload.get("workstream", ""),
        customer=payload.get("customer", ""),
        meeting_name=payload.get("meeting_name", ""),
    )
    orchestrator = PipelineOrchestrator.from_env()
    result = orchestrator.process(work_item)
    logger.info("Processed transcript work item: %s", result)


@app.timer_trigger(arg_name="timer", schedule="0 */30 * * * *", run_on_startup=False)
def renew_graph_subscription(timer: func.TimerRequest) -> None:
    manager = GraphSubscriptionManager.from_env()
    result = manager.ensure_subscription()
    logger.info("Graph subscription ensured: %s", result)
