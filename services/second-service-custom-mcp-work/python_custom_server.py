import json
import logging
import os
import sys
from pathlib import Path

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "service": os.getenv("OTEL_SERVICE_NAME", "second-service-custom-mcp-work"),
            "message": record.getMessage(),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload)


def configure_logging() -> logging.Logger:
    logger = logging.getLogger("second_service_custom_mcp_work")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    formatter = JsonFormatter()

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setFormatter(formatter)
    logger.addHandler(stdout_handler)

    log_file = os.getenv(
        "SERVICE_LOG_FILE", "/var/log/services/second-service-custom-mcp-work/app.log"
    )
    log_path = Path(log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    return logger


def configure_tracing() -> None:
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://alloy:4317")
    service_name = os.getenv("OTEL_SERVICE_NAME", "second-service-custom-mcp-work")
    resource_attrs = os.getenv(
        "OTEL_RESOURCE_ATTRIBUTES",
        "service.name=second-service-custom-mcp-work,service.version=1.0",
    )
    resource = Resource.create(
        {
            k.strip(): v.strip()
            for item in resource_attrs.split(",")
            if "=" in item
            for k, v in [item.split("=", 1)]
        }
        | {"service.name": service_name}
    )

    provider = TracerProvider(resource=resource)
    exporter = OTLPSpanExporter(endpoint=endpoint, insecure=True)
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)


def main():
    logger = configure_logging()
    configure_tracing()
    tracer = trace.get_tracer("second-service-custom-mcp-work")

    with tracer.start_as_current_span("mcp_placeholder_operation") as span:
        span.set_attribute("mcp.operation", "placeholder")
        logger.info("Python server placeholder. Not in use. Not for MCPs already built")

if __name__ == "__main__":
    main()