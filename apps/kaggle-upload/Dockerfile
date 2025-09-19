FROM python:3.11-slim

RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY /app/pyproject.toml /app/README.md ./

RUN pip install --no-cache-dir -e .

COPY . .

ENV PYTHONPATH=/app

ENTRYPOINT ["mock-run"]

# CMD ["fetch", "--ref", "urbansound8k/urbansound8k"]
