from __future__ import annotations

from abc import ABC, abstractmethod
from typing import List


class EmbeddingProviderError(RuntimeError):
    """Normalized provider-level error for embedding operations."""


class EmbeddingProvider(ABC):
    @abstractmethod
    def embed_text(self, text: str) -> List[float]:
        """Return a vector embedding for input text."""
