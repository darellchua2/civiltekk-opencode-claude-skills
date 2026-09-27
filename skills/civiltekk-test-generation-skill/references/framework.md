# framework-matrix route — the 6-step generation lifecycle

For `civiltekk-test-generation-skill` route `framework-matrix`, and the
shared lifecycle that the `python` and `nextjs` routes layer on top of.
Language-agnostic test generation: detect the stack, analyze sources,
generate scenarios, confirm, write files, verify they execute. Use the
generic route directly for any framework without a dedicated route, or to
standardize test generation across projects; add a dedicated route (a new
`references/<route>.md`) when a stack accrues version-specific patterns.

Bash snippets below require bash (git-bash/WSL on Windows).

## Step 1: Detect Framework and Package Manager

**Framework detection**:
- JavaScript/TypeScript: `grep -E "(jest|vitest)" package.json`
- Python: `grep pytest pyproject.toml` or `requirements.txt`
- Ruby: `grep -E "(rspec|minitest)" Gemfile`
- Go: Built-in testing

**Package manager detection**:
| Language | Manager | Lock File | Command |
|----------|---------|-----------|---------|
| JS/TS | npm | `package-lock.json` | `npm run <script>` |
| JS/TS | yarn | `yarn.lock` | `yarn <script>` |
| JS/TS | pnpm | `pnpm-lock.yaml` | `pnpm run <script>` |
| Python | Poetry | `pyproject.toml` | `poetry run <script>` |
| Python | pip | `requirements.txt` | Direct command |

## Step 2: Analyze Source Code

Use glob patterns to find source files (exclude test files):
```
<glob_pattern> --exclude "**/*test*.<ext>" --exclude "**/test/**/*"
```

Identify:
- Functions, classes, modules, components
- Import statements and dependencies
- Export patterns

## Step 3: Generate Test Scenarios

**Scenario categories**:

**Happy path**: Normal inputs, expected outputs, common use cases
**Edge cases**: Empty inputs, boundary values (0, 1, -1, max, min), single-item collections
**Error handling**: Invalid types, out of range values, missing params, invalid formats, permissions
**State management**: Initial state, state updates, multiple transitions, reset, cleanup
**User interactions**: Click events, form submissions, keyboard nav, input changes, hover/focus

**Scenario generation template**:
```
For each [function/class/component]:
  1. Identify inputs and return values
  2. Determine normal behavior (happy path)
  3. List edge cases based on input types
  4. Identify error conditions
  5. Check for state management or user interactions
```

## Step 4: Display Scenarios for Confirmation

```
📋 Generated Test Scenarios for <file_name>

**Type:** <Component | Function | Class>
**Item:** <Item Name>

**Scenarios:**
1. Happy Path: <description> → <result>
2. Edge Case: <description> → <result>
3. Error Case: <description> → <error>

**Total Scenarios:** <number>
**Framework:** <Jest | Vitest | Pytest>
**Test Command:** <command>

Proceed? (y/n/suggest)
```

## Step 5: Create Test Files

**Test file structure**:
```
describe('<ItemName>', () => {
  describe('Happy Path', () => { /* tests */ })
  describe('Edge Cases', () => { /* tests */ })
  describe('Error Handling', () => { /* tests */ })
  describe('State/Interactions', () => { /* tests */ })
})
```

**Naming conventions**:
- Jest/Vitest: `<Component>.test.tsx` or `<Component>.spec.tsx`
- Pytest: `test_<module>.py` or `<module>_test.py`
- RSpec: `<module>_spec.rb`
- Go: `<module>_test.go`

## Step 6: Verify Executability

**Run tests**:
```bash
# JavaScript/TypeScript
npm run test              # npm
yarn test                 # yarn
pnpm run test            # pnpm

# Python
pytest                   # direct
poetry run pytest        # poetry
```

**Verification checklist**:
- [ ] Test files created in correct location
- [ ] Naming follows framework conventions
- [ ] Imports resolve correctly
- [ ] Tests are discoverable
- [ ] Tests execute (even if they fail)
- [ ] No syntax errors

## Mock Pitfalls

### `mock-headers-magicmock-truthy`

`MagicMock` auto-creates any attribute on first access, so `resp.headers` is a truthy MagicMock by default. This produces two silent false positives: (1) `if resp.headers:` evaluates truthy even when no headers were set, masking a missing-header bug in production code, and (2) `resp.headers.get('Location')` returns a truthy mock that then crashes with `TypeError` when passed to `int()`, `len()`, or string operations. In every test helper that builds a fake response, explicitly assign a REAL dict: `resp.headers = headers or {}`. This forces the test to confront the empty-headers case the same way production code will.

```python
from unittest.mock import MagicMock

# WRONG — headers auto-created as truthy MagicMock, .get() returns truthy mock
def make_response(status: int = 200):
    resp = MagicMock()
    resp.status_code = status
    return resp  # resp.headers is truthy MagicMock, .get('Location') is truthy

def test_redirect():
    resp = make_response(302)
    assert resp.headers.get('Location')  # PASSES — but production returns None!
    int(resp.headers.get('retry-after')) # TypeError: int() argument must be a string, not MagicMock

# CORRECT — headers is always a real dict; empty case behaves like production
def make_response(status: int = 200, headers: dict | None = None):
    resp = MagicMock()
    resp.status_code = status
    resp.headers = headers or {}  # real dict, .get() returns None on missing
    return resp

def test_redirect_no_location():
    resp = make_response(302)  # no headers → empty dict
    assert resp.headers.get('Location') is None  # PASSES — matches production

def test_redirect_with_location():
    resp = make_response(302, headers={'Location': '/new'})
    assert resp.headers.get('Location') == '/new'
```

**Detection:**

```bash
rg 'MagicMock\(' --type py | rg -v 'headers\s*=|\.headers\s*='
```

**Rule:** Never let `MagicMock` auto-create `.headers`. In every fake-response builder, assign a real dict: `resp.headers = headers or {}`. This forces the empty-headers case to behave in tests exactly as it does in production. The same rule generalizes to any auto-creating mock standing in for a structured container — the `python` and `nextjs` route files cite this pitfall instead of restating it.

## Best Practices

- **Organization**: Keep tests in `tests/` or `__tests__/` directory
- **Fixtures**: Use framework-specific fixtures for common setup
- **Parametrization**: Use parametrized tests for similar cases
- **Isolation**: Each test should be independent
- **Coverage**: Aim for 80%+ code coverage
- **Speed**: Keep unit tests fast (< 0.1s each)
- **AAA pattern**: Structure tests as Arrange-Act-Assert
- **Confirmation**: Always show scenarios before creating files

## Common Issues

### Framework Not Detected
Check for config files:
- JS/TS: `package.json`, `jest.config.js`, `vitest.config.ts`
- Python: `pyproject.toml`, `pytest.ini`, `setup.cfg`

### Package Manager Not Detected
Check lock files:
- `package-lock.json` → npm
- `yarn.lock` → yarn
- `pnpm-lock.yaml` → pnpm
- `pyproject.toml` → poetry (or pip)

### Import Errors
Ensure correct import paths and modules are exported:
```bash
# Python
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# JS/TS
grep '"exports"' package.json
```

### Tests Not Discovered
Verify correct naming and location per framework patterns
