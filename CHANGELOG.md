# Changelog

All notable changes to this project will be documented in this file.

## [9.2.1](https://github.com/darellchua2/opencode-config-template/compare/v9.2.0...v9.2.1) (2026-09-18)

### Bug Fixes

* **init:** conflict-gate project models.json like opencode.json ([#412](https://github.com/darellchua2/opencode-config-template/issues/412)) ([#413](https://github.com/darellchua2/opencode-config-template/issues/413)) ([30784da](https://github.com/darellchua2/opencode-config-template/commit/30784dae55f79f527116dd4d7d272a58f4b59697))

## [9.2.0](https://github.com/darellchua2/opencode-config-template/compare/v9.1.3...v9.2.0) (2026-09-18)

### Features

* **agents:** route dwg/image redraw to cad-redraw-skill ([01dd772](https://github.com/darellchua2/opencode-config-template/commit/01dd772cc591978df71b37f578bf2c8dc6ea6f22))
* **skills:** add cad-redraw fingerprint and spec-to-dxf scripts ([0f14c74](https://github.com/darellchua2/opencode-config-template/commit/0f14c74863c00fc14ec03a9473a219e6e15bd87e))
* **skills:** add cad-redraw image pipeline scripts ([751fe4c](https://github.com/darellchua2/opencode-config-template/commit/751fe4c50f7157efb1acfd3d96173f0473105082))
* **skills:** add cad-redraw-skill contract and references ([16acdec](https://github.com/darellchua2/opencode-config-template/commit/16acdec655ce6c3021d7681b20870cc77f1086f3))

### Bug Fixes

* **skills:** close re-review residuals in cad-redraw loaders ([507099d](https://github.com/darellchua2/opencode-config-template/commit/507099dec50c8ab9c232f708ee42ce4a235642ed))
* **skills:** harden cad-redraw validators per code review ([8bc684b](https://github.com/darellchua2/opencode-config-template/commit/8bc684b1246be3d8d786e8388002eb79ead9cc0c))

### Documentation

* **learnings:** capture skill-add count blast radius and docs-registry artifact ([8e39ad7](https://github.com/darellchua2/opencode-config-template/commit/8e39ad71495aaeb28a0a696d364aa253ab1701c2))
* **learnings:** capture validator-crash anti-pattern from [#402](https://github.com/darellchua2/opencode-config-template/issues/402) review ([081210f](https://github.com/darellchua2/opencode-config-template/commit/081210f8d003a204e2f755e7078885671284adb2))
* **plan:** add PLAN-402.md for [#402](https://github.com/darellchua2/opencode-config-template/issues/402) ([ecb2a16](https://github.com/darellchua2/opencode-config-template/commit/ecb2a16f43165225c3ceab93e184b6ef195f4872))
* **plan:** amend PLAN-402.md per architecture review ([7dce1b3](https://github.com/darellchua2/opencode-config-template/commit/7dce1b3417b6bce323ec31cef38f99310fbf7f7b))
* **plan:** ride registry rebuild with phases 1 and 4 (BT-157 per-commit invariant) ([e6602a9](https://github.com/darellchua2/opencode-config-template/commit/e6602a9cd28013002a17cc699997d8b04fab3013))
* **plan:** tick PLAN-402 acceptance criteria ([99694ab](https://github.com/darellchua2/opencode-config-template/commit/99694ab4520b7251bb435458fdff4994b7a56500))
* **skills:** fill missing helper docstrings in spec_to_dxf ([476f8da](https://github.com/darellchua2/opencode-config-template/commit/476f8da4800f9b903b3a2f94e057e622993299bb))

## [9.1.3](https://github.com/darellchua2/opencode-config-template/compare/v9.1.2...v9.1.3) (2026-09-18)

### Bug Fixes

* **installer:** project-scope installs honor agent-overrides.json ([#401](https://github.com/darellchua2/opencode-config-template/issues/401)) ([#410](https://github.com/darellchua2/opencode-config-template/issues/410)) ([889e7a7](https://github.com/darellchua2/opencode-config-template/commit/889e7a7fcbdd94607d1cf159563e62d7b88cabe9))

## [9.1.2](https://github.com/darellchua2/opencode-config-template/compare/v9.1.1...v9.1.2) (2026-09-18)

### Bug Fixes

* **pipeline:** extend pipeline-mode skip set to step 3 + supersede all restatements ([1c62d41](https://github.com/darellchua2/opencode-config-template/commit/1c62d4120ebc1f26dda7dd1edfea424979574d8b))

### Code Refactoring

* **pipeline:** pipeline-mode PR handoff — skip pr-workflow steps 2/2.5/4 ([6385bd1](https://github.com/darellchua2/opencode-config-template/commit/6385bd160b5640be80e97727985c7acb8e19f16d))
* **skills:** handle refactor/DRY directly — code-review-subagent is review-only ([3099b69](https://github.com/darellchua2/opencode-config-template/commit/3099b69f7a44fc1060d4d8bd5338f84663e37941))

### Documentation

* **agents:** disposition step 8 in pipeline-mode block per re-review note ([1efcd2a](https://github.com/darellchua2/opencode-config-template/commit/1efcd2aa6b0b7403e70169b71d713b3f317c4a46))
* **plan:** add PLAN-399.md for [#399](https://github.com/darellchua2/opencode-config-template/issues/399) ([7aafdf2](https://github.com/darellchua2/opencode-config-template/commit/7aafdf23425db69a2fa994cec270c3fc06e3453a))
* **plan:** apply architecture+Mode R amendments to PLAN-399 ([74bc965](https://github.com/darellchua2/opencode-config-template/commit/74bc96514f48c656d20a3651a19d3fbfdafa990c))
* **plan:** tick PLAN-399 acceptance criteria — all 5 satisfied ([d579398](https://github.com/darellchua2/opencode-config-template/commit/d579398cd2ae5d48bc26c0a1a32cadfdbe2f1abd))
* **plan:** verify PLAN-399 Phase 3 — registry no-drift, scoped proofs, bats INCONCLUSIVE ([7fc5217](https://github.com/darellchua2/opencode-config-template/commit/7fc5217b5dde4974070d676d6e542c7c9eb30d64))

## [9.1.1](https://github.com/darellchua2/opencode-config-template/compare/v9.1.0...v9.1.1) (2026-09-18)

### Bug Fixes

* **installer:** update reports per-target outcomes without dropping partial updates ([#400](https://github.com/darellchua2/opencode-config-template/issues/400)) ([#403](https://github.com/darellchua2/opencode-config-template/issues/403)) ([c06bcde](https://github.com/darellchua2/opencode-config-template/commit/c06bcde4cb731fac89a1c02b3431d34a4bdaea79))

## [9.1.0](https://github.com/darellchua2/opencode-config-template/compare/v9.0.0...v9.1.0) (2026-09-18)

### Features

* **skills:** reviewer-owned requirements coverage + Mode R relay ([2c5e66c](https://github.com/darellchua2/opencode-config-template/commit/2c5e66c01b88e9879e7af7608f22139f069da44b)), closes [#397](https://github.com/darellchua2/opencode-config-template/issues/397)

## [9.0.0](https://github.com/darellchua2/opencode-config-template/compare/v8.0.0...v9.0.0) (2026-09-17)

### ⚠ BREAKING CHANGES

* **setup:** single install path + npx update command (#379) (#396)

### Features

* **setup:** single install path + npx update command ([#379](https://github.com/darellchua2/opencode-config-template/issues/379)) ([#396](https://github.com/darellchua2/opencode-config-template/issues/396)) ([9cda837](https://github.com/darellchua2/opencode-config-template/commit/9cda8370ca6f6a6e958a2caeb9109e41b1d89bcd))

## [8.0.0](https://github.com/darellchua2/opencode-config-template/compare/v7.1.1...v8.0.0) (2026-09-17)

### ⚠ BREAKING CHANGES

* **agents:** normalize frontmatter to native v2 permissions (#380) (#395)

### Code Refactoring

* **agents:** normalize frontmatter to native v2 permissions ([#380](https://github.com/darellchua2/opencode-config-template/issues/380)) ([#395](https://github.com/darellchua2/opencode-config-template/issues/395)) ([a04fa6d](https://github.com/darellchua2/opencode-config-template/commit/a04fa6d47eea1b676cb7efa56cb2b08bf323220b)), closes [#379](https://github.com/darellchua2/opencode-config-template/issues/379) [#379](https://github.com/darellchua2/opencode-config-template/issues/379) [#383](https://github.com/darellchua2/opencode-config-template/issues/383)

## [7.1.1](https://github.com/darellchua2/opencode-config-template/compare/v7.1.0...v7.1.1) (2026-09-17)

### Bug Fixes

* **skills:** restore autoresearch reference citations required by bats suite ([4673550](https://github.com/darellchua2/opencode-config-template/commit/4673550ab8f9a813e3bcb7c8591424a765428f56))
* **skills:** restore clean-code imperative gating preamble (bats default-behavior suite) ([ec82b1c](https://github.com/darellchua2/opencode-config-template/commit/ec82b1c141e3d5c40014cd0e0c87b06c67b76554))

### Code Refactoring

* **skills:** add lean-standard bloat check to skills maintainer ([e0a98f9](https://github.com/darellchua2/opencode-config-template/commit/e0a98f9dd6284acfd7eee5eabb766835e24a6998))
* **skills:** adopt lean standard in opencode-skill-creation-skill ([fd77a84](https://github.com/darellchua2/opencode-config-template/commit/fd77a84f06a50c075e225ee3e42c1e069a3d0b64))
* **skills:** drop vestigial numeric anchors, fix api-design related labels ([fe13e6c](https://github.com/darellchua2/opencode-config-template/commit/fe13e6c0ed1829b10dbc84d5dfe4e6fd5c69f5e1))
* **skills:** split docx-creation reference into sibling file ([7ea53d1](https://github.com/darellchua2/opencode-config-template/commit/7ea53d1b7fa8a5c202e34d57b285b75ccad3c81e))
* **skills:** split office reference material into sibling files ([5ce5d7d](https://github.com/darellchua2/opencode-config-template/commit/5ce5d7d9df8d8262c425834fe1ee0fef762f4590))
* **skills:** trim ceremony from 20 category-C skills ([7693673](https://github.com/darellchua2/opencode-config-template/commit/7693673eb712a2f105e2e96cbfee712540f084a9))
* **skills:** trim ceremony from git-semantic-commits-skill ([ef32770](https://github.com/darellchua2/opencode-config-template/commit/ef32770fbc8a269802924de05e47a1d468612e12))
* **skills:** trim HCL recipes from opentofu-kubernetes-explorer-skill ([76db575](https://github.com/darellchua2/opencode-config-template/commit/76db5759c75df70cf4128099516135f0f1e20208))
* **skills:** trim textbook content from 10 category-A skills ([30a71d8](https://github.com/darellchua2/opencode-config-template/commit/30a71d857b3b68fefe520a900e52680290ca7c0c))
* **skills:** trim textbook content from clean-code-skill ([e1d26fc](https://github.com/darellchua2/opencode-config-template/commit/e1d26fc155a852272ca40c9f5e83337289b909cf))
* **skills:** trim vendor API reference from nextjs-image-usage-skill ([380c28b](https://github.com/darellchua2/opencode-config-template/commit/380c28b10af9dbc1a18b255af983c75b385bdb66))
* **skills:** trim vendor references from 12 category-B skills ([8a9265f](https://github.com/darellchua2/opencode-config-template/commit/8a9265f604138d4f204292c31165f302f5ad7963))

### Documentation

* **plan:** add PLAN-383.md for [#383](https://github.com/darellchua2/opencode-config-template/issues/383) ([8eadb7f](https://github.com/darellchua2/opencode-config-template/commit/8eadb7f315edde89d01c5516e9bfe08a5d9c0ce0))
* **plan:** apply requirements review findings to PLAN-383.md ([41bb3a1](https://github.com/darellchua2/opencode-config-template/commit/41bb3a112ded5265dc259969100ec4b4382c3be4))
* **plan:** gate path deploy/ -> installer/ per [#390](https://github.com/darellchua2/opencode-config-template/issues/390) ([fc20883](https://github.com/darellchua2/opencode-config-template/commit/fc20883fb756173f5f6ccf9159ae7d13317464eb))
* **plan:** tick Phase 2 trace + acceptance criteria — final validation ([0221c25](https://github.com/darellchua2/opencode-config-template/commit/0221c25090ad8b910fc47b454bcc91cdf78ad1c4))
* **plan:** trace Phase 1 pilot steps 1.1-1.5 (5 commits) ([75cdd27](https://github.com/darellchua2/opencode-config-template/commit/75cdd276b1806a227e709cb985ee87586255afcc))
* **plan:** trace Phases 3-4 complete (batches A-E + invariants) ([355d989](https://github.com/darellchua2/opencode-config-template/commit/355d9898d168d758adac733bba8979792b191cd4))
* **plan:** trace step 1.6 user approval gate ([5ac7577](https://github.com/darellchua2/opencode-config-template/commit/5ac757747ef45ec76fd72b667290a654b2271f66))
* **plan:** trace step 3.4, note skills/ layout move from [#384](https://github.com/darellchua2/opencode-config-template/issues/384) ([c562af1](https://github.com/darellchua2/opencode-config-template/commit/c562af1054fe8773599f0341df41dbf63bb105b6))

## [7.1.0](https://github.com/darellchua2/opencode-config-template/compare/v7.0.1...v7.1.0) (2026-09-16)

### Features

* **installer:** multi-app install targets — --target opencode|claude ([#377](https://github.com/darellchua2/opencode-config-template/issues/377)) ([#393](https://github.com/darellchua2/opencode-config-template/issues/393)) ([143213e](https://github.com/darellchua2/opencode-config-template/commit/143213e77b171af4a41560e15624493ced2a80f6))

### Documentation

* **migration:** document DCP to v2 checkpoint compaction reasoning ([#385](https://github.com/darellchua2/opencode-config-template/issues/385)) ([#392](https://github.com/darellchua2/opencode-config-template/issues/392)) ([f051539](https://github.com/darellchua2/opencode-config-template/commit/f0515393f2807555166692c536bcba65160f687a))

## [7.0.1](https://github.com/darellchua2/opencode-config-template/compare/v7.0.0...v7.0.1) (2026-09-15)

### Bug Fixes

* **docker:** opencode-owned npm dir + precise goal healthcheck ([#391](https://github.com/darellchua2/opencode-config-template/issues/391)) ([c543217](https://github.com/darellchua2/opencode-config-template/commit/c5432177291cfb4d52f3afd2148a7ca5aeae8742)), closes [#389](https://github.com/darellchua2/opencode-config-template/issues/389)

## [7.0.0](https://github.com/darellchua2/opencode-config-template/compare/v6.1.0...v7.0.0) (2026-09-14)

### ⚠ BREAKING CHANGES

* **installer:** split deploy/ into installer/ + deploy/ (#378) (#390)

### Code Refactoring

* **installer:** split deploy/ into installer/ + deploy/ ([#378](https://github.com/darellchua2/opencode-config-template/issues/378)) ([#390](https://github.com/darellchua2/opencode-config-template/issues/390)) ([56df622](https://github.com/darellchua2/opencode-config-template/commit/56df622c2ed3fd8bbfbafa5706c7a02a086d0ef0)), closes [#281](https://github.com/darellchua2/opencode-config-template/issues/281)

## [6.1.0](https://github.com/darellchua2/opencode-config-template/compare/v6.0.1...v6.1.0) (2026-09-14)

### Features

* **plugins:** re-add goal mode via @prevalentware/opencode-goal-plugin (OpenCode v2) ([#388](https://github.com/darellchua2/opencode-config-template/issues/388)) ([43e3c6c](https://github.com/darellchua2/opencode-config-template/commit/43e3c6cbd386ed9066733e777dea807b36713a9e)), closes [#382](https://github.com/darellchua2/opencode-config-template/issues/382) [#387](https://github.com/darellchua2/opencode-config-template/issues/387) [#382](https://github.com/darellchua2/opencode-config-template/issues/382) [#382](https://github.com/darellchua2/opencode-config-template/issues/382) [#382](https://github.com/darellchua2/opencode-config-template/issues/382)

## [6.0.1](https://github.com/darellchua2/opencode-config-template/compare/v6.0.0...v6.0.1) (2026-09-14)

### Bug Fixes

* **review:** scaffold tree, anchored tarball gate, drop dead dockerignore ([6e5fff0](https://github.com/darellchua2/opencode-config-template/commit/6e5fff0cd20779ee76c742d90812e85c050af71f))
* **tests:** restore pinned bats-core submodule pointer ([9ac1901](https://github.com/darellchua2/opencode-config-template/commit/9ac19010b0f97a0d3ec8fd8d317bba2eb5df73e1))

### Code Refactoring

* **deploy:** implement Phase 2 — rewire code paths to root content ([7a0130c](https://github.com/darellchua2/opencode-config-template/commit/7a0130ceaa1bbfa07e2a54cc9cfaadbe588e6f69))
* **deploy:** implement Phase 3 — rewire setup scripts to root content ([33883d5](https://github.com/darellchua2/opencode-config-template/commit/33883d52385ef63dc9bd687268e33773d9c9a0fc))
* **repo:** implement Phase 1 — move content to root + bridge ([54a65bf](https://github.com/darellchua2/opencode-config-template/commit/54a65bf30d5f24330b31c3b4aceb1d0b82823ec7))

### Documentation

* **content:** implement Phase 6 — self-references on new layout ([c733638](https://github.com/darellchua2/opencode-config-template/commit/c73363828168bc6b0332a54fded68c17240d7c91))
* **learnings:** capture path-move CI-gate anchoring + vibeguard search-path pattern ([8689972](https://github.com/darellchua2/opencode-config-template/commit/8689972e77e4a2158c402a851cc074962cc9f9af)), closes [#381](https://github.com/darellchua2/opencode-config-template/issues/381)
* **plan:** add PLAN-381.md for [#381](https://github.com/darellchua2/opencode-config-template/issues/381) ([4a5f9f2](https://github.com/darellchua2/opencode-config-template/commit/4a5f9f29e13147a68ccb5402ea2ed22c92707940))
* **plan:** apply review findings to PLAN-381 ([d1a8458](https://github.com/darellchua2/opencode-config-template/commit/d1a8458e14a79da0fbc99fe965368a8b953280b0))
* **repo:** implement Phase 7 — docs on new layout, all final gates green ([52caa8c](https://github.com/darellchua2/opencode-config-template/commit/52caa8c21712d0a0e1a4d9dd8108b7d4cbaf75c6))

## [6.0.0](https://github.com/darellchua2/opencode-config-template/compare/v5.18.2...v6.0.0) (2026-09-14)

### ⚠ BREAKING CHANGES

* **packs:** drop voice pack — plugin has no v2 implementation

### Features

* **packs:** drop voice pack — plugin has no v2 implementation ([4d0ed8d](https://github.com/darellchua2/opencode-config-template/commit/4d0ed8dfe525dcefa1ebfddab44e1e08be6ee01a))

## [5.18.2](https://github.com/darellchua2/opencode-config-template/compare/v5.18.1...v5.18.2) (2026-09-14)

### Bug Fixes

* **docling:** default transport to stdio and survive PEP 668 pip ([021c37a](https://github.com/darellchua2/opencode-config-template/commit/021c37a79bd2b58d0e2231a195056aff985489a1))

## [5.18.1](https://github.com/darellchua2/opencode-config-template/compare/v5.18.0...v5.18.1) (2026-09-14)

### Bug Fixes

* **repo-setup:** write full MCP entries, not disabled-only stubs ([234e813](https://github.com/darellchua2/opencode-config-template/commit/234e813152e6211d519297cea6b9a23ba8b2eb60))

### Documentation

* **migration:** record v2 MCP stub-replacement and cli.json TUI-plugin traps ([e4240bc](https://github.com/darellchua2/opencode-config-template/commit/e4240bccd71431e64a97a0a7474d29570d294f9b))

## [5.18.0](https://github.com/darellchua2/opencode-config-template/compare/v5.17.0...v5.18.0) (2026-09-14)

### Features

* **plugins:** port local plugins to v2 API, prune v1-only npm pins ([e918ece](https://github.com/darellchua2/opencode-config-template/commit/e918ece40b28568542e78005e0a9a63aafa7d27d))
* **skills:** add opencode-v2-migration skill + subagent (149th skill, 34th agent) ([33fc115](https://github.com/darellchua2/opencode-config-template/commit/33fc115fd64a94819070a86c60f4c5a56e0079db))

### Bug Fixes

* **deploy:** write global config to opencode.json, not config.json ([a21504e](https://github.com/darellchua2/opencode-config-template/commit/a21504e9dfae6d036e243848eecd54bf721058cf))
* **docker:** healthcheck against V2 /api/health endpoint ([d5aa298](https://github.com/darellchua2/opencode-config-template/commit/d5aa298c9f45edb98d851ed3f66f7b93f27c24ff))
* **skills,deploy:** finish plugin-drop reference cleanup; harden markitdown install check ([158e316](https://github.com/darellchua2/opencode-config-template/commit/158e3164366783a21ad85fda7559ef5c1f746838))
* **skills:** repoint plugin-dependent references after v2 plugin cleanup ([a385f0d](https://github.com/darellchua2/opencode-config-template/commit/a385f0d68b7daa76deb3c0b748918f28991919f5))

### Documentation

* mark V1-plugin features inert on OpenCode v2, fix v2 doc links ([a875e7c](https://github.com/darellchua2/opencode-config-template/commit/a875e7cde0a6278dfbab043a227b954d45bb6842))

## [5.17.0](https://github.com/darellchua2/opencode-config-template/compare/v5.16.0...v5.17.0) (2026-09-13)

### Features

* **config:** convert opencode.json to native v2 shape (Phase 1) ([6f8a407](https://github.com/darellchua2/opencode-config-template/commit/6f8a407031e8e47cd62cf7a74f1e59bc0dfdcb00))
* **deploy:** implement Phase 2 — v2 deploy tooling (steps 2.1-2.5) ([4810d22](https://github.com/darellchua2/opencode-config-template/commit/4810d22f25b998a4fe59c95f4aee937d281a1e4c))
* **deploy:** implement Phase 2 remainder — init.mjs + Dockerfile patch (steps 2.6-2.7) ([6261fbc](https://github.com/darellchua2/opencode-config-template/commit/6261fbccfe58a275099c20eacb60fbd3396d0fca))
* **skills:** add email-drafter-skill (Communication) ([a27482b](https://github.com/darellchua2/opencode-config-template/commit/a27482bcd0ff0f261721d3bc343aa6f69538d3ba))

### Bug Fixes

* **deploy:** address code-review findings — permit seed, docs sweep, counts ([72d5c9c](https://github.com/darellchua2/opencode-config-template/commit/72d5c9ca3c7fee3b0f4a689b6718682c55c4dfc4))
* **deploy:** review iter-2 residuals — v2 doc sweep + permit tests ([3031d27](https://github.com/darellchua2/opencode-config-template/commit/3031d2728f0ab676607ffe616c9f76cebd0f87ce))

### Documentation

* **deploy:** implement Phase 4 — v2 doc surfaces + registry rebuild (steps 4.1-4.4) ([0bf42fd](https://github.com/darellchua2/opencode-config-template/commit/0bf42fd4d52c7f0a5e6cd14479c77a4a8b6eeb6d))
* **plan:** add PLAN-374.md for [#374](https://github.com/darellchua2/opencode-config-template/issues/374) ([b478dcf](https://github.com/darellchua2/opencode-config-template/commit/b478dcfa02b40ace34c026c24433c126118e3a25))
* **plan:** fold review findings into PLAN-374 (init.mjs, Docker, packs, cli.json) ([781660c](https://github.com/darellchua2/opencode-config-template/commit/781660c252de54123149948290e6a0beb87fff60))
* **plan:** LEARNINGS bump in 4.4, client-config flag wording in 2.3 ([6f3ba20](https://github.com/darellchua2/opencode-config-template/commit/6f3ba20fbb8619dbcacb7cf4b4473531ebab579a))
* **plan:** tick all acceptance criteria — PLAN-374 complete ([31ebf2b](https://github.com/darellchua2/opencode-config-template/commit/31ebf2be0a433d5961b36a76f7755734e0891b72))

## [5.16.0](https://github.com/darellchua2/opencode-config-template/compare/v5.15.0...v5.16.0) (2026-09-09)

### Features

* **deploy:** install markitdown launcher on --enable-pack (Phase 4) ([2825546](https://github.com/darellchua2/opencode-config-template/commit/28255468aa28a67cb1920a09e135467a81a847f7))

### Bug Fixes

* **config:** migrate source permission.tool denies to permission root (Phase 2) ([c8b8e44](https://github.com/darellchua2/opencode-config-template/commit/c8b8e44f9c672e7589eb07a410bda3682faa56c3))
* **deploy:** add pep668 fallback for launcher install (Phase 6.3) ([f7b2bad](https://github.com/darellchua2/opencode-config-template/commit/f7b2bada86741bbbed6867c7df2371c0b218ad13))
* **deploy:** address code-review findings — ps1 rc clobber, doc residue (Step 9) ([6c9c3fb](https://github.com/darellchua2/opencode-config-template/commit/6c9c3fb1fe61ca1977a419c392b40902aa38aefe))
* **deploy:** migrate all MCP packs to root permission allow keys (Phase 1) ([1d1106a](https://github.com/darellchua2/opencode-config-template/commit/1d1106a2f11b578168b9603837bb6d5f720e7e04))
* **deploy:** review iteration 2 — tail-after-rm, MIGRATION residue, guard scope ([134d9a0](https://github.com/darellchua2/opencode-config-template/commit/134d9a0c9cbcb53897957256233ba4244fda386f))
* **deploy:** track permission key in merge-packs dry-run snapshot (Phase 3) ([f8432cf](https://github.com/darellchua2/opencode-config-template/commit/f8432cf03c7b74c4f3be867a13a9a0176689bdc2))

### Documentation

* **plan:** add PLAN-370.md for [#370](https://github.com/darellchua2/opencode-config-template/issues/370) ([e410185](https://github.com/darellchua2/opencode-config-template/commit/e410185a779f7ad57c521bfceae656616b52aefa))
* **plan:** address review findings in PLAN-370 ([ab66c04](https://github.com/darellchua2/opencode-config-template/commit/ab66c0447ee588f91b70e6394a391469e5b7800f))
* **skills:** correct enable-path docs to root permission patterns (Phase 5) ([d1821ce](https://github.com/darellchua2/opencode-config-template/commit/d1821ce78b07f2488fc85afa9fbf5af196995b1a))

## [5.15.0](https://github.com/darellchua2/opencode-config-template/compare/v5.14.0...v5.15.0) (2026-09-09)

### Features

* **skills:** worktree-pipeline adaptive review, failure policy, CI gate ([#366](https://github.com/darellchua2/opencode-config-template/issues/366)) ([#369](https://github.com/darellchua2/opencode-config-template/issues/369)) ([47fcafc](https://github.com/darellchua2/opencode-config-template/commit/47fcafc473a41036fc9d23733244f843394989b6))

## [5.14.0](https://github.com/darellchua2/opencode-config-template/compare/v5.13.0...v5.14.0) (2026-09-09)

### Features

* **vision:** remove zai-vision skill, MCP entry, profile + registry references (Phase 1) ([faf878b](https://github.com/darellchua2/opencode-config-template/commit/faf878b02a99388ef4abe491ea05841defdaf078))

### Bug Fixes

* **vision:** correct fallback-embed claims to point at image-analyzer only ([6f01649](https://github.com/darellchua2/opencode-config-template/commit/6f01649e27431112253ac43eea4a9d86ff5b4e8c))

### Documentation

* **plan:** add PLAN-GIT-364.md for [#364](https://github.com/darellchua2/opencode-config-template/issues/364) ([4e74723](https://github.com/darellchua2/opencode-config-template/commit/4e74723e383ad72d990d407a8500d44630093bd3))
* **plan:** apply GIT-364 review findings (lean-count, MCP banner, README totals, glm-4.6v-flash wording, bats bootstrap) ([18f37d1](https://github.com/darellchua2/opencode-config-template/commit/18f37d1b9d814b99bbda2c29ff68ab1cb445b2b0))
* purge stale plans/audits/research + refresh allowlist LEARNINGS counts ([#368](https://github.com/darellchua2/opencode-config-template/issues/368)) ([b1ab520](https://github.com/darellchua2/opencode-config-template/commit/b1ab5202506b8e6b92ca70bdf1872aba90b95fc4)), closes [#365](https://github.com/darellchua2/opencode-config-template/issues/365)
* **vision:** rewrite agent/skill prose to inline fallback, drop skill citations (Phase 2) ([c285f0a](https://github.com/darellchua2/opencode-config-template/commit/c285f0a3b896fd882f868876c1454f2133e06fd0))
* **vision:** sync counts across docs, invert MCP test, full gate green (Phase 4) ([4444efa](https://github.com/darellchua2/opencode-config-template/commit/4444efa3a1f4ea6e39712510ada4555d9bb27783))

## [5.13.0](https://github.com/darellchua2/opencode-config-template/compare/v5.12.0...v5.13.0) (2026-09-09)

### Features

* **skills:** vendor wayfinder-skill adapted for opencode ([cabee96](https://github.com/darellchua2/opencode-config-template/commit/cabee96f6a2e73d853cd9089e24941de3ff404f1))

### Code Refactoring

* **reviewers:** extract checklists + shared baseline, slim 4 agents ([18e376a](https://github.com/darellchua2/opencode-config-template/commit/18e376af5a8bd1c19b566e66ddf122e8f22630ce))
* **workflow:** split ticket-creation from plan authoring ([47f280b](https://github.com/darellchua2/opencode-config-template/commit/47f280bdeb94f58dc0251a759fab9bc40ca80d3e))

### Documentation

* **docker:** sync opencode_app/README skill count to 148 ([04e433e](https://github.com/darellchua2/opencode-config-template/commit/04e433e8427e53d5aded2197fb5f3df99142b9e7))
* **sync:** refresh README/AGENTS counts + add /create-ticket docs ([10905a0](https://github.com/darellchua2/opencode-config-template/commit/10905a0c0f6f3b91640c0535fdf334002bdd787b))

## [5.12.0](https://github.com/darellchua2/opencode-config-template/compare/v5.11.0...v5.12.0) (2026-09-01)

### Features

* **deploy:** add ollama as standardized local provider ([eea2689](https://github.com/darellchua2/opencode-config-template/commit/eea26897cdf90b9327bcd070191d840ccd4a7ee6))

## [5.11.0](https://github.com/darellchua2/opencode-config-template/compare/v5.10.0...v5.11.0) (2026-08-31)

### Features

* **deploy:** add voice plugin pack with whisper.cpp build prereqs ([#360](https://github.com/darellchua2/opencode-config-template/issues/360)) ([96eedf4](https://github.com/darellchua2/opencode-config-template/commit/96eedf48b0c7bdb846813dc609e95d61098bd631))

## [5.10.0](https://github.com/darellchua2/opencode-config-template/compare/v5.9.0...v5.10.0) (2026-08-30)

### Features

* **agents:** add zai-media-subagent + zai media skills, repoint vision refs ([#357](https://github.com/darellchua2/opencode-config-template/issues/357)) ([41a8b42](https://github.com/darellchua2/opencode-config-template/commit/41a8b42e82848d430bec4f708ee9a52930313b1b))
* **config:** add zai-custom-plan provider, vision tier repoint, zai MCP servers ([#357](https://github.com/darellchua2/opencode-config-template/issues/357)) ([b326df6](https://github.com/darellchua2/opencode-config-template/commit/b326df61d2119bfbbad6e613cc7fba53b1c325ff))

### Documentation

* **plan:** add PLANS/PLAN-GIT-357.md for GIT-357 ([9035129](https://github.com/darellchua2/opencode-config-template/commit/903512957af8857765e66c99904291401b6de46b))
* **plan:** complete PLAN-GIT-357 checkboxes ([43ae96a](https://github.com/darellchua2/opencode-config-template/commit/43ae96a9c7982f888f430deff5bb7d283dcebef5))
* sync counts/tables for GIT-357 (133 skills, 37 agents, 9 MCP) ([#357](https://github.com/darellchua2/opencode-config-template/issues/357)) ([29c253d](https://github.com/darellchua2/opencode-config-template/commit/29c253d8a6e6fc9791cd798b316cba4b8f72ad29))
* sync stale count claims to ground truth (105-allow, 45-lean, 145 skills, 33 agents) ([8ebbb4f](https://github.com/darellchua2/opencode-config-template/commit/8ebbb4f505e73697c0cdf8837726ced8e17bdb15))

## [5.9.0](https://github.com/darellchua2/opencode-config-template/compare/v5.8.0...v5.9.0) (2026-08-28)

### Features

* **skills:** vendor 8 official GSAP animation skills from greensock/gsap-skills ([a965e47](https://github.com/darellchua2/opencode-config-template/commit/a965e47ca83c64ae69d78f445036727d190a37b8))

## [5.8.0](https://github.com/darellchua2/opencode-config-template/compare/v5.7.1...v5.8.0) (2026-08-27)

### Features

* **deploy:** add zai-custom provider mirroring zai-coding-plan ([59177de](https://github.com/darellchua2/opencode-config-template/commit/59177de94d06ac0ed20fe5b8e2a6ae84204d762d))

## [5.7.1](https://github.com/darellchua2/opencode-config-template/compare/v5.7.0...v5.7.1) (2026-08-27)

### Bug Fixes

* **agents:** unblock linting/docx/tdd/testing bash, align language-reviewer gate ([#347](https://github.com/darellchua2/opencode-config-template/issues/347)) ([#348](https://github.com/darellchua2/opencode-config-template/issues/348)) ([57303c8](https://github.com/darellchua2/opencode-config-template/commit/57303c80b3959cd659ddeb52c2096345269c8ca7)), closes [#345](https://github.com/darellchua2/opencode-config-template/issues/345)

## [5.7.0](https://github.com/darellchua2/opencode-config-template/compare/v5.6.0...v5.7.0) (2026-08-27)

### Features

* **command:** add /run-worktree-pipeline with worktree-pipeline-skill ([#354](https://github.com/darellchua2/opencode-config-template/issues/354)) ([5607c2a](https://github.com/darellchua2/opencode-config-template/commit/5607c2a305924c2d1ad2c60abedb7bcf0e1495e2)), closes [#351](https://github.com/darellchua2/opencode-config-template/issues/351)

## [5.6.0](https://github.com/darellchua2/opencode-config-template/compare/v5.5.0...v5.6.0) (2026-08-27)

### Features

* **agents:** delegate pre-PR docstring sweep to documentation-subagent ([#353](https://github.com/darellchua2/opencode-config-template/issues/353)) ([bb1650e](https://github.com/darellchua2/opencode-config-template/commit/bb1650ecbdd24ec070929ec066ec2a5900e5e317)), closes [#350](https://github.com/darellchua2/opencode-config-template/issues/350)

## [5.5.0](https://github.com/darellchua2/opencode-config-template/compare/v5.4.1...v5.5.0) (2026-08-27)

### Features

* **models:** switch vision and docs tiers to native zai-coding-plan/glm-5.3-flash ([#352](https://github.com/darellchua2/opencode-config-template/issues/352)) ([b07bba8](https://github.com/darellchua2/opencode-config-template/commit/b07bba89368a0bb886f9b7938ed1f87166559a34)), closes [#349](https://github.com/darellchua2/opencode-config-template/issues/349)

## [5.4.1](https://github.com/darellchua2/opencode-config-template/compare/v5.4.0...v5.4.1) (2026-08-27)

### Bug Fixes

* **docs:** remove stale plans ([fd4e2b6](https://github.com/darellchua2/opencode-config-template/commit/fd4e2b61506912f4f7881cccfc5f106067784e01))

## [5.4.0](https://github.com/darellchua2/opencode-config-template/compare/v5.3.0...v5.4.0) (2026-08-26)

### Features

* **agents:** split reviewer charters, unblock permission-blocked skills ([#344](https://github.com/darellchua2/opencode-config-template/issues/344)) ([3db6383](https://github.com/darellchua2/opencode-config-template/commit/3db638322396f36b342edcccab282a6421cd8ab9))

### Bug Fixes

* **test:** bump reviewer skill-count assertions ([#344](https://github.com/darellchua2/opencode-config-template/issues/344)) ([ff47865](https://github.com/darellchua2/opencode-config-template/commit/ff478658c26b18de2ab9dc0d930929cb7a0a0420))

### Documentation

* **agents:** sync codegraph table, human-readable replies rule ([#344](https://github.com/darellchua2/opencode-config-template/issues/344)) ([a31febb](https://github.com/darellchua2/opencode-config-template/commit/a31febba2dd6b17444b54813eaae3292a944a36a))

## [5.3.0](https://github.com/darellchua2/opencode-config-template/compare/v5.2.0...v5.3.0) (2026-08-26)

### Features

* **models:** switch fast tier to glm-5.3-flash ([0acc81a](https://github.com/darellchua2/opencode-config-template/commit/0acc81a89200864f95baf04f45c61b80ae263057)), closes [#343](https://github.com/darellchua2/opencode-config-template/issues/343)

## [5.2.0](https://github.com/darellchua2/opencode-config-template/compare/v5.1.0...v5.2.0) (2026-08-21)

### Features

* **local-llm:** replace LM Studio with llama.cpp/vLLM backends ([eea2a76](https://github.com/darellchua2/opencode-config-template/commit/eea2a76bb7a1eddfa1e4739e5cb0362ec4fcaed0))

### Bug Fixes

* **plugins:** add mcp-resource-guard against MCP resource tool loops ([ad2bdf9](https://github.com/darellchua2/opencode-config-template/commit/ad2bdf9dae25fe4995f38d672d3007e0c4b0a9cb)), closes [anomalyco/opencode#23045](https://github.com/anomalyco/opencode/issues/23045)

## [5.1.0](https://github.com/darellchua2/opencode-config-template/compare/v5.0.0...v5.1.0) (2026-08-19)

### Features

* **agents:** wire skills into subagent allowlists ([cca4bab](https://github.com/darellchua2/opencode-config-template/commit/cca4bab998b8cd7025c0286e7611bf848a5c4eeb))
* **skills:** add pstack router patterns to plan skills ([21bd40b](https://github.com/darellchua2/opencode-config-template/commit/21bd40bd11017b1c4d7e6fa3eb3e2d0637ea5322))
* **skills:** vendor ponytail satellite skills (audit, review, debt) ([24a97ea](https://github.com/darellchua2/opencode-config-template/commit/24a97eabed278b095562648dcd7df4290ffd483a))
* **skills:** vendor pstack core 3 (unslop, technical-writing, blast-radius) ([8296738](https://github.com/darellchua2/opencode-config-template/commit/8296738207d9dae8b1b9e47b77ac63061b482d64))

### Bug Fixes

* **docs:** address review findings — category casing, preset/profile counts, lean orphan ([ba9b171](https://github.com/darellchua2/opencode-config-template/commit/ba9b1715632d82b38a6ae3d2c0b4f200c189f85f))

### Code Refactoring

* **skills:** trim high-multiplier skill descriptions ([2062621](https://github.com/darellchua2/opencode-config-template/commit/20626213ecbec673e0a694c0a18490c2165f6ff7))

### Documentation

* fix stale counts and linter-skill reference after GIT-338 ([43e9f68](https://github.com/darellchua2/opencode-config-template/commit/43e9f68a24ba2ef522de32e4a67f6ed79bb0cdfe))
* **plan:** add PLAN-GIT-341.md for GIT-341 ([0862912](https://github.com/darellchua2/opencode-config-template/commit/0862912bb0e3048e5645185850ee80e2d7d1f4c5))

## [5.0.0](https://github.com/darellchua2/opencode-config-template/compare/v4.29.0...v5.0.0) (2026-08-16)

### ⚠ BREAKING CHANGES

* **skills:** npx add python-ruff-linter-skill|javascript-eslint-linter-skill|java-linter-skill|csharp-linter-skill names removed; use language-linting-skill. Skills 130 -> 127. Plan: PLANS/PLAN-GIT-338.md Phase 2. Gate: build-registry --check + bats 304/304 green.
* **agents:** npx add <lang>-reviewer-subagent names are removed; use
language-reviewer-subagent. Presets review/backend swap to the merged agent.

Plan: PLANS/PLAN-GIT-338.md. Gate: registry --check OK (agents=32), bats
304/304, bash -n setup.sh OK. Trace: per-step Done lines in PLAN.

### Features

* **agents:** merge language reviewers into language-reviewer-subagent ([9dc23ed](https://github.com/darellchua2/opencode-config-template/commit/9dc23edb3efbb74adc5b2420f7a4f695cabcb95a))
* **skills:** merge per-language linter skills into language-linting-skill ([63c3bf2](https://github.com/darellchua2/opencode-config-template/commit/63c3bf21f46f56a0450d269bd21d9d8b9a896566))

### Bug Fixes

* **deploy:** fold YAML block-scalar descriptions in registry parser ([c52d8c4](https://github.com/darellchua2/opencode-config-template/commit/c52d8c4249081f0aaabf7fc9b51b6c7d29cea8d9)), closes [#339](https://github.com/darellchua2/opencode-config-template/issues/339)

### Code Refactoring

* **agents:** extract duplicated agent knowledge into skills ([0227077](https://github.com/darellchua2/opencode-config-template/commit/0227077f4efa82b1249daa50c410302a13be403d))

### Documentation

* **plan:** add PLAN-GIT-338.md for GIT-338 ([5c989a8](https://github.com/darellchua2/opencode-config-template/commit/5c989a8c898777c1003a168b9456bc72219b29a0))
* **plan:** trace Phase 4 completion (PR [#339](https://github.com/darellchua2/opencode-config-template/issues/339)) ([06ce413](https://github.com/darellchua2/opencode-config-template/commit/06ce413e20f2dcbf8fc8540523d4f5793de69802))
* sync counts after reviewer/linter consolidation ([705c759](https://github.com/darellchua2/opencode-config-template/commit/705c7592691d4f1081b744cbc73baa3ba5bba210))

## [4.29.0](https://github.com/darellchua2/opencode-config-template/compare/v4.28.0...v4.29.0) (2026-08-16)

### Features

* **mcp:** add zai-web-search server enabled by default (GIT-336) ([730c933](https://github.com/darellchua2/opencode-config-template/commit/730c933a3f3583020df45d0edc9cb3420fa0dfe6)), closes [#336](https://github.com/darellchua2/opencode-config-template/issues/336)

### Documentation

* **plan): tick GIT-336 steps, record measured 344-token result; style(mcp:** normalize zai block indent ([c298143](https://github.com/darellchua2/opencode-config-template/commit/c298143595bd273af1f97e4bfd825da2df787e54))
* **plan:** add PLAN-GIT-336.md for GIT-336 ([2be71cf](https://github.com/darellchua2/opencode-config-template/commit/2be71cf7f5df1c1746d7218aa1d87e0d324d40a7))
* **plan:** revise PLAN-GIT-336 per strong review (v2) ([0fb3b58](https://github.com/darellchua2/opencode-config-template/commit/0fb3b58c2f67790a21c98a4232460a712cc5f5d0))

## [4.28.0](https://github.com/darellchua2/opencode-config-template/compare/v4.27.0...v4.28.0) (2026-08-16)

### Features

* **plugins:** add opencode-scheduler@1.3.0 for cron-style scheduled jobs ([ef187ab](https://github.com/darellchua2/opencode-config-template/commit/ef187abfcfacba7c0c4570dc075c1abfce2b2ac1))

## [4.27.0](https://github.com/darellchua2/opencode-config-template/compare/v4.26.3...v4.27.0) (2026-08-15)

### Features

* **agents:** scope subagent-only skills via frontmatter allows ([56ad174](https://github.com/darellchua2/opencode-config-template/commit/56ad174146e34cc131bb927f4974b0c9b65266c8))
* **config:** default atlassian and dead zai MCP servers to opt-in ([719b3d3](https://github.com/darellchua2/opencode-config-template/commit/719b3d3bef1956e4bf9b655a5b50c4b73ad1c441))
* **deploy:** add --skill-profile lean|full option ([781ce8e](https://github.com/darellchua2/opencode-config-template/commit/781ce8e88f734626c9d02e4aac065c15a077dcbe))
* **skills:** add opencode-repo-setup-skill as per-project MCP frontend ([33d4f4c](https://github.com/darellchua2/opencode-config-template/commit/33d4f4c937d222ba86505bfb81eef6f8db768f5b))

### Bug Fixes

* **skills:** add MCP availability guards to JIRA-dependent skills and subagents ([44d605b](https://github.com/darellchua2/opencode-config-template/commit/44d605baadb7c1071f2175c85e0beb5d91099c61))
* **skills:** correct repo-setup config path and add jq merge procedure ([ed4cf2d](https://github.com/darellchua2/opencode-config-template/commit/ed4cf2d2e5e0befef730640baccb07b87c69c1b7))
* **skills:** reroute vision MCP references to native vision tier ([03cd313](https://github.com/darellchua2/opencode-config-template/commit/03cd313dd7bbf7f77d3fe1bb03567974ce6872cb)), closes [#294](https://github.com/darellchua2/opencode-config-template/issues/294)
* **tests:** align docling routing grep with pointer-style deploy AGENTS.md ([3baa2af](https://github.com/darellchua2/opencode-config-template/commit/3baa2af9a38652aa500bcd32774879f94012362e))
* **tests:** commit skill_profiles count updates for lean-30 (missed in 33d4f4c) ([7ef3eef](https://github.com/darellchua2/opencode-config-template/commit/7ef3eef6ad036b2f1c005466d6a569e2f7595ac8))
* **tests:** derive Configuration category count from registry.json ([ab6da1a](https://github.com/darellchua2/opencode-config-template/commit/ab6da1a5b906341af7568e63e3fae342a799bea2))

### Code Refactoring

* **agents:** slim subagent descriptions ([ed46ec3](https://github.com/darellchua2/opencode-config-template/commit/ed46ec3607632d3d17a50cbae9622234d0a14535))
* **mcp:** make autodesk servers pack-only opt-in ([8ed73e3](https://github.com/darellchua2/opencode-config-template/commit/8ed73e317fb6ab074d30c8a4f2f17ab54bfd720a))
* **mcp:** remove mermaid and web-search-prime servers, go inline-diagram ([161c21d](https://github.com/darellchua2/opencode-config-template/commit/161c21d4ed50f033acd32f30a66f157aca712411))
* **mcp:** remove redundant zai-vision-mcp-server and zai-zread entries ([eb908f1](https://github.com/darellchua2/opencode-config-template/commit/eb908f133315e4857ba0718096be901b23336d67))
* **rules:** move CodeGraph/LSP routing to project-level rule blocks ([cdd0ceb](https://github.com/darellchua2/opencode-config-template/commit/cdd0cebcb4f6e57e3d66f00249b89786f2cc9b55))
* **skills:** enforce lean frontmatter contract across catalog ([fd05c73](https://github.com/darellchua2/opencode-config-template/commit/fd05c7347c1bb29449494055681b36806268027c))
* **skills:** merge codegraph-setup-skill into repo-setup Step 4 ([a72196a](https://github.com/darellchua2/opencode-config-template/commit/a72196a96759fa2d798dca6208f724adacd50de9))

### Documentation

* **agents:** condense agent and skill frontmatter descriptions ([c804a57](https://github.com/darellchua2/opencode-config-template/commit/c804a572bd36c46221397326c88e7921955fc1c9))
* **plan:** add PLAN-GIT-333 for skill-profile context reduction ([3aa999f](https://github.com/darellchua2/opencode-config-template/commit/3aa999fa74454e15b87ceccaf64fd3a17c7fe56b))
* **plan:** extend PLAN-GIT-333 phases 6-8 (MCP opt-in + repo-setup skill) ([7d5b5ac](https://github.com/darellchua2/opencode-config-template/commit/7d5b5ac805b2d1c93832c67ecb4cbda39e7b4def))
* **plan:** trace PLAN-GIT-333 completion (PR [#334](https://github.com/darellchua2/opencode-config-template/issues/334)) ([8a82e4e](https://github.com/darellchua2/opencode-config-template/commit/8a82e4e1f88b8af75091fe2285e355dbfc16835b))
* **plan:** trace PLAN-GIT-333 phases 6-8 (PR [#334](https://github.com/darellchua2/opencode-config-template/issues/334) extended) ([60234b6](https://github.com/darellchua2/opencode-config-template/commit/60234b65c22edf95b1c4548e5e4de2b1c2197ae1)), closes [#333](https://github.com/darellchua2/opencode-config-template/issues/333)
* **setup:** add combination-install examples to setup help ([8414391](https://github.com/darellchua2/opencode-config-template/commit/8414391bf3da7f9051e7bdf242f882eefa953240))
* sync skill-profile docs and LEARNINGS ([5fa6f15](https://github.com/darellchua2/opencode-config-template/commit/5fa6f15975caa0aca02690f018b4437aaa051dd9))

## [4.26.3](https://github.com/darellchua2/opencode-config-template/compare/v4.26.2...v4.26.3) (2026-08-12)

### Bug Fixes

* **pptx-template-modifier:** repair-worthy defects in designer_promoter output ([#332](https://github.com/darellchua2/opencode-config-template/issues/332)) ([c0da44e](https://github.com/darellchua2/opencode-config-template/commit/c0da44e12040b6a36679b44e2e8e1f3804c6cf6e)), closes [#331](https://github.com/darellchua2/opencode-config-template/issues/331)

## [4.26.2](https://github.com/darellchua2/opencode-config-template/compare/v4.26.1...v4.26.2) (2026-08-10)

### Bug Fixes

* **deploy:** use $HOME instead of hard-coded silentx path ([2a99a06](https://github.com/darellchua2/opencode-config-template/commit/2a99a069cb9974e8a683779e851ab1ff164d8ffd))

## [4.26.1](https://github.com/darellchua2/opencode-config-template/compare/v4.26.0...v4.26.1) (2026-08-09)

### Bug Fixes

* **config:** remove moonshot provider (incorrect setup) ([088b260](https://github.com/darellchua2/opencode-config-template/commit/088b260f25dcf3f075e37b9e8a3e6f3ab63bf7f4))

## [4.26.0](https://github.com/darellchua2/opencode-config-template/compare/v4.25.3...v4.26.0) (2026-08-09)

### Features

* **config:** add moonshot provider with kimi-k3 vision support ([cb79f31](https://github.com/darellchua2/opencode-config-template/commit/cb79f3122ff4673ba41f113223cf4710a9d576b7))

## [4.25.3](https://github.com/darellchua2/opencode-config-template/compare/v4.25.2...v4.25.3) (2026-08-09)

### Bug Fixes

* **config:** remove kimi-k3-vision from zai-coding-plan provider ([b135781](https://github.com/darellchua2/opencode-config-template/commit/b13578119f0f4c67c57e0ddcbc7e92f571e09cfd))

## [4.25.2](https://github.com/darellchua2/opencode-config-template/compare/v4.25.1...v4.25.2) (2026-08-09)

### Bug Fixes

* **config:** rename kimi-k3 to kimi-k3-vision for variant differentiation ([aa8e7c5](https://github.com/darellchua2/opencode-config-template/commit/aa8e7c55dde93d049d90b12c1c82ef80a309839f))

## [4.25.1](https://github.com/darellchua2/opencode-config-template/compare/v4.25.0...v4.25.1) (2026-08-09)

### Bug Fixes

* **config:** add modalities for vision support on zai-coding-plan models ([f497e82](https://github.com/darellchua2/opencode-config-template/commit/f497e822d0d955dce6dcdd10cf7a162334cdda27))

## [4.25.0](https://github.com/darellchua2/opencode-config-template/compare/v4.24.0...v4.25.0) (2026-08-08)

### Features

* **deploy:** make primary model injection opt-in via --inject-primary ([5e69bb4](https://github.com/darellchua2/opencode-config-template/commit/5e69bb455fd5e485c3ec7772ae51bc99554c842a))

## [4.24.0](https://github.com/darellchua2/opencode-config-template/compare/v4.23.0...v4.24.0) (2026-08-07)

### Features

* **mcp:** add privacy-hardened chrome-devtools MCP for frontend agents ([#329](https://github.com/darellchua2/opencode-config-template/issues/329)) ([#330](https://github.com/darellchua2/opencode-config-template/issues/330)) ([67c4d49](https://github.com/darellchua2/opencode-config-template/commit/67c4d493efe2fd8e08b17fc30d010b0d6e3bfee0))

## [4.23.0](https://github.com/darellchua2/opencode-config-template/compare/v4.22.0...v4.23.0) (2026-08-06)

### Features

* **vision:** route glm-5v-turbo through coding-plan endpoint with API fallback ([#326](https://github.com/darellchua2/opencode-config-template/issues/326)) ([226f740](https://github.com/darellchua2/opencode-config-template/commit/226f7409a259eaaf55fff7670db8683f9f68d1b4))

## [4.22.0](https://github.com/darellchua2/opencode-config-template/compare/v4.21.0...v4.22.0) (2026-08-06)

### Features

* **agents:** add epistemic-honesty & verification baseline with web access ([c672185](https://github.com/darellchua2/opencode-config-template/commit/c67218560030dc7769424239afaf98e96519faef))

### Bug Fixes

* **agents:** correct false factual claims and unverified version pins ([4da8d4f](https://github.com/darellchua2/opencode-config-template/commit/4da8d4fd13430d194c9e4c132816afe269b99b93))
* **agents:** remove leaked secret-mask token from uiux-reviewer ([3cbf825](https://github.com/darellchua2/opencode-config-template/commit/3cbf8253ec3bbee297b16509db874e05825926e0))
* **agents:** repair duplicate frontmatter task key in startup-ceo ([9ca357f](https://github.com/darellchua2/opencode-config-template/commit/9ca357f37e9ce292bfb1242b3a9c8aaf4e1e5b51))
* **agents:** soften confabulation-pressure in error-resolver and explorer ([65702a4](https://github.com/darellchua2/opencode-config-template/commit/65702a4c3c94c3a73906043f9d2d68505087554d))

## [4.21.0](https://github.com/darellchua2/opencode-config-template/compare/v4.20.0...v4.21.0) (2026-08-06)

### Features

* **agents:** grant web access + lookup guidance to reviewers ([01ab540](https://github.com/darellchua2/opencode-config-template/commit/01ab5407719846ba0a931f5148912cd7fb9a7211))

### Documentation

* **plan:** add PLAN-GIT-323.md for [#323](https://github.com/darellchua2/opencode-config-template/issues/323) ([d510249](https://github.com/darellchua2/opencode-config-template/commit/d510249377ce9c9a1c798be9036be1eb38b2cb56))
* **plan:** revise PLAN-GIT-323 to minimal web-lookup scope ([ff1cd2e](https://github.com/darellchua2/opencode-config-template/commit/ff1cd2e9d1a0093533b836122094afd2cd6b02c2))

## [4.20.0](https://github.com/darellchua2/opencode-config-template/compare/v4.19.2...v4.20.0) (2026-08-06)

### Features

* **skills:** add zai-image-generation-skill (Z.AI GLM-Image text→PNG) ([73ab708](https://github.com/darellchua2/opencode-config-template/commit/73ab7087fd4312df0eb79fc6f6e17dcd819b9f86))

### Bug Fixes

* **plugins:** pin exact versions to resolve DCP peer conflict ([164af01](https://github.com/darellchua2/opencode-config-template/commit/164af01ba0a6c6652b5dd2fa6de8e4e5460f4ac9))

## [4.19.2](https://github.com/darellchua2/opencode-config-template/compare/v4.19.1...v4.19.2) (2026-08-06)

### Bug Fixes

* **mcp:** correct env var syntax in zai-vision-mcp-server ([bdbcdbd](https://github.com/darellchua2/opencode-config-template/commit/bdbcdbd9514cb81975875eccbacfb2b4d5f96e9c))

## [4.19.1](https://github.com/darellchua2/opencode-config-template/compare/v4.19.0...v4.19.1) (2026-08-05)

### Bug Fixes

* **learnings:** capture redocly + tsoa factual corrections from [#319](https://github.com/darellchua2/opencode-config-template/issues/319) review ([c195011](https://github.com/darellchua2/opencode-config-template/commit/c195011b7ca5fdc19662319c7e2ba9c709aa7cbf))

## [4.19.0](https://github.com/darellchua2/opencode-config-template/compare/v4.18.0...v4.19.0) (2026-08-05)

### Features

* **openapi:** route authoring signals to api-design-skill with Authoring Quality Gate ([5dc455e](https://github.com/darellchua2/opencode-config-template/commit/5dc455e942520f04979b4d3539b65d479adea87c)), closes [#319](https://github.com/darellchua2/opencode-config-template/issues/319)

### Bug Fixes

* **api-design:** correct Authoring Quality Gate per code review ([8fbe070](https://github.com/darellchua2/opencode-config-template/commit/8fbe0703c8de41d44fe9f97e4c56f7c581c78174)), closes [#319](https://github.com/darellchua2/opencode-config-template/issues/319)

### Documentation

* **plan:** add PLAN-GIT-319 for openapi authoring enforcement redesign ([8a9da55](https://github.com/darellchua2/opencode-config-template/commit/8a9da55acb99b706d146b960d99237ccbe25d690)), closes [#320](https://github.com/darellchua2/opencode-config-template/issues/320) [#319](https://github.com/darellchua2/opencode-config-template/issues/319)
* **plan:** trace PLAN-GIT-319 phases + close acceptance criteria ([0e18a71](https://github.com/darellchua2/opencode-config-template/commit/0e18a715d27f0f6cb2526dd6459bed65974f1dd3)), closes [#320](https://github.com/darellchua2/opencode-config-template/issues/320)

## [4.18.0](https://github.com/darellchua2/opencode-config-template/compare/v4.17.0...v4.18.0) (2026-08-05)

### Features

* **tooling:** recommend ripgrep as optional dependency ([#317](https://github.com/darellchua2/opencode-config-template/issues/317)) ([#318](https://github.com/darellchua2/opencode-config-template/issues/318)) ([c3ac0dc](https://github.com/darellchua2/opencode-config-template/commit/c3ac0dc15751496aafd22f377084992b148c3b3b))

## [4.17.0](https://github.com/darellchua2/opencode-config-template/compare/v4.16.0...v4.17.0) (2026-08-05)

### Features

* **security:** integrate vibeguard secret masking for .env safety ([#315](https://github.com/darellchua2/opencode-config-template/issues/315)) ([#316](https://github.com/darellchua2/opencode-config-template/issues/316)) ([cd05707](https://github.com/darellchua2/opencode-config-template/commit/cd05707bd5b855234571da4fb1504d69b2fb605f)), closes [inkdust2021/opencode-vibeguard#6](https://github.com/inkdust2021/opencode-vibeguard/issues/6)

## [4.16.0](https://github.com/darellchua2/opencode-config-template/compare/v4.15.0...v4.16.0) (2026-08-04)

### Features

* improve skills & subagents from cross-repo LEARNINGS (PLAN-GIT-312) ([#313](https://github.com/darellchua2/opencode-config-template/issues/313)) ([e494d5b](https://github.com/darellchua2/opencode-config-template/commit/e494d5b47b4e51b414238c97159abaa78fc2ff0a))

### Bug Fixes

* **ci:** rebuild registry after review fixes (PLAN-GIT-312) ([#314](https://github.com/darellchua2/opencode-config-template/issues/314)) ([c81b1d4](https://github.com/darellchua2/opencode-config-template/commit/c81b1d4cef9bfe768a84c9f4e0c7a9721a54bf8f))

## [4.15.0](https://github.com/darellchua2/opencode-config-template/compare/v4.14.1...v4.15.0) (2026-08-04)

### Features

* **docling:** office document extraction routing + docling CLI-on-demand ([#308](https://github.com/darellchua2/opencode-config-template/issues/308)) ([#310](https://github.com/darellchua2/opencode-config-template/issues/310)) ([1be58ce](https://github.com/darellchua2/opencode-config-template/commit/1be58ced6e564510ec5c7c31ca9be0dd18827d6f))

### Bug Fixes

* **ci:** update preset count 10→9 (google/microsoft removed in [#309](https://github.com/darellchua2/opencode-config-template/issues/309)) ([#311](https://github.com/darellchua2/opencode-config-template/issues/311)) ([6fba3aa](https://github.com/darellchua2/opencode-config-template/commit/6fba3aaf1f2cab84140536be3e32f3dd76ef0433))
* **docs:** replace stale microsoft/google pack examples with valid packs ([b7a719b](https://github.com/darellchua2/opencode-config-template/commit/b7a719ba881a353305a1f9879a9ccffa9cd88dac))

### Code Refactoring

* **mcp:** remove Google Cloud + Microsoft 365 MCP integrations ([65d156b](https://github.com/darellchua2/opencode-config-template/commit/65d156b15bb89d2f4bb305431ed2999c21fa15f8))

### Documentation

* **plan:** add PLAN-GIT-307.md for chore/remove-google-microsoft-mcp ([24ef880](https://github.com/darellchua2/opencode-config-template/commit/24ef88052a3dcf1301b55d0cd2e6bb434a149330))
* **plan:** add PLAN-GIT-308 for [#308](https://github.com/darellchua2/opencode-config-template/issues/308) ([496ca73](https://github.com/darellchua2/opencode-config-template/commit/496ca7394b886c7804320caf9fa4344af666cafa))
* **plan:** tick final 3 checkboxes — v4.14.1 release verified ([e163aef](https://github.com/darellchua2/opencode-config-template/commit/e163aeff71ac78f815ca71ddd4da9cf5bdeb77ee))

## [4.14.1](https://github.com/darellchua2/opencode-config-template/compare/v4.14.0...v4.14.1) (2026-08-04)

### Bug Fixes

* **release:** pin semantic-release plugins + npm ci to restore release notes ([#306](https://github.com/darellchua2/opencode-config-template/issues/306)) ([666aef4](https://github.com/darellchua2/opencode-config-template/commit/666aef4417c4f09408e8f9bfa6166f2be34a8a90))

## [4.14.0](https://github.com/darellchua2/opencode-config-template/compare/v4.13.0...v4.14.0) (2026-08-04)

## [4.13.0](https://github.com/darellchua2/opencode-config-template/compare/v4.12.0...v4.13.0) (2026-08-04)

## [4.12.0](https://github.com/darellchua2/opencode-config-template/compare/v4.11.0...v4.12.0) (2026-08-04)

## [4.11.0](https://github.com/darellchua2/opencode-config-template/compare/v4.10.1...v4.11.0) (2026-08-04)

## [4.10.1](https://github.com/darellchua2/opencode-config-template/compare/v4.10.0...v4.10.1) (2026-08-04)

## [4.10.0](https://github.com/darellchua2/opencode-config-template/compare/v4.9.0...v4.10.0) (2026-08-04)

## [4.9.0](https://github.com/darellchua2/opencode-config-template/compare/v4.8.0...v4.9.0) (2026-08-04)

## [4.8.0](https://github.com/darellchua2/opencode-config-template/compare/v4.7.3...v4.8.0) (2026-08-04)

## [4.7.3](https://github.com/darellchua2/opencode-config-template/compare/v4.7.2...v4.7.3) (2026-08-04)

## [4.7.2](https://github.com/darellchua2/opencode-config-template/compare/v4.7.1...v4.7.2) (2026-08-04)

## [4.7.1](https://github.com/darellchua2/opencode-config-template/compare/v4.7.0...v4.7.1) (2026-08-03)

## [4.7.0](https://github.com/darellchua2/opencode-config-template/compare/v4.6.0...v4.7.0) (2026-08-02)

## [4.6.0](https://github.com/darellchua2/opencode-config-template/compare/v4.5.4...v4.6.0) (2026-08-02)

## [4.5.4](https://github.com/darellchua2/opencode-config-template/compare/v4.5.3...v4.5.4) (2026-08-02)

## [4.5.3](https://github.com/darellchua2/opencode-config-template/compare/v4.5.2...v4.5.3) (2026-07-30)

## [4.5.2](https://github.com/darellchua2/opencode-config-template/compare/v4.5.1...v4.5.2) (2026-07-27)

## [4.5.1](https://github.com/darellchua2/opencode-config-template/compare/v4.5.0...v4.5.1) (2026-07-26)

## [4.5.0](https://github.com/darellchua2/opencode-config-template/compare/v4.4.0...v4.5.0) (2026-07-26)

## [4.4.0](https://github.com/darellchua2/opencode-config-template/compare/v4.3.0...v4.4.0) (2026-07-26)

## [4.3.0](https://github.com/darellchua2/opencode-config-template/compare/v4.2.0...v4.3.0) (2026-07-26)

## [4.2.0](https://github.com/darellchua2/opencode-config-template/compare/v4.1.0...v4.2.0) (2026-07-26)

## [4.1.0](https://github.com/darellchua2/opencode-config-template/compare/v4.0.1...v4.1.0) (2026-07-26)

## [4.0.1](https://github.com/darellchua2/opencode-config-template/compare/v4.0.0...v4.0.1) (2026-07-23)

## [4.0.0](https://github.com/darellchua2/opencode-config-template/compare/v3.1.0...v4.0.0) (2026-07-21)

## [3.1.0](https://github.com/darellchua2/opencode-config-template/compare/v3.0.0...v3.1.0) (2026-07-20)

## [3.0.0](https://github.com/darellchua2/opencode-config-template/compare/v2.3.0...v3.0.0) (2026-07-20)

## [2.3.0](https://github.com/darellchua2/opencode-config-template/compare/v2.2.1...v2.3.0) (2026-07-20)

## [2.2.1](https://github.com/darellchua2/opencode-config-template/compare/v2.2.0...v2.2.1) (2026-07-20)

## [2.2.0](https://github.com/darellchua2/opencode-config-template/compare/v2.1.0...v2.2.0) (2026-07-19)

## [2.1.0](https://github.com/darellchua2/opencode-config-template/compare/v2.0.0...v2.1.0) (2026-07-19)

# [2.0.0](https://github.com/darellchua2/opencode-config-template/compare/v1.77.1...v2.0.0) (2026-07-19)


* feat(models)!: tier-based provider-agnostic model resolution (v2.0) [BT-74] ([f8b4de9](https://github.com/darellchua2/opencode-config-template/commit/f8b4de9940f3a32c065977c6f40faf4cc4ed0e1a))


### Bug Fixes

* **bt-74:** post-review fixes — --json writes, config.json unstale ([b20a2d1](https://github.com/darellchua2/opencode-config-template/commit/b20a2d13995fb5cc5541a3fc74348cfd7bec1dd4))
* **ci:** repoint release workflow lint at canonical opencode.json ([#250](https://github.com/darellchua2/opencode-config-template/issues/250)) ([b1f66bd](https://github.com/darellchua2/opencode-config-template/commit/b1f66bddd090d51d7f43e5d483346eb916e24d03)), closes [#231](https://github.com/darellchua2/opencode-config-template/issues/231) [#248](https://github.com/darellchua2/opencode-config-template/issues/248) [#249](https://github.com/darellchua2/opencode-config-template/issues/249) [#231](https://github.com/darellchua2/opencode-config-template/issues/231)
* **tests:** correct agent-tiers.json structure lookup in assertions [BT-74] ([1dbe59d](https://github.com/darellchua2/opencode-config-template/commit/1dbe59d3389bdddbc0efe3213cee00e485960668))
* **tests:** update autoresearch model assertions for v2.0 tier-based resolution [BT-74] ([ebf3be3](https://github.com/darellchua2/opencode-config-template/commit/ebf3be35dbbd201829991fcaee801c6526cb8070))
* **tui:** exit after interactive flows + show resolution progress [BT-74] ([4d938d2](https://github.com/darellchua2/opencode-config-template/commit/4d938d2d75ea4495b7bf5fd1432a73f8c45304b2))
* update SKILL ([952dc2d](https://github.com/darellchua2/opencode-config-template/commit/952dc2dac72b61ac83c5b3946ea612a4ffb535a8))


### Features

* **models:** per-category provider/model mixing (--mix) [BT-74] ([97eaea3](https://github.com/darellchua2/opencode-config-template/commit/97eaea3ca2a7e78039fcac76509ccb69310c01e1))


### BREAKING CHANGES

* agent .md files no longer carry a hardcoded model; redeploy via
./deploy/setup.sh (or setup.ps1) to resolve models from tiers. Existing v1.x
installs auto-migrate on first run. See MIGRATION.md.

## [1.77.1](https://github.com/darellchua2/opencode-config-template/compare/v1.77.0...v1.77.1) (2026-07-19)


### Bug Fixes

* **deploy:** harden setup.sh/ps1 against paths, errors, silent failures ([f4f9aa4](https://github.com/darellchua2/opencode-config-template/commit/f4f9aa452f154510015708972f5978de22f71845))

# [1.77.0](https://github.com/darellchua2/opencode-config-template/compare/v1.76.0...v1.77.0) (2026-07-19)


### Features

* **skills:** add threejs-nextjs-skill + repair frontmatter spec violations ([#245](https://github.com/darellchua2/opencode-config-template/issues/245)) ([#246](https://github.com/darellchua2/opencode-config-template/issues/246)) ([1e1fef7](https://github.com/darellchua2/opencode-config-template/commit/1e1fef7d5afef0595a0367115d9db70606383ed6))

# [1.76.0](https://github.com/darellchua2/opencode-config-template/compare/v1.75.2...v1.76.0) (2026-07-18)


### Features

* **autoresearch:** add core skill + 3 domain skills + 3 subagents ([#239](https://github.com/darellchua2/opencode-config-template/issues/239)) ([9785820](https://github.com/darellchua2/opencode-config-template/commit/9785820349a915a524815c5d6456719cf944ea79))
* **autoresearch:** retrofit Tier 1 + Tier 2 skills with iteration protocol ([#239](https://github.com/darellchua2/opencode-config-template/issues/239)) ([300b73e](https://github.com/darellchua2/opencode-config-template/commit/300b73e0828426df0823e5e1bd59b114d717bbbc))
* **autoresearch:** retrofit Tier 3 skills with iteration protocol ([#239](https://github.com/darellchua2/opencode-config-template/issues/239)) ([732350b](https://github.com/darellchua2/opencode-config-template/commit/732350b6729fd8202bd140bbbbaaf636b3159ccf))

## [1.75.2](https://github.com/darellchua2/opencode-config-template/compare/v1.75.1...v1.75.2) (2026-07-18)


### Bug Fixes

* update pm2 ([031c3fb](https://github.com/darellchua2/opencode-config-template/commit/031c3fbafdfeb69b4fe07f95fe56805844ba8b3b))

## [1.75.1](https://github.com/darellchua2/opencode-config-template/compare/v1.75.0...v1.75.1) (2026-07-18)


### Bug Fixes

* **deploy:** correct unbalanced parens in setup.ps1 Deploy-Agents function ([#242](https://github.com/darellchua2/opencode-config-template/issues/242)) ([a8e5cd9](https://github.com/darellchua2/opencode-config-template/commit/a8e5cd925ddcfd69f841c5720f9f63eb97d5811c)), closes [#241](https://github.com/darellchua2/opencode-config-template/issues/241)

# [1.75.0](https://github.com/darellchua2/opencode-config-template/compare/v1.74.0...v1.75.0) (2026-07-18)


### Features

* **agents:** add uiux-reviewer-subagent + uiux-review-skill (13-axis design review) ([#237](https://github.com/darellchua2/opencode-config-template/issues/237)) ([83ef55c](https://github.com/darellchua2/opencode-config-template/commit/83ef55c6455649fdfbe2fb4c0fa698eb890d2cc6))

# [1.74.0](https://github.com/darellchua2/opencode-config-template/compare/v1.73.0...v1.74.0) (2026-07-18)


### Features

* **agents:** add java-reviewer-subagent for Java code review ([#236](https://github.com/darellchua2/opencode-config-template/issues/236)) ([78b74d4](https://github.com/darellchua2/opencode-config-template/commit/78b74d48ff2b53cc56b31641b45778d05a9757ff)), closes [#234](https://github.com/darellchua2/opencode-config-template/issues/234)

# [1.73.0](https://github.com/darellchua2/opencode-config-template/compare/v1.72.0...v1.73.0) (2026-06-26)


### Features

* **agents:** add BRD + technical-design document-ladder stage [BT-73] ([#230](https://github.com/darellchua2/opencode-config-template/issues/230)) ([d881883](https://github.com/darellchua2/opencode-config-template/commit/d881883c29bc93609d1b74778a322bde7295bb2a))

# [1.72.0](https://github.com/darellchua2/opencode-config-template/compare/v1.71.0...v1.72.0) (2026-06-26)


### Features

* **agents:** restructure document workflow into software-house ladder [BT-72] ([#229](https://github.com/darellchua2/opencode-config-template/issues/229)) ([9fe2702](https://github.com/darellchua2/opencode-config-template/commit/9fe27020c48b7680b0813731809f3d989e1b01af))

# [1.71.0](https://github.com/darellchua2/opencode-config-template/compare/v1.70.0...v1.71.0) (2026-06-24)


### Features

* **cad:** Port 11 CAD skills from text-to-cad, consolidate 3 specialists into 1 [BT-71] ([#228](https://github.com/darellchua2/opencode-config-template/issues/228)) ([f8a24f7](https://github.com/darellchua2/opencode-config-template/commit/f8a24f7bc3b507aa921ce75a82f0e9bffc98a427))

# [1.70.0](https://github.com/darellchua2/opencode-config-template/compare/v1.69.0...v1.70.0) (2026-06-24)


### Features

* **DA-1421:** add Playwright responsive audit skill + wireframer skill + responsive-audit subagent ([#226](https://github.com/darellchua2/opencode-config-template/issues/226)) ([8dcbc03](https://github.com/darellchua2/opencode-config-template/commit/8dcbc03b587fd9dcafce913baf90fd576418d665)), closes [#1](https://github.com/darellchua2/opencode-config-template/issues/1)

# [1.69.0](https://github.com/darellchua2/opencode-config-template/compare/v1.68.0...v1.69.0) (2026-06-21)


### Features

* **BT-70:** import grill-with-docs skill suite (4 skills) + prd-specialist wiring ([#225](https://github.com/darellchua2/opencode-config-template/issues/225)) ([b0bb5b1](https://github.com/darellchua2/opencode-config-template/commit/b0bb5b1459dea5105111bb2a2b3c6fb1f4c579d8))

# [1.68.0](https://github.com/darellchua2/opencode-config-template/compare/v1.67.0...v1.68.0) (2026-06-21)


### Features

* add prd-creation-skill, prd-specialist-subagent, and image-analyzer shared utility ([#224](https://github.com/darellchua2/opencode-config-template/issues/224)) ([813958d](https://github.com/darellchua2/opencode-config-template/commit/813958d00865edfafb65e68195869d9462281e3b)), closes [#223](https://github.com/darellchua2/opencode-config-template/issues/223) [#223](https://github.com/darellchua2/opencode-config-template/issues/223)

# [1.67.0](https://github.com/darellchua2/opencode-config-template/compare/v1.66.1...v1.67.0) (2026-06-21)


### Features

* add openapi-contract-adherence-skill for API contract evolution ([#221](https://github.com/darellchua2/opencode-config-template/issues/221)) ([#222](https://github.com/darellchua2/opencode-config-template/issues/222)) ([5dee29a](https://github.com/darellchua2/opencode-config-template/commit/5dee29a31bb825b891982245897aa281e5612e7d))

## [1.66.1](https://github.com/darellchua2/opencode-config-template/compare/v1.66.0...v1.66.1) (2026-06-19)


### Bug Fixes

* code review fixes — step numbering, DRY detection, failure handling ([#220](https://github.com/darellchua2/opencode-config-template/issues/220)) ([d8ff686](https://github.com/darellchua2/opencode-config-template/commit/d8ff68692ed3bb9bf0c3850124b4307488a319d7))

# [1.66.0](https://github.com/darellchua2/opencode-config-template/compare/v1.65.1...v1.66.0) (2026-06-19)


### Features

* add git-branch-workflow-setup-skill for dev→uat→main orchestration ([#219](https://github.com/darellchua2/opencode-config-template/issues/219)) ([25c1260](https://github.com/darellchua2/opencode-config-template/commit/25c12608e4fe5721e70b75597d6d798f753f4c44)), closes [#218](https://github.com/darellchua2/opencode-config-template/issues/218) [#218](https://github.com/darellchua2/opencode-config-template/issues/218)

## [1.65.1](https://github.com/darellchua2/opencode-config-template/compare/v1.65.0...v1.65.1) (2026-06-19)


### Bug Fixes

* model ([55451b0](https://github.com/darellchua2/opencode-config-template/commit/55451b0bcdfbaa12cafbdd48b78cb47b75a19d8f))

# [1.65.0](https://github.com/darellchua2/opencode-config-template/compare/v1.64.0...v1.65.0) (2026-06-19)


### Features

* add version-bump-standard-skill and repo-ops-specialist-subagent ([#216](https://github.com/darellchua2/opencode-config-template/issues/216)) ([#217](https://github.com/darellchua2/opencode-config-template/issues/217)) ([baf628b](https://github.com/darellchua2/opencode-config-template/commit/baf628b6b01c83b46e2b4bda2f55815efc0af8af)), closes [fbca04/#d73a4a](https://github.com/darellchua2/opencode-config-template/issues/d73a4a)

# [1.64.0](https://github.com/darellchua2/opencode-config-template/compare/v1.63.0...v1.64.0) (2026-06-19)


### Features

* **agents:** mandatory learning gate + filesystem MCP doc accuracy [[#214](https://github.com/darellchua2/opencode-config-template/issues/214)] ([#215](https://github.com/darellchua2/opencode-config-template/issues/215)) ([9c78c30](https://github.com/darellchua2/opencode-config-template/commit/9c78c303d01fb5ddd2b97be3cf676921930ae51c))

# [1.63.0](https://github.com/darellchua2/opencode-config-template/compare/v1.62.1...v1.63.0) (2026-06-19)


### Features

* atomic plan steps, mandatory consumer traversal, subagent model tiering [[#212](https://github.com/darellchua2/opencode-config-template/issues/212)] ([#213](https://github.com/darellchua2/opencode-config-template/issues/213)) ([67e70a3](https://github.com/darellchua2/opencode-config-template/commit/67e70a33569c35794bd9efb4d80ba7028798362a))

## [1.62.1](https://github.com/darellchua2/opencode-config-template/compare/v1.62.0...v1.62.1) (2026-06-13)


### Bug Fixes

* **agents:** align skill permissions with actual skill names ([973210c](https://github.com/darellchua2/opencode-config-template/commit/973210c2726687250811e474a82a69c79cc1b719))

# [1.62.0](https://github.com/darellchua2/opencode-config-template/compare/v1.61.0...v1.62.0) (2026-06-13)


### Features

* **skills:** curate 48 learnings into 1 new + 18 existing skills [BT-69] ([#211](https://github.com/darellchua2/opencode-config-template/issues/211)) ([98cd42c](https://github.com/darellchua2/opencode-config-template/commit/98cd42c4d7ce972b17b70d01d986d0125347aed6))

# [1.61.0](https://github.com/darellchua2/opencode-config-template/compare/v1.60.0...v1.61.0) (2026-06-03)


### Features

* add opencode-goal-plugin, shell-strategy, type-inject, and unmoji plugins ([#210](https://github.com/darellchua2/opencode-config-template/issues/210)) ([feaf8a9](https://github.com/darellchua2/opencode-config-template/commit/feaf8a90a9b22c186f16443e662b620975d3603c)), closes [#209](https://github.com/darellchua2/opencode-config-template/issues/209)

# [1.60.0](https://github.com/darellchua2/opencode-config-template/compare/v1.59.0...v1.60.0) (2026-05-30)


### Features

* update general agent model to glm-5-turbo ([6a7e6aa](https://github.com/darellchua2/opencode-config-template/commit/6a7e6aacef8776e1eb73787109c9103028cfcaab))

# [1.59.0](https://github.com/darellchua2/opencode-config-template/compare/v1.58.0...v1.59.0) (2026-05-30)


### Features

* update explore agent model to glm-5-turbo ([57d6009](https://github.com/darellchua2/opencode-config-template/commit/57d60096ec6ede77d176571f02b216c975cacd0e))

# [1.58.0](https://github.com/darellchua2/opencode-config-template/compare/v1.57.0...v1.58.0) (2026-05-29)


### Features

* replace opencode-supermemory with opencode-superlocalmemory (100% local) ([#208](https://github.com/darellchua2/opencode-config-template/issues/208)) ([2be10ab](https://github.com/darellchua2/opencode-config-template/commit/2be10ab7429ae8b259c9c11ddaa28f0d3f959214)), closes [#207](https://github.com/darellchua2/opencode-config-template/issues/207)

# [1.57.0](https://github.com/darellchua2/opencode-config-template/compare/v1.56.0...v1.57.0) (2026-05-24)


### Features

* **agents,skills:** add ECC-inspired search-first, context-budget, and language reviewers [BT-55] ([#206](https://github.com/darellchua2/opencode-config-template/issues/206)) ([9360feb](https://github.com/darellchua2/opencode-config-template/commit/9360feb188ba77f677a8b7c01b2081d2a55b1822))

# [1.56.0](https://github.com/darellchua2/opencode-config-template/compare/v1.55.0...v1.56.0) (2026-05-24)


### Features

* **skills:** add documentation-consistency-skill — audit + auto-fix doc drift ([#205](https://github.com/darellchua2/opencode-config-template/issues/205)) ([865b844](https://github.com/darellchua2/opencode-config-template/commit/865b8448a91f73a60ce1fdb74c952f5826a2cd11)), closes [#204](https://github.com/darellchua2/opencode-config-template/issues/204)

# [1.55.0](https://github.com/darellchua2/opencode-config-template/compare/v1.54.0...v1.55.0) (2026-05-24)


### Features

* **agents:** add interactive workflow selection to ticket-creation-subagent ([#203](https://github.com/darellchua2/opencode-config-template/issues/203)) ([4caab48](https://github.com/darellchua2/opencode-config-template/commit/4caab480e3056af25c858d4f9e5397bc864dd654))

# [1.54.0](https://github.com/darellchua2/opencode-config-template/compare/v1.53.0...v1.54.0) (2026-05-24)


### Features

* **agents:** update ticket-creation-subagent with prompt-first workflow and architecture review [#201](https://github.com/darellchua2/opencode-config-template/issues/201) ([#202](https://github.com/darellchua2/opencode-config-template/issues/202)) ([55cce55](https://github.com/darellchua2/opencode-config-template/commit/55cce5527a603981ccc3f166ade9c3e7ae58235a))

# [1.53.0](https://github.com/darellchua2/opencode-config-template/compare/v1.52.0...v1.53.0) (2026-05-24)


### Features

* **skills:** add 11 new skills — security, devops, api, python [IBIS-215] ([#200](https://github.com/darellchua2/opencode-config-template/issues/200)) ([b1bb9b8](https://github.com/darellchua2/opencode-config-template/commit/b1bb9b82550488d93f39125c493627abc6b5e390)), closes [hi#value](https://github.com/hi/issues/value)

# [1.52.0](https://github.com/darellchua2/opencode-config-template/compare/v1.51.0...v1.52.0) (2026-05-24)


### Features

* **skills:** add git-compact-commits-skill [BT-54] ([#199](https://github.com/darellchua2/opencode-config-template/issues/199)) ([759bdd6](https://github.com/darellchua2/opencode-config-template/commit/759bdd6b31defbb6e1c9e8cf664552992a002d08))

# [1.51.0](https://github.com/darellchua2/opencode-config-template/compare/v1.50.3...v1.51.0) (2026-05-24)


### Features

* **mermaid:** MCP server + skill-only architecture, remove 2 diagram agents ([#198](https://github.com/darellchua2/opencode-config-template/issues/198)) ([fce0873](https://github.com/darellchua2/opencode-config-template/commit/fce0873a63959d97436efa03a08a8a670acc1eb8)), closes [#197](https://github.com/darellchua2/opencode-config-template/issues/197)

## [1.50.3](https://github.com/darellchua2/opencode-config-template/compare/v1.50.2...v1.50.3) (2026-05-22)


### Bug Fixes

* **ci:** update release workflow paths for deploy/ restructure ([#196](https://github.com/darellchua2/opencode-config-template/issues/196)) ([93295d3](https://github.com/darellchua2/opencode-config-template/commit/93295d3b044fb7ddf5c7b3ecc0f64662b1bac6c7)), closes [#194](https://github.com/darellchua2/opencode-config-template/issues/194)

## [Unreleased](https://github.com/darellchua2/opencode-config-template/compare/v1.50.2...HEAD)

### Code Refactoring

* **refactor:** move user-space deployment files into deploy/ folder for clearer separation ([#194](https://github.com/darellchua2/opencode-config-template/issues/194))
* **docs(codegraph):** add built-in subagent CodeGraph injection to AGENTS.md files ([#194](https://github.com/darellchua2/opencode-config-template/issues/194))

## [1.50.2](https://github.com/darellchua2/opencode-config-template/compare/v1.50.1...v1.50.2) (2026-05-21)


### Bug Fixes

* **config:** add missing codegraph MCP server to root config.json [[#190](https://github.com/darellchua2/opencode-config-template/issues/190)] ([#191](https://github.com/darellchua2/opencode-config-template/issues/191)) ([015dc14](https://github.com/darellchua2/opencode-config-template/commit/015dc14ccde090d11b3e0de3da370ebcb2a7ea44))

## [1.50.1](https://github.com/darellchua2/opencode-config-template/compare/v1.50.0...v1.50.1) (2026-05-21)


### Bug Fixes

* add strict input validation to y/n prompts in setup scripts (BT-53) ([#189](https://github.com/darellchua2/opencode-config-template/issues/189)) ([196289e](https://github.com/darellchua2/opencode-config-template/commit/196289eb0b776a0d9626aed224e30b1ba2ea1eca))

# [1.50.0](https://github.com/darellchua2/opencode-config-template/compare/v1.49.0...v1.50.0) (2026-05-21)


### Features

* add CodeGraph MCP server, split label skills, and remove code-quality-subagent ([#187](https://github.com/darellchua2/opencode-config-template/issues/187)) ([80d074b](https://github.com/darellchua2/opencode-config-template/commit/80d074b67b8c1cf496cfbb8d7dbe0fdfd74980aa)), closes [#186](https://github.com/darellchua2/opencode-config-template/issues/186) [#188](https://github.com/darellchua2/opencode-config-template/issues/188)

# [1.49.0](https://github.com/darellchua2/opencode-config-template/compare/v1.48.0...v1.49.0) (2026-05-17)


### Features

* add LEARNINGS infrastructure with dual-strategy knowledge persistence ([#184](https://github.com/darellchua2/opencode-config-template/issues/184)) ([c328240](https://github.com/darellchua2/opencode-config-template/commit/c3282402ca9214c7854be5310035e5e61b54a491))

# [1.48.0](https://github.com/darellchua2/opencode-config-template/compare/v1.47.1...v1.48.0) (2026-05-17)


### Features

* add frontend-design-skill and enhance pptx/docx/xlsx with anti-AI-slop aesthetics ([#179](https://github.com/darellchua2/opencode-config-template/issues/179)) ([5e09917](https://github.com/darellchua2/opencode-config-template/commit/5e099174bdd0674c7c1d9f91566ffe9b9b5f8f6f)), closes [#178](https://github.com/darellchua2/opencode-config-template/issues/178)

## [1.47.1](https://github.com/darellchua2/opencode-config-template/compare/v1.47.0...v1.47.1) (2026-05-17)


### Bug Fixes

* **agents:** correct task permission mismatches and document subagent chaining ([#170](https://github.com/darellchua2/opencode-config-template/issues/170)) ([#177](https://github.com/darellchua2/opencode-config-template/issues/177)) ([25a882b](https://github.com/darellchua2/opencode-config-template/commit/25a882b3789813b01bf5f44848dd2bd0abe83a49))

# [1.47.0](https://github.com/darellchua2/opencode-config-template/compare/v1.46.0...v1.47.0) (2026-05-01)


### Features

* **scripts:** add git pull to pm2 restart script ([e7454eb](https://github.com/darellchua2/opencode-config-template/commit/e7454eb484717e8f43c4508af22fe097f90fa756))

# [1.46.0](https://github.com/darellchua2/opencode-config-template/compare/v1.45.0...v1.46.0) (2026-04-28)


### Features

* **scripts:** add PM2 restart script for opencode serve ([#173](https://github.com/darellchua2/opencode-config-template/issues/173)) ([4474384](https://github.com/darellchua2/opencode-config-template/commit/4474384464eda5d98c3ff8de1a0ba9942afa0227))

# [1.45.0](https://github.com/darellchua2/opencode-config-template/compare/v1.44.0...v1.45.0) (2026-04-27)


### Features

* **docker:** add code execution, persistent volumes, folder passthrough, and git support ([#172](https://github.com/darellchua2/opencode-config-template/issues/172)) ([ace6f49](https://github.com/darellchua2/opencode-config-template/commit/ace6f49eaae05effe87ba402452712e084e258cb)), closes [#171](https://github.com/darellchua2/opencode-config-template/issues/171)

# [1.44.0](https://github.com/darellchua2/opencode-config-template/compare/v1.43.0...v1.44.0) (2026-04-22)


### Bug Fixes

* resolve docker-entrypoint.sh auth.json generation error ([62b1a1b](https://github.com/darellchua2/opencode-config-template/commit/62b1a1b823e2f11687e79448c49d58bbaabab23d))
* rewrite docker-entrypoint.sh to build auth.json in single pass ([6476d9b](https://github.com/darellchua2/opencode-config-template/commit/6476d9bb2f764e75f7925feda8b8d27a8da07bff))
* **setup:** correct echo formatting in print_summary skill listings ([75270c5](https://github.com/darellchua2/opencode-config-template/commit/75270c53dde6107b209643e2173f021a4be23bc8))


### Features

* implement dual-mode repo with Docker standalone and user-space deploy ([5724429](https://github.com/darellchua2/opencode-config-template/commit/572442911089c78a49d9fbf48bda22b98b30d8a4)), closes [#166](https://github.com/darellchua2/opencode-config-template/issues/166)

# [1.43.0](https://github.com/darellchua2/opencode-config-template/compare/v1.42.1...v1.43.0) (2026-04-22)


### Features

* **agents:** add built-in subagent task permissions to top 5 agents ([b76be5e](https://github.com/darellchua2/opencode-config-template/commit/b76be5ef17ad317ec7cc9a52a3e27dec20c9ac57)), closes [#167](https://github.com/darellchua2/opencode-config-template/issues/167)

## [1.42.1](https://github.com/darellchua2/opencode-config-template/compare/v1.42.0...v1.42.1) (2026-04-15)


### Bug Fixes

* resolve Python syntax errors in thumbnail.py and base.py validator ([95b42a8](https://github.com/darellchua2/opencode-config-template/commit/95b42a8f90d576eaa72ced6c6efc2f13e6392fa0))
* udpate gitignore ([1766328](https://github.com/darellchua2/opencode-config-template/commit/17663286c7c345689daec953270a4c4c3dc93a0b))

# [1.42.0](https://github.com/darellchua2/opencode-config-template/compare/v1.41.0...v1.42.0) (2026-04-15)


### Bug Fixes

* model override for explore and general ([025bb26](https://github.com/darellchua2/opencode-config-template/commit/025bb26e7b0634f67d181efdc8b64a8b8d9b783d))


### Features

* add plan-execution-skill and update documentation sync ([d5bef75](https://github.com/darellchua2/opencode-config-template/commit/d5bef75fb30d9ef00644a7a67d7c201bc31194a5))

# [1.41.0](https://github.com/darellchua2/opencode-config-template/compare/v1.40.1...v1.41.0) (2026-04-14)


### Features

* add semantic-release-convention governance skill and standardize release pipeline ([#159](https://github.com/darellchua2/opencode-config-template/issues/159)) ([90fd218](https://github.com/darellchua2/opencode-config-template/commit/90fd218932fe4056b3944d11a3c6980a15407d6c)), closes [#158](https://github.com/darellchua2/opencode-config-template/issues/158)

## [1.40.1](https://github.com/darellchua2/opencode-config-template/compare/v1.40.0...v1.40.1) (2026-04-12)


### Bug Fixes

* comprehensive quality review and enhancement of skills and agents ([#154](https://github.com/darellchua2/opencode-config-template/issues/154)) ([ccd2850](https://github.com/darellchua2/opencode-config-template/commit/ccd2850d5073082065a003753055a6d690cb9796))

# [1.40.0](https://github.com/darellchua2/opencode-config-template/compare/v1.39.1...v1.40.0) (2026-04-12)


### Features

* add backup retention cleanup, unit tests, and 4 agent optimization skills ([#150](https://github.com/darellchua2/opencode-config-template/issues/150)) ([#151](https://github.com/darellchua2/opencode-config-template/issues/151)) ([fb153b0](https://github.com/darellchua2/opencode-config-template/commit/fb153b0a8978ab143091d29412c73f9777e0aa08))

## [1.39.1](https://github.com/darellchua2/opencode-config-template/compare/v1.39.0...v1.39.1) (2026-04-10)


### Bug Fixes

* **mcp:** migrate Atlassian MCP endpoint from /v1/sse to /v1/mcp ([23913d5](https://github.com/darellchua2/opencode-config-template/commit/23913d52e468a34c79fb6dbf6a7fb697f1e86a8b)), closes [#148](https://github.com/darellchua2/opencode-config-template/issues/148)

# [1.39.0](https://github.com/darellchua2/opencode-config-template/compare/v1.38.0...v1.39.0) (2026-04-07)


### Features

* **plugins:** add opencode-gemini-auth and fix md-table-formatter scope ([a3698cc](https://github.com/darellchua2/opencode-config-template/commit/a3698ccfcf6c0837351078457d8a3c12e6b4d23e)), closes [#144](https://github.com/darellchua2/opencode-config-template/issues/144)
* **plugins:** remove opencode-claude-auth ([2e42868](https://github.com/darellchua2/opencode-config-template/commit/2e428680959b148fa92640a67ded46053068f56c))

# [1.38.0](https://github.com/darellchua2/opencode-config-template/compare/v1.37.3...v1.38.0) (2026-04-05)


### Features

* **skills:** add changelog-python-cliff skill for Python projects using git-cliff ([529f1ee](https://github.com/darellchua2/opencode-config-template/commit/529f1ee1699b6dece5790b86141d6a9f4ff880ac)), closes [#142](https://github.com/darellchua2/opencode-config-template/issues/142)

## [1.37.3](https://github.com/darellchua2/opencode-config-template/compare/v1.37.2...v1.37.3) (2026-03-30)


### Bug Fixes

* standardize agent models and remove skill-broker-subagent ([51b368e](https://github.com/darellchua2/opencode-config-template/commit/51b368e1f46184d3614ef290f5b5878db593c15e))

## [1.37.2](https://github.com/darellchua2/opencode-config-template/compare/v1.37.1...v1.37.2) (2026-03-30)


### Bug Fixes

* change glm-5 to glm-5.2 ([4472334](https://github.com/darellchua2/opencode-config-template/commit/4472334464967f57ee21ab6f9b8d87202be17c56))

## [1.37.1](https://github.com/darellchua2/opencode-config-template/compare/v1.37.0...v1.37.1) (2026-03-30)


### Bug Fixes

* update the models ([e62277b](https://github.com/darellchua2/opencode-config-template/commit/e62277baf7845413a45e46b01dedaf5761b31b6d))
