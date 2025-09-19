from ..domain.gcs_storage_port import GCSStoragePort

class GCSStorageService(GCSStoragePort):
    """Concrete implementation of the GCSStoragePort interface.
    For now, it's a mock service that only prints actions instead of
    actually uploading to Google Cloud Storage.
    """

    def __init__(self, bucket: str, prefix: str = ""):
        # bucket: the name of the GCS bucket
        # prefix: an optional base path (like a folder) inside the bucket
        self.bucket = bucket
        self.prefix = prefix

    def upload_dir(self, local_dir: str, dst_prefix: str) -> None:
        # Mock implementation: just print what would happen
        # local_dir: path to the local directory that should be uploaded
        # dst_prefix: destination folder (prefix) in the GCS bucket
        print(f"[MOCK] Uploading directory {local_dir} to gs://{self.bucket}/{dst_prefix}")

    def upload_file(self, src_path, dst_blob, content_type=None):
        # Mock implementation: just print what would happen
        # src_path: local path of the file to upload
        # dst_blob: destination object (blob) name in the GCS bucket
        # content_type: optional MIME type of the file (e.g., "image/png")
        print(f"[MOCK] Uploading file {src_path} to gs://{self.bucket}/{dst_blob}")
