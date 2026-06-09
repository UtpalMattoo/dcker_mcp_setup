"""Tests for cache-path related config and startup checks.

We use temporary folders so tests do not touch real cache directories.
"""

from pathlib import Path

from services.config import load_embedding_config, run_startup_health_checks


def test_cache_path_from_env(monkeypatch, tmp_path):
    """HF_HOME from env should be copied into config exactly."""
    cache_dir = tmp_path / "hf"
    monkeypatch.setenv("EMBEDDING_PROVIDER", "sentence_transformers")
    monkeypatch.setenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    monkeypatch.setenv("HF_HOME", str(cache_dir))

    config = load_embedding_config(validate_runtime=False)
    assert config.hf_cache_dir == str(cache_dir)


def test_cache_path_write_check(monkeypatch, tmp_path):
    """Startup checks should create/verify cache path safely."""
    cache_dir = tmp_path / "hf_write"
    monkeypatch.setenv("EMBEDDING_PROVIDER", "sentence_transformers")
    monkeypatch.setenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    monkeypatch.setenv("HF_HOME", str(cache_dir))

    config = load_embedding_config(validate_runtime=False)
    run_startup_health_checks(config, check_runtime=False)
    assert Path(config.hf_cache_dir).exists()
