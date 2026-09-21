# Pattern: Dual-provider catalog entry proves endpoint swap

Swapping a model id in an inline API recipe that selects between two provider endpoints (coding-plan vs PAYG keys) is provable without a live API call when `installer/provider-models.json` — contractually pinned to the models.dev catalog — lists the replacement under BOTH provider prefixes the recipe can resolve to. Used to verify the pre-5.3-vision → glm-5.3-flash swap in the image-analyzer fallback (glm-5.3-flash listed under both `zai-coding-plan` and `zai`, plus a `resolve-models.mjs` guard run on a /tmp purged copy). Replicate for any future recipe/model swap instead of touching `auth.json` for a live probe. On purge tickets, keep candidates token-free — name the class ("the purged pre-5.3 vision model"), not the literal id, so the branch's own acceptance grep stays green.

**Confidence:** high
**Scope:** project
**Evidence:** installer/provider-models.json (glm-5.3-flash under both prefixes) + installer/resolve-models.mjs guard (L345-392), verified 2026-09-21
**Date:** 2026-09-21
