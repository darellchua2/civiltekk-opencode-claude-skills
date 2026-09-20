# Pattern: jq @tsv needs sentinels for nullable columns

`jq @tsv` output parsed with `IFS=$'\t' read` collapses empty cells — tab is IFS whitespace, so a null field shifts every later column left. Emit a sentinel for nullable columns in the jq program (`// "false"`) and rely on positional parsing only for never-null enum fields (#446 conflict labeler).
