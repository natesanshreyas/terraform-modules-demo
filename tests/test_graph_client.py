from pipeline.graph_client import parse_graph_resource, parse_vtt_to_text


def test_parse_graph_resource_examples():
    examples = [
        (
            "communications/onlineMeetings('AAMkAGI2abc')/transcripts('MSMjMCMjxyz')",
            ("AAMkAGI2abc", "MSMjMCMjxyz"),
        ),
        (
            "communications/onlineMeetings('AAMkAGI2''quoted''id')/transcripts('MSMjMCMj''quoted''tid')",
            ("AAMkAGI2'quoted'id", "MSMjMCMj'quoted'tid"),
        ),
        (
            "communications/onlineMeetings('id-with-''-inside')/transcripts('transcript-''inner')",
            ("id-with-'-inside", "transcript-'inner"),
        ),
    ]

    for resource, expected in examples:
        assert parse_graph_resource(resource) == expected


def test_parse_vtt_to_text_preserves_speaker_and_timestamp():
    vtt = """WEBVTT

00:00:38.500 --> 00:00:52.000
<v Alex>Need API auth and audit logs.</v>

00:00:53.000 --> 00:00:57.000
Add retries for Graph webhooks.
"""

    output = parse_vtt_to_text(vtt)

    assert "[00:00:38.500] Alex: Need API auth and audit logs." in output
    assert "[00:00:53.000] Add retries for Graph webhooks." in output
