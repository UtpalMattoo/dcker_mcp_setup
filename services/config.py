"""Compatibility entry point for embedding config.

Why this exists: older imports can keep working while the active
implementation lives in services.ai_pipeline.config.
"""

from services.ai_pipeline.config import (
	ConfigError,
	EmbeddingConfig,
	load_embedding_config,
	run_startup_health_checks,
)

__all__ = [
	"ConfigError",
	"EmbeddingConfig",
	"load_embedding_config",
	"run_startup_health_checks",
]
