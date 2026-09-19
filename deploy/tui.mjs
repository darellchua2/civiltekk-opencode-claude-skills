#!/usr/bin/env node
// deploy/tui.mjs
//
// Zero-dependency interactive terminal UI dispatcher for the v2.0 model system.
// The primitives + flows live in installer/tui-primitives.mjs (extracted so other
// tools like installer/init.mjs can import them WITHOUT triggering this dispatch,
// which calls process.exit on run).
//
// Flows (first positional arg):
//   provider-picker   Arrow-key select a provider preset; write models.json
//   migration-review  Show before/after table (via resolver --json), confirm
//   override-editor   Pick agents to pin with a custom model
//   tier-editor       Edit the model of each tier for a chosen provider
//
// Non-TTY / piped stdin: flows exit non-zero (except migration-review with --yes).

import {
  parseArgs, flowProviderPicker, flowMigrationReview, flowOverrideEditor, flowTierEditor,
} from "../installer/tui-primitives.mjs";

const flow = process.argv[2];
const parsed = parseArgs(process.argv.slice(3));
(async () => {
  switch (flow) {
    case "provider-picker": await flowProviderPicker(parsed); break;
    case "migration-review": await flowMigrationReview(parsed); break;
    case "override-editor": await flowOverrideEditor(parsed); break;
    case "tier-editor": await flowTierEditor(parsed); break;
    default:
      console.error("usage: tui.mjs <provider-picker|migration-review|override-editor|tier-editor> [opts]");
      process.exit(2);
  }
  // Explicit exit — singleSelect/multiSelect resume stdin for keypress capture,
  // and a resumed stdin handle would keep node alive (hanging the caller's `&&`).
  process.exit(0);
})().catch((e) => { console.error(`tui error: ${e.message}`); process.exit(1); });
