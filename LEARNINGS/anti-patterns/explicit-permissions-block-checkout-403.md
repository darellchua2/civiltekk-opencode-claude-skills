# Anti-pattern: explicit `permissions:` block + checkout without `contents: read`

An explicit `permissions:` block switches the job to explicit mode — every unlisted scope becomes `none`, and `actions/checkout` under `contents: none` fails with "Resource not accessible by integration" (403). Pair any scoped block whose job runs checkout with `contents: read`, and pin it in the workflow-shape bats test (#446 review; actions/labeler#870).
