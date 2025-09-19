# Python Mock Package: Structure and Build Instructions

This document explains how to set up the folder structure, build the package, and run the mock for `kaggle-upload`.

---

## Project structure

Place the code under `apps/kaggle-upload/app/` and include `__init__.py` in each folder:

```
apps/
└─ kaggle-upload/
   ├─ app/
   │  ├─ __init__.py
   │  ├─ main.py
   │  ├─ application/
   │  │  ├─ __init__.py
   │  │  └─ fetch_and_export.py
   │  ├─ domain/
   │  │  ├─ __init__.py
   │  │  ├─ gcs_storage_port.py
   │  │  └─ kaggle_service_port.py
   │  └─ infrastructure/
   │     ├─ __init__.py
   │     ├─ gcs_storage.py
   │     └─ kaggle_service.py
   ├─ pyproject.toml
   ├─ Dockerfile
   └─ README.md
```

---

## `pyproject.toml`

Register the package and the console script:

```toml
[project]
name = "kaggle-upload"
version = "0.1.0"
requires-python = ">=3.10"

[project.scripts]
mock-run = "app.main:main"

[tool.setuptools.packages.find]
where = ["."]
include = ["app*"]

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
```

---

## `app/main.py`

Define the `main` function and use relative or absolute imports:

```python
from .infrastructure.kaggle_service import KaggleService
from .infrastructure.gcs_storage import GCSStorageService
from .application.fetch_and_export import FetchAndExport

def main() -> None:
    kaggle = KaggleService()
    gcs = GCSStorageService(bucket="my-test-bucket", prefix="datasets/")
    use_case = FetchAndExport(kaggle, gcs)
    use_case.run("urbansound8k/urbansound8k", "./data", "us8k/")

if __name__ == "__main__":
    main()
```

---

## Run without installing

From the package directory:

```bash
cd apps/kaggle-upload
python -m app.main
```

---

## Install in editable mode

```bash
cd apps/kaggle-upload
pip install -e .
mock-run
```

---

## Dockerfile

Example file for building the image:

```dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1     PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml README.md ./
COPY app ./app

RUN pip install --no-cache-dir .

RUN mkdir -p /app/data

ENTRYPOINT ["mock-run"]
```

---

## Build and run with Docker

Build:

```bash
cd apps/kaggle-upload
docker build -t kaggle-upload:dev .
```

Run:

```bash
docker run --rm -it kaggle-upload:dev
```

Run with environment variables:

```bash
docker run --rm -it   -e BUCKET="my-test-bucket"   -e PREFIX="datasets/us8k/"   kaggle-upload:dev
```

---

## `.gitignore`

Place in the repository root:

```gitignore
__pycache__/
*.py[cod]
*.egg-info/
.eggs/
dist/
build/
.venv/
.env
.vscode/
.idea/
.DS_Store
Thumbs.db
```

To remove cached files already committed:

```bash
git rm -r --cached **/__pycache__/
git rm -r --cached **/*.egg-info/
git commit -m "remove build artifacts"
```

---

## Troubleshooting

- **`ModuleNotFoundError: No module named 'infrastructure'`**  
  Use `from app.infrastructure...` or add `__init__.py` in `app/`.

- **`attempted relative import with no known parent package`**  
  Run `python -m app.main` from `apps/kaggle-upload`.

- **`ImportError: cannot import name 'main'`**  
  Ensure `def main()` exists in `app/main.py`.

- **`mock-run: command not found`**  
  Confirm `pip install .` ran successfully and `[project.scripts]` is present.
