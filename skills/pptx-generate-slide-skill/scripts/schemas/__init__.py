"""Schema definitions package for the pptx-generate-slide-skill engine.

Exposes the per-slide-type schemas and the standalone validator so callers can
import a single, stable entry point::

    from schema_validator import validate_slide_data_list
"""

from .slide_schemas import (
    CHART_OPTIONS_SPEC,
    CHART_TYPES,
    SLIDE_SCHEMAS,
    VALID_SLIDE_TYPES,
)

__all__ = [
    "SLIDE_SCHEMAS",
    "CHART_OPTIONS_SPEC",
    "CHART_TYPES",
    "VALID_SLIDE_TYPES",
]
