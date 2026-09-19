---
name: github-runners-setup-skill
description: >-
  Set up a Linux machine as GitHub Actions self-hosted org runners
  (multi-runner folders, systemd services) with the local-if-idle /
  else-ubuntu-latest workflow. Gates gh scope refresh, sudo install, and
  PAT handling on explicit user action. Triggers: self-hosted runner,
  local CI runner, local-if-idle workflow.
license: Apache-2.0
compatibility: opencode
category: DevOps
---

## What I do

I turn a Linux box into a pool of GitHub Actions self-hosted runners for an
**organization**, one runner per subfolder of a chosen root (e.g.
`~/GITHUB_RUNNERS/r1..rN`), each as an auto-starting systemd service. I also
provide the workflow pattern that runs jobs on these runners **only when one
is online and idle**, falling back to `ubuntu-latest` otherwise.

Validated runbook (nus-cee org, Ubuntu 24.04, runners v2.337.0, 4 folders).

## When to use me

- "Set up this machine as GitHub Actions runners" / "add local runners to my org"
- "Use my machine for CI when it's free, GitHub's otherwise"
- Adding more runner folders to an existing pool

## Preconditions

- Linux x64, systemd, `gh` CLI installed and authenticated
- User is a member of the target org with rights to register runners
- Private repos (or public repos with fork-PR approvals enforced — self-hosted
  runners execute arbitrary workflow code from the repo)

## Procedure

Defaults below: org `ORG`, runner root `~/GITHUB_RUNNERS`, folders `r1..rN`,
host label prefix `<hostname>`. Ask the user for org + count + names once,
up front, with the question tool — then do not re-ask.

### 1. Scope check (GATED)

The registration API needs the `admin:org` scope. Check first:

```bash
gh auth status | grep -q "'admin:org'" || echo NEEDS_REFRESH
```

If refresh is needed, spawn it in a PTY, show the user the one-time code, and
**wait for their confirmation before continuing**:

```bash
gh auth refresh -h github.com -s admin:org
```

### 2. Install runner bits (automated)

Download once, extract into the first folder, copy to the rest:

```bash
VER=$(gh api /repos/actions/runner/releases/latest --jq .tag_name | tr -d v)
curl -sL -o /tmp/actions-runner-linux-x64-$VER.tar.gz \
  https://github.com/actions/runner/releases/download/v$VER/actions-runner-linux-x64-$VER.tar.gz
curl -sL -o /tmp/actions-runner-linux-x64-$VER.tar.gz.sha256 \
  https://github.com/actions/runner/releases/download/v$VER/actions-runner-linux-x64-$VER.tar.gz.sha256
( cd /tmp && sha256sum -c "actions-runner-linux-x64-$VER.tar.gz.sha256" )
mkdir -p ~/GITHUB_RUNNERS/r1
tar xzf /tmp/actions-runner-linux-x64-$VER.tar.gz -C ~/GITHUB_RUNNERS/r1
cd ~/GITHUB_RUNNERS
for d in r2 r3 r4; do cp -a r1 $d; done
```

Skip `installdependencies.sh` if a runner already works on this machine
(deps are system-wide); otherwise it needs sudo.

### 3. Register each runner (automated)

One registration token covers all folders (valid ~1h):

```bash
TOKEN=$(gh api orgs/ORG/actions/runners/registration-token --jq .token)
cd ~/GITHUB_RUNNERS
for d in r1 r2 r3 r4; do
  (cd $d && ./config.sh --url https://github.com/ORG --token "$TOKEN" \
     --name "$(hostname)-$d" --labels local --unattended)
done
```

Labels per runner: `self-hosted,Linux,X64,local` (defaults + `local`, the
pool label the workflow selects on). A transient 404 on the token mint can
be retried immediately.

### 4. Install services (GATED — user's terminal, never ours)

`svc.sh` needs sudo. **Never ask for the sudo password** — hand the user this
one line and wait for their "done":

```bash
for d in r1 r2 r3 r4; do (cd ~/GITHUB_RUNNERS/$d && sudo ./svc.sh install && sudo ./svc.sh start); done
```

Creates system services `actions.runner.<org>.<host>-rN.service`,
enabled at boot, running as the current user.

### 5. Verify (automated)

```bash
systemctl list-units 'actions.runner.*' --no-legend --plain
gh api /orgs/ORG/actions/runners --paginate \
  --jq '.runners[] | .name + " " + .status + " busy=" + (.busy|tostring)'
```

Expect every new runner `online busy=false` within ~30s and labels including
`local`. Registration is done at this point.

### 6. Local-if-idle workflow (GATED once for the PAT)

The runners list API needs a classic PAT with `admin:org`. The user must
create it (browser: Settings → Developer settings → Tokens classic) — do not
handle the token value in chat. Have the user run, in their own terminal:

```bash
read -rs PAT && gh secret set ORG_RUNNER_PAT --org ORG --visibility selected --repos REPO1,REPO2 <<< "$PAT" && unset PAT
```

Default to `--visibility selected` naming only the repos that opt into the
pool — the secret is an `admin:org` PAT, and `--visibility all` hands it to
every workflow in every repo of the org.

Then repos opt in by pairing a dispatcher job with the real job:

```yaml
jobs:
  pick-runner:
    runs-on: ubuntu-latest
    outputs:
      labels: ${{ steps.pick.outputs.labels }}
    steps:
      - id: pick
        env:
          GH_TOKEN: ${{ secrets.ORG_RUNNER_PAT }}
        run: |
          idle=$(gh api orgs/ORG/actions/runners --paginate \
            --jq '.runners[] | select(.labels[].name=="local") | select(.status=="online" and .busy==false) | .name' \
            | wc -l)
          if [ "$idle" -gt 0 ]; then
            echo 'labels=["self-hosted","local"]' >> "$GITHUB_OUTPUT"
          else
            echo 'labels=["ubuntu-latest"]' >> "$GITHUB_OUTPUT"
          fi
  build:
    needs: pick-runner
    runs-on: ${{ fromJSON(needs.pick-runner.outputs.labels) }}
    steps: [ ... real job ... ]
```

## Gate summary

| Gate | User action | Why |
|------|-------------|-----|
| 1 | Enter device code in browser | grants `admin:org` to gh |
| 4 | Run sudo one-liner in own terminal | agent must never take passwords |
| 6 | Create PAT + run `gh secret set` line | PAT value must not transit chat |

Every gate: state the exact command, what it does, then stop and wait for
explicit confirmation. Do not proceed on silence.

## Caveats

- **Race:** two runs can pick the same idle runner; the loser queues locally
  instead of falling back. Rare with 4+ runners; if it bites, add
  `timeout-minutes` + a `ubuntu-latest` retry job (`if: failure()`).
- **GitHub-first fallback is not possible** — hosted runners are never
  "unavailable", jobs just queue. Local-if-idle is the only deterministic
  direction.
- Dispatcher adds ~10–20s per run.
- `ORG_RUNNER_PAT` must be an **org** secret (`--org`), or repos won't see it.
  Keep `--visibility selected` — the PAT holds `admin:org`, so `all` exposes
  near-full org admin API to every workflow in every repo.

## Teardown

Per runner: `sudo ./svc.sh uninstall` (or stop+uninstall), then
`./config.sh remove --token "$(gh api orgs/ORG/actions/runners/registration-token --jq .token)"`,
then delete the folder.
