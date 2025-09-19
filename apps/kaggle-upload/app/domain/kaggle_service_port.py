from typing import Protocol

class KaggleServicePort(Protocol):
    """Contract for a service that fetches datasets from Kaggle."""

    def download_dataset(self, ref: str, local_dir: str, unzip: bool = True) -> str: ...
