# Partial version-normalization sweep leaves display sites lying

- **Category**: anti-pattern
- **Confidence**: 0.8
- **Scope**: project
- **Evidence**: #499 review — `opencode --version` prints a prefixed banner ("opencode v2.0.11"); normalizing only the compare sites in setup_opencode/update_opencode_cli/check_for_updates_only left print_summary's `v${opencode_version}` interpolating raw output ("✓ @opencode/cli: Installed vopencode v2.0.11") and, worse, certifying an un-migrated 1.x install under the v2 package label. Fixed with a shared `normalize_version()` helper used at every version consumer + a `case 1.*` honest-label branch in print_summary.

When a binary's version banner format differs from a bare semver, a normalization fix that touches only the compare sites is a partial sweep: every consumer of the string — comparisons AND display/summary interpolation — must route through one shared normalizer, or display sites print raw banners and, for format-crossing upgrades (v1 bare vs v2 prefixed), can mislabel which package is actually installed. Prefer extracting `normalize_version()` at the second consumer; the sweep is complete only when no raw call remains downstream of the banner.
