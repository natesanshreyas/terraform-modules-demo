from pipeline.blob_store import BlobRequirementsStore, BlobRoute


class _FakeDownload:
    def __init__(self, value: bytes) -> None:
        self._value = value

    def readall(self) -> bytes:
        return self._value


class _FakeBlobClient:
    def __init__(self, backing: dict[tuple[str, str], bytes], container: str, name: str) -> None:
        self._backing = backing
        self._container = container
        self._name = name

    def upload_blob(self, data: bytes, overwrite: bool = False) -> None:
        self._backing[(self._container, self._name)] = data

    def download_blob(self) -> _FakeDownload:
        value = self._backing.get((self._container, self._name), b"")
        return _FakeDownload(value)


class _FakeContainerClient:
    def create_container(self) -> None:
        return None


class _FakeServiceClient:
    def __init__(self) -> None:
        self.storage: dict[tuple[str, str], bytes] = {}

    def get_container_client(self, container_name: str) -> _FakeContainerClient:
        return _FakeContainerClient()

    def get_blob_client(self, container: str, blob: str) -> _FakeBlobClient:
        return _FakeBlobClient(self.storage, container, blob)


def test_append_analysis_writes_latest_and_versioned():
    service = _FakeServiceClient()
    store = BlobRequirementsStore(service)  # type: ignore[arg-type]
    route = BlobRoute(container="requirements", requirements_blob="latest.md", version_prefix="versions")

    result = store.append_analysis(route, "- Added API requirement", "Kickoff")

    latest = service.storage[("requirements", "latest.md")].decode("utf-8")
    assert "Added API requirement" in latest
    assert result["latest_blob"] == "latest.md"
    assert result["versioned_blob"].startswith("versions/")
