#!/bin/bash

OTEL_SERVICE_NAME=dice-requester \
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=development,service.name=kafka_test,service.instance.id=consumer \
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
OTEL_EXPORTER_OTLP_PROTOCOL=grpc \
OTEL_TRACES_EXPORTER=otlp \
OTEL_METRICS_EXPORTER=otlp \
OTEL_LOGS_EXPORTER=otlp \
OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true \
OTEL_EXPORTER_OTLP_INSECURE=true \
opentelemetry-instrument \
    python requester.py
