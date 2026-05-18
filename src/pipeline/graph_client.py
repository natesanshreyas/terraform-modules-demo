from __future__ import annotations

import html
import os
import re
import threading
import time
from typing import Any

import msal
import requests

GRAPH_SCOPE = ["https://graph.microsoft.com/.default"]
_GRAPH_BASE = "https://graph.microsoft.com"
_RESOURCE_RE = re.compile(
    r"^communications/onlineMeetings\('((?:[^']|'')+)'\)/transcripts\('((?:[^']|'')+)'\)$"
)
_TAG_RE = re.compile(r"<[^>]+>")

_TOKEN_CACHE: dict[str, Any] = {
    "access_token": None,
    "expires_at": 0,
}
_TOKEN_CACHE_LOCK = threading.Lock()


def parse_graph_resource(resource: str) -> tuple[str, str]:
    match = _RESOURCE_RE.match(resource)
    if not match:
        raise ValueError(f"Unsupported Graph resource format: {resource}")
    meeting_id = match.group(1).replace("''", "'")
    transcript_id = match.group(2).replace("''", "'")
    return meeting_id, transcript_id


def _escape_odata_id(value: str) -> str:
    return value.replace("'", "''")


def parse_vtt_to_text(vtt_content: str) -> str:
    lines = vtt_content.splitlines()
    output: list[str] = []
    i = 0

    while i < len(lines):
        line = lines[i].strip()
        if not line or line.upper() == "WEBVTT" or line.startswith("NOTE"):
            i += 1
            continue

        if "-->" not in line:
            i += 1
            continue

        start = line.split("-->", 1)[0].strip()
        i += 1

        cue_lines: list[str] = []
        while i < len(lines) and lines[i].strip():
            cue_lines.append(lines[i].strip())
            i += 1

        speaker = None
        text_parts: list[str] = []
        for cue_line in cue_lines:
            speaker_match = re.search(r"<v\s+([^>]+)>(.*?)</v>", cue_line, re.IGNORECASE)
            if speaker_match:
                if speaker is None:
                    speaker = html.unescape(speaker_match.group(1).strip())
                fragment = html.unescape(_TAG_RE.sub("", speaker_match.group(2)).strip())
            else:
                fragment = html.unescape(_TAG_RE.sub("", cue_line).strip())
            if fragment:
                text_parts.append(fragment)

        text = " ".join(text_parts).strip()
        if text:
            if speaker:
                output.append(f"[{start}] {speaker}: {text}")
            else:
                output.append(f"[{start}] {text}")

    return "\n".join(output)


class GraphClient:
    def __init__(
        self,
        tenant_id: str,
        client_id: str,
        client_secret: str,
        base_url: str = _GRAPH_BASE,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        authority = f"https://login.microsoftonline.com/{tenant_id}"
        self._app = msal.ConfidentialClientApplication(
            client_id=client_id,
            authority=authority,
            client_credential=client_secret,
        )

    @classmethod
    def from_env(cls) -> "GraphClient":
        return cls(
            tenant_id=os.environ["GRAPH_TENANT_ID"],
            client_id=os.environ["GRAPH_CLIENT_ID"],
            client_secret=os.environ["GRAPH_CLIENT_SECRET"],
        )

    def get_access_token(self) -> str:
        with _TOKEN_CACHE_LOCK:
            now = int(time.time())
            token = _TOKEN_CACHE.get("access_token")
            expires_at = int(_TOKEN_CACHE.get("expires_at") or 0)
            if token and now < (expires_at - 300):
                return str(token)

            result = self._app.acquire_token_for_client(scopes=GRAPH_SCOPE)
            access_token = result.get("access_token")
            if not access_token:
                raise RuntimeError(
                    f"Failed to acquire Graph token: {result.get('error_description') or result}"
                )

            _TOKEN_CACHE["access_token"] = access_token
            _TOKEN_CACHE["expires_at"] = now + int(result.get("expires_in", 3600))
            return str(access_token)

    def _request(self, method: str, path_or_url: str, **kwargs: Any) -> requests.Response:
        token = self.get_access_token()
        headers = kwargs.pop("headers", {})
        headers["Authorization"] = f"Bearer {token}"
        if not path_or_url.startswith("http"):
            url = f"{self.base_url}{path_or_url}"
        else:
            url = path_or_url
        response = requests.request(method, url, headers=headers, timeout=30, **kwargs)
        response.raise_for_status()
        return response

    def get_transcript_content_url(self, meeting_id: str, transcript_id: str) -> str:
        meeting = _escape_odata_id(meeting_id)
        transcript = _escape_odata_id(transcript_id)
        path = (
            f"/v1.0/communications/onlineMeetings('{meeting}')/transcripts('{transcript}')"
            "?$select=transcriptContentUrl"
        )
        payload = self._request("GET", path).json()
        url = payload.get("transcriptContentUrl") or payload.get("contentUrl")
        if not url:
            raise RuntimeError("Graph transcript response did not include transcriptContentUrl")
        return str(url)

    def download_transcript_vtt(self, meeting_id: str, transcript_id: str) -> str:
        content_url = self.get_transcript_content_url(meeting_id, transcript_id)
        response = self._request("GET", content_url)
        return response.text
