from __future__ import annotations
"""Load embedding settings for Phase 1.

This module keeps provider/model/dimension rules in one place so the rest of
the pipeline can stay simple and consistent.
"""

import importlib.util
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Dict


class ConfigError(ValueError):
	"""Raised when embedding configuration is invalid."""


PROVIDER_MODEL_DIMENSIONS: Dict[str, Dict[str, int]] = {
	"openai": {
		"text-embedding-3-small": 1536,
		"text-embedding-3-large": 3072,
	},
	"sentence_transformers": {
		"all-MiniLM-L6-v2": 384,
		"all-mpnet-base-v2": 768,
	},
	"precomputed": {
		"qdrant-dbpedia-entities-100k-openai-1536": 1536,
	},
}


@dataclass(frozen=True)
class EmbeddingConfig:
	provider: str
	model: str
	dimensions: int
	openai_api_key: str | None = None
	hf_cache_dir: str = "/cache/huggingface"
	hf_dataset_name: str = "Qdrant/dbpedia-entities-100k"
	hf_dataset_split: str = "train"


def _validate_cache_dir(path_value: str) -> None:
	"""Verify the cache path exists and is writable at runtime."""
	cache_path = Path(path_value)
	cache_path.mkdir(parents=True, exist_ok=True)
	probe_file = cache_path / ".write_check"
	probe_file.write_text("ok", encoding="utf-8")
	probe_file.unlink(missing_ok=True)


def _validate_local_provider_runtime() -> None:
	"""Check that local embedding dependencies are installed."""
	if importlib.util.find_spec("sentence_transformers") is None:
		raise ConfigError(
			"sentence_transformers provider selected but sentence-transformers is not installed"
		)


def load_embedding_config(validate_runtime: bool = True) -> EmbeddingConfig:
	"""Read and validate environment-based embedding settings.

	Why this exists: Phase 1 needs config-only provider switching and strict
	dimension safety before vectors are written to Qdrant.
	"""
	provider = os.getenv("EMBEDDING_PROVIDER")
	if not provider:
		raise ConfigError("EMBEDDING_PROVIDER must be set explicitly")
	provider = provider.strip().lower()

	if provider not in PROVIDER_MODEL_DIMENSIONS:
		supported = ", ".join(sorted(PROVIDER_MODEL_DIMENSIONS))
		raise ConfigError(f"Unsupported embedding provider: {provider}. Supported: {supported}")

	model = os.getenv("EMBEDDING_MODEL")
	if not model:
		model = next(iter(PROVIDER_MODEL_DIMENSIONS[provider].keys()))
	model = model.strip()

	if model not in PROVIDER_MODEL_DIMENSIONS[provider]:
		supported_models = ", ".join(sorted(PROVIDER_MODEL_DIMENSIONS[provider]))
		raise ConfigError(
			f"Unsupported model '{model}' for provider '{provider}'. Supported: {supported_models}"
		)

	derived_dimensions = PROVIDER_MODEL_DIMENSIONS[provider][model]
	configured_dimensions = os.getenv("EMBEDDING_DIMENSIONS")
	if configured_dimensions:
		try:
			configured_value = int(configured_dimensions)
		except ValueError as exc:
			raise ConfigError("EMBEDDING_DIMENSIONS must be an integer") from exc
		if configured_value != derived_dimensions:
			raise ConfigError(
				"Configured EMBEDDING_DIMENSIONS does not match model-derived dimensions"
			)

	openai_api_key = os.getenv("OPENAI_API_KEY")
	hf_cache_dir = os.getenv("HF_HOME", "/cache/huggingface")
	hf_dataset_name = os.getenv("HF_DATASET_NAME", "Qdrant/dbpedia-entities-100k")
	hf_dataset_split = os.getenv("HF_DATASET_SPLIT", "train")

	if provider == "openai" and not openai_api_key:
		raise ConfigError("OPENAI_API_KEY is required when EMBEDDING_PROVIDER=openai")

	if provider == "sentence_transformers" and validate_runtime:
		_validate_local_provider_runtime()

	return EmbeddingConfig(
		provider=provider,
		model=model,
		dimensions=derived_dimensions,
		openai_api_key=openai_api_key,
		hf_cache_dir=hf_cache_dir,
		hf_dataset_name=hf_dataset_name,
		hf_dataset_split=hf_dataset_split,
	)


def run_startup_health_checks(
	config: EmbeddingConfig,
	check_cache_writable: bool = True,
	check_runtime: bool = True,
) -> None:
	"""Run runtime checks separately from config parsing.

	Why separate: config loading should be lightweight and predictable, while
	runtime checks can safely touch filesystem and installed packages.
	"""
	if config.provider == "sentence_transformers":
		if check_runtime:
			_validate_local_provider_runtime()
		if check_cache_writable:
			_validate_cache_dir(config.hf_cache_dir)
