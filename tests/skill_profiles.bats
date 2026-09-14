#!/usr/bin/env bats
# GIT-333: skill-profile mechanism coverage (v2 shapes, PLAN-374).
#   1. every lean key in deploy/skill-profiles.json matches a real skill dir
#   2. lean ⊆ shipped skill allows in opencode_app/opencode.json (typo guard)
#   3. lean count == 47
#   4. apply-skill-profile.mjs lean rewrites a scratch deployed config to
#      exactly 47 allow rules + a skill deny-all-first; full leaves the
#      shipped permissions array verbatim. Non-skill rules are never touched.
# Note: these tests intentionally do NOT assert the shipped skill-allow count
# (count-drift tests own disk counts; allowlist size is profile-dependent).

setup() {
    PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    TEST_HOME="$(mktemp -d)"
    teardown_set=true
}

teardown() {
    [ -n "${TEST_HOME:-}" ] && rm -rf "$TEST_HOME"
}

lean_keys() {
    node -e "console.log(require('${PROJECT_ROOT}/deploy/skill-profiles.json').lean.join('\n'))"
}

@test "skill-profiles: lean has exactly 47 keys" {
    count=$(lean_keys | wc -l)
    [ "$count" -eq 47 ]
}

@test "skill-profiles: every lean key matches a skill dir on disk" {
    bad=$(lean_keys | while read -r k; do
        [ -d "${PROJECT_ROOT}/skills/${k}" ] || echo "$k"
    done)
    [ -z "$bad" ] || { echo "not on disk: $bad"; return 1; }
}

@test "skill-profiles: lean is a subset of the shipped skill allows" {
    bad=$(node -e "
const p=require('${PROJECT_ROOT}/deploy/skill-profiles.json');
const c=require('${PROJECT_ROOT}/opencode_app/opencode.json');
const allow=new Set(c.permissions.filter(r=>r.action==='skill'&&r.effect==='allow'&&r.resource!=='*').map(r=>r.resource));
console.log(p.lean.filter(k=>!allow.has(k)).join(' '));")
    [ -z "$bad" ] || { echo "not in shipped skill allows: $bad"; return 1; }
}

@test "apply-skill-profile: lean rewrites scratch config to 47 allows + deny-all-first" {
    scratch="${TEST_HOME}/opencode.json"
    cp "${PROJECT_ROOT}/opencode_app/opencode.json" "$scratch"
    non_skill_before=$(node -e "const c=require('$scratch');console.log(c.permissions.filter(r=>r.action!=='skill').length)")
    run node "${PROJECT_ROOT}/deploy/apply-skill-profile.mjs" \
        --config "$scratch" \
        --profiles "${PROJECT_ROOT}/deploy/skill-profiles.json" \
        --profile lean
    [ "$status" -eq 0 ]
    out=$(node -e "
const c=require('${scratch}');
const rules=c.permissions.filter(r=>r.action==='skill');
const allows=rules.filter(r=>r.resource!=='*');
const first=rules[0]||{};
const nonSkill=c.permissions.filter(r=>r.action!=='skill').length;
console.log(allows.length, first.resource==='*'&&first.effect==='deny'?'deny-ok':'no-deny', nonSkill===${non_skill_before}?'non-skill-ok':'non-skill-lost');")
    echo "result: $out"
    [ "$out" = "47 deny-ok non-skill-ok" ]
}

@test "apply-skill-profile: full is a verified no-op on a fresh copy" {
    scratch="${TEST_HOME}/opencode.json"
    cp "${PROJECT_ROOT}/opencode_app/opencode.json" "$scratch"
    before=$(node -e "const c=require('${scratch}');console.log(JSON.stringify(c.permissions))")
    run node "${PROJECT_ROOT}/deploy/apply-skill-profile.mjs" \
        --config "$scratch" \
        --profiles "${PROJECT_ROOT}/deploy/skill-profiles.json" \
        --profile full
    [ "$status" -eq 0 ]
    after=$(node -e "const c=require('${scratch}');console.log(JSON.stringify(c.permissions))")
    [ "$before" = "$after" ]
}

@test "apply-skill-profile: unknown profile and typo'd lean keys fail closed" {
    scratch="${TEST_HOME}/opencode.json"
    cp "${PROJECT_ROOT}/opencode_app/opencode.json" "$scratch"
    run node "${PROJECT_ROOT}/deploy/apply-skill-profile.mjs" --config "$scratch" \
        --profiles "${PROJECT_ROOT}/deploy/skill-profiles.json" --profile bogus
    [ "$status" -ne 0 ]

    # typo guard: a profiles file naming a key absent from the shipped allowlist must fail
    bad_profiles="${TEST_HOME}/bad-profiles.json"
    node -e "
const p=require('${PROJECT_ROOT}/deploy/skill-profiles.json');
p.lean=[...p.lean,'not-a-real-skill'];
require('fs').writeFileSync('${bad_profiles}',JSON.stringify(p,null,2));"
    run node "${PROJECT_ROOT}/deploy/apply-skill-profile.mjs" --config "$scratch" \
        --profiles "$bad_profiles" --profile lean
    [ "$status" -ne 0 ]
}
