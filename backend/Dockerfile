FROM python:3.12-slim

WORKDIR /app

ENV SUPERCRONIC_VERSION=v0.2.30

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSLO "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-amd64" && \
    install -m 0755 supercronic-linux-amd64 /usr/local/bin/supercronic && \
    rm supercronic-linux-amd64 && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080

CMD ["bash", "-c", "supercronic /app/cron/clear_cache.cron & exec uvicorn app:app --host 0.0.0.0 --port 8080"]

