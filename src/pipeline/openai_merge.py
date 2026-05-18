from __future__ import annotations

import json
import os

from openai import AzureOpenAI


class OpenAIMergeClient:
    def __init__(self, endpoint: str, api_key: str, deployment: str, api_version: str) -> None:
        self.deployment = deployment
        self.client = AzureOpenAI(
            azure_endpoint=endpoint,
            api_key=api_key,
            api_version=api_version,
        )

    @classmethod
    def from_env(cls) -> "OpenAIMergeClient":
        return cls(
            endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
            api_key=os.environ["AZURE_OPENAI_API_KEY"],
            deployment=os.environ["AZURE_OPENAI_DEPLOYMENT"],
            api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-10-21"),
        )

    def merge_requirements(
        self,
        existing_requirements: str,
        transcript_text: str,
        context: dict[str, str],
    ) -> str:
        system_prompt = (
            "You are an enterprise requirements analyst. Summarize actionable software requirements "
            "from meeting transcript text into concise markdown bullet points. Keep output factual and "
            "grounded in the transcript."
        )

        user_prompt = {
            "meeting_context": context,
            "current_requirements_markdown": existing_requirements,
            "transcript": transcript_text,
            "instructions": (
                "Return markdown with sections: New Requirements, Clarifications, Open Questions, "
                "Risks/Dependencies."
            ),
        }

        completion = self.client.chat.completions.create(
            model=self.deployment,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": json.dumps(user_prompt)},
            ],
            temperature=0.1,
        )

        content = completion.choices[0].message.content
        if not content:
            raise RuntimeError("Azure OpenAI returned an empty response")
        return content.strip()
