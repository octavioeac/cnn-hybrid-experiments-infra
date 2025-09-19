from typing import Protocol

class GCSStoragePort(Protocol):
    """Contract (interface) for a service that uploads data to Google Cloud Storage."""

    def upload_dir(self, local_dir: str, dst_prefix: str) -> None: ...
    # The "..." here is a placeholder (Ellipsis).
    # It means: this method exists, but it has no implementation yet.
    # Equivalent to "void uploadDir(String localDir, String dstPrefix);" in a Java interface.

    def upload_file(
        self,
        src_path: str,
        dst_blob: str,
        content_type: str | None = None
    ) -> None: ...
    # Same here: "..." is a placeholder (no implementation).
    # src_path: local path to the file.
    # dst_blob: destination path (object key) in the GCS bucket.
    # content_type: optional MIME type (e.g., "image/png").
    # Equivalent to "void uploadFile(String srcPath, String dstBlob, String contentType);" in Java.
