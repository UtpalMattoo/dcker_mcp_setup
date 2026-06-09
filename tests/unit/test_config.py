"""Tests for embedding config behavior in plain terms.

These tests set environment variables with monkeypatch to mimic how the app
would run in different environments without changing real machine settings.
"""

import pytest

from services.config import ConfigError, load_embedding_config, run_startup_health_checks


def test_missing_provider_fails(monkeypatch):
    """Provider must be explicit so startup behavior is predictable."""
    monkeypatch.delenv("EMBEDDING_PROVIDER", raising=False)
    with pytest.raises(ConfigError):
        load_embedding_config(validate_runtime=False)


def test_load_sentence_transformers_config(monkeypatch):
    """Valid local-provider settings should load into a clean config object."""
    monkeypatch.setenv("EMBEDDING_PROVIDER", "sentence_transformers")
    monkeypatch.delenv("EMBEDDING_MODEL", raising=False)
    config = load_embedding_config(validate_runtime=False)
    assert config.provider == "sentence_transformers"
    assert config.model == "all-MiniLM-L6-v2"
    assert config.dimensions == 384


def test_unsupported_provider(monkeypatch):
    """Unknown providers should fail fast instead of falling back silently."""
    monkeypatch.setenv("EMBEDDING_PROVIDER", "unknown")
    with pytest.raises(ConfigError):
        load_embedding_config(validate_runtime=False)


def test_openai_requires_api_key(monkeypatch):
    """OpenAI path must require API key to avoid runtime surprises."""
    monkeypatch.setenv("EMBEDDING_PROVIDER", "openai")
    monkeypatch.setenv("EMBEDDING_MODEL", "text-embedding-3-small")
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)

    with pytest.raises(ConfigError):
        load_embedding_config(validate_runtime=False)


def test_dimension_override_mismatch_fails(monkeypatch):
    """Manual dimension override should be blocked if it conflicts with model output."""
    monkeypatch.setenv("EMBEDDING_PROVIDER", "sentence_transformers")
    monkeypatch.setenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    monkeypatch.setenv("EMBEDDING_DIMENSIONS", "512")

    with pytest.raises(ConfigError):
        load_embedding_config(validate_runtime=False)


def test_startup_health_check_writable_cache(monkeypatch, tmp_path):
    """Startup checks should confirm cache path can be used before ingestion starts."""
    monkeypatch.setenv("EMBEDDING_PROVIDER", "sentence_transformers")
    monkeypatch.setenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    monkeypatch.setenv("HF_HOME", str(tmp_path / "cache"))
    config = load_embedding_config(validate_runtime=False)

    run_startup_health_checks(config, check_runtime=False)
