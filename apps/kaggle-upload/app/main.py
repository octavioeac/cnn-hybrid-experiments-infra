from infrastructure.kaggle_service import KaggleService
from infrastructure.gcs_storage import GCSStorageService
from application.fetch_and_export import FetchAndExport

if __name__ == "__main__":
    kaggle = KaggleService()
    gcs = GCSStorageService(bucket="my-test-bucket", prefix="datasets/")
    uc = FetchAndExport(kaggle, gcs)

    # prueba con datos ficticios
    uc.run("urbansound8k/urbansound8k", "./data", "us8k/")
