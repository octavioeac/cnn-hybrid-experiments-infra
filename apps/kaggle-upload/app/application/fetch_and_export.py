from ..domain.kaggle_service_port import KaggleServicePort
from ..domain.gcs_storage_port import GCSStoragePort

class FetchAndExport:
    """Use case that downloads a dataset from Kaggle and exports it to GCS.
    Notice that this class depends only on the *ports* (interfaces),
    not on the concrete implementations.
    """

    def __init__(self, kaggle: KaggleServicePort, gcs: GCSStoragePort):
        # We inject the *ports* (interfaces) instead of hardcoding implementations.
        # Why?
        # - Dependency Inversion Principle (Clean Architecture).
        # - Makes the use case independent from infrastructure details.
        # - Easier to replace implementations (e.g., mock vs real).
        # - Easier to test (you can inject a fake KaggleService or GCSStorage).
        self.kaggle = kaggle
        self.gcs = gcs

    def run(self, ref: str, local_dir: str, dst_prefix: str) -> None:
        # Call the Kaggle service via the port interface
        path = self.kaggle.download_dataset(ref, local_dir)

        # Call the GCS service via the port interface
        self.gcs.upload_dir(path, dst_prefix)

        # This use case does not care HOW Kaggle downloads or HOW GCS uploads.
        # It only cares that both follow the contract defined by the ports.
