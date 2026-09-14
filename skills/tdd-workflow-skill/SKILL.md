---
name: tdd-workflow-skill
description: Guide developers through Test Driven Development workflow with red-green-refactor cycle, supporting multiple languages and frameworks
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Framework
---

## What I do

I guide developers through the complete Test Driven Development (TDD) workflow by:

1. **Explain TDD Principles**: Teach the core red-green-refactor cycle and its purpose
2. **Provide Language-Specific Guidance**: Offer TDD workflows for Python/pytest, JavaScript/Jest/Vitest, Next.js, and other frameworks
3. **Define Test Structure**: Show how to structure tests for TDD (failing tests first, minimal implementation, refactoring)
4. **Guide Through Workflow Steps**: Walk through Write Test → Run Test (Red) → Write Minimal Code → Run Test (Green) → Refactor cycle
5. **Provide Examples**: Show concrete TDD examples with before/after code comparisons
6. **Integrate with Test Generation**: Work seamlessly with test-generator-framework, python-pytest-creator, and nextjs-unit-test-creator
7. **Enforce TDD Best Practices**: Promote test isolation, clear test names, and incremental development

## When to use me

Use this skill when:
- You want to adopt Test Driven Development methodology for a new feature
- You need guidance on TDD workflow for a specific language or framework
- You're teaching or mentoring developers on TDD practices
- You want to refactor existing code using TDD techniques
- You need to verify your test coverage follows TDD principles
- You're setting up testing standards for a new project
- You want to ensure tests are written before implementation code

Use this **before** using test generation skills like:
- `test-generator-framework` for generic test patterns
- `python-pytest-creator` for Python-specific TDD
- `nextjs-unit-test-creator` for Next.js TDD

## Prerequisites

- Basic understanding of unit testing concepts
- Access to testing framework for your language (pytest, Jest, Vitest, etc.)
- Knowledge of the programming language you're working with
- Familiarity with project structure and build tools
- Optional: Existing test generation skills for your language

## TDD Principles

### The Red-Green-Refactor Cycle

TDD follows a continuous cycle:

```
┌─────────────────────────────────────────┐
│  1. Write a failing test (RED)      │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  2. Run test and see it fail (RED)   │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  3. Write minimal code to pass (GREEN) │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  4. Run test and see it pass (GREEN)  │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  5. Refactor code (REFACTOR)         │
└─────────────────────────────────────────┘
                 ↓
         (Return to step 1)
```

### Core TDD Rules

1. **Never write production code without a failing test**
2. **Write the minimal amount of code to make the test pass**
3. **Refactor only after all tests pass**
4. **Keep tests small and focused**
5. **Write one test at a time**
6. **Test behavior, not implementation details**

## Steps

### Step 1: Choose Your Feature

Identify the feature or function you want to implement:

**Example**: "User login functionality"

**Break down into behaviors**:
- Validate email format
- Check if user exists
- Verify password matches
- Return authentication token on success
- Return error message on failure

### Step 2: Write First Failing Test (RED)

Start with the simplest possible test case:

**Python/pytest Example**:
```python
def test_login_with_valid_credentials():
    """User should be able to login with valid credentials."""
    response = auth.login("user@example.com", "password123")
    assert response.success is True
    assert "token" in response.data
```

**JavaScript/Jest Example**:
```javascript
test('user can login with valid credentials', () => {
  const response = auth.login('user@example.com', 'password123');
  expect(response.success).toBe(true);
  expect(response.data).toHaveProperty('token');
});
```

**Verify the test fails**:
```bash
# Python
pytest tests/test_auth.py -v

# JavaScript
npm test auth.test.js
```

**Expected output**: Test should fail with an error like `AttributeError: module 'auth' has no attribute 'login'` or `auth.login is not a function`

### Step 3: Write Minimal Production Code (GREEN)

Write just enough code to make the test pass, nothing more:

**Python/pytest Example**:
```python
# auth.py
class AuthResponse:
    def __init__(self, success, data):
        self.success = success
        self.data = data

def login(email, password):
    return AuthResponse(success=True, data={"token": "dummy_token"})
```

**JavaScript/Jest Example**:
```javascript
// auth.js
const login = (email, password) => {
  return {
    success: true,
    data: { token: 'dummy_token' }
  };
};

module.exports = { login };
```

**Verify the test passes**:
```bash
# Python
pytest tests/test_auth.py -v

# JavaScript
npm test auth.test.js
```

**Expected output**: Test should pass (1 passed)

### Step 4: Refactor (REFACTOR)

Now that the test passes, improve the code quality without changing behavior:

**Refactoring guidelines**:
- Extract constants
- Improve variable names
- Remove code duplication
- Improve readability
- Add input validation

**Python Refactored Example**:
```python
# auth.py
DUMMY_TOKEN = "dummy_token"

class AuthResponse:
    def __init__(self, success, data):
        self.success = success
        self.data = data

def login(email, password):
    if not email or not password:
        raise ValueError("Email and password are required")
    return AuthResponse(success=True, data={"token": DUMMY_TOKEN})
```

**JavaScript Refactored Example**:
```javascript
// auth.js
const DUMMY_TOKEN = 'dummy_token';

const login = (email, password) => {
  if (!email || !password) {
    throw new Error('Email and password are required');
  }
  return {
    success: true,
    data: { token: DUMMY_TOKEN }
  };
};

module.exports = { login };
```

**Verify tests still pass**:
```bash
# Python
pytest tests/test_auth.py -v

# JavaScript
npm test auth.test.js
```

### Step 5: Add Next Test Case

Return to Step 2 for the next behavior:

**Example**: Test invalid credentials
```python
def test_login_with_invalid_credentials():
    """User should not be able to login with invalid credentials."""
    response = auth.login("user@example.com", "wrong_password")
    assert response.success is False
    assert "error" in response.data
```

Write minimal code to pass, then refactor. Continue until all behaviors are tested.

## Language-Specific TDD Workflows

### Python TDD with pytest

**Setup**:
```bash
# Install pytest
pip install pytest pytest-cov

# Create tests directory
mkdir -p tests

# Create __init__.py
touch tests/__init__.py
```

**TDD Workflow**:
```bash
# 1. Create test file
touch tests/test_feature.py

# 2. Write failing test
vim tests/test_feature.py

# 3. Run test (should fail)
pytest tests/test_feature.py -v

# 4. Write minimal production code
vim feature.py

# 5. Run test (should pass)
pytest tests/test_feature.py -v

# 6. Refactor code
vim feature.py

# 7. Run tests again (should still pass)
pytest tests/test_feature.py -v

# 8. Add next test
# Return to step 2
```

**Pytest-specific TDD tips**:
- Use descriptive test names (snake_case)
- Use pytest fixtures for setup/teardown
- Use `@pytest.mark.parametrize` for data-driven tests
- Use `pytest.raises` for exception testing
- Use `pytest --cov` for coverage checking

### JavaScript/TypeScript TDD with Jest/Vitest

**Setup (Jest)**:
```bash
# Install Jest
npm install --save-dev jest

# Create test directory
mkdir tests

# Add test script to package.json
# "test": "jest"
```

**Setup (Vitest)**:
```bash
# Install Vitest
npm install --save-dev vitest

# Create test directory
mkdir tests

# Add test script to package.json
# "test": "vitest"
```

**TDD Workflow**:
```bash
# 1. Create test file
touch feature.test.js

# 2. Write failing test
vim feature.test.js

# 3. Run test (should fail)
npm test feature.test.js

# 4. Write minimal production code
vim feature.js

# 5. Run test (should pass)
npm test feature.test.js

# 6. Refactor code
vim feature.js

# 7. Run tests again (should still pass)
npm test feature.test.js

# 8. Add next test
# Return to step 2
```

**Jest/Vitest-specific TDD tips**:
- Use descriptive test names (descriptive strings)
- Use `describe` blocks to group related tests
- Use `beforeEach`/`afterEach` for setup/teardown
- Use `.toThrow()` for exception testing
- Use watch mode for rapid TDD: `npm test -- --watch`

### Next.js TDD

**Setup**:
```bash
# Use test-generator-framework with nextjs-unit-test-creator
# Next.js standard setup includes testing infrastructure
```

**TDD for Next.js Components**:
```typescript
// Button.test.tsx
import { render, screen } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders button with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });
});
```

**Next.js-specific TDD tips**:
- Test user interactions (click, form submit, etc.)
- Test component props and state
- Mock API calls with testing-library
- Use `@testing-library/react` for component testing
- Use `@testing-library/jest-dom` for custom matchers

## Best Practices

### Test Organization

1. **One test file per module/component**
2. **Group related tests with `describe` blocks**
3. **Use descriptive test names that explain the behavior**
4. **Keep tests independent and isolated**
5. **Arrange-Act-Assert (AAA) pattern**:

```python
# Arrange: Set up test data and conditions
user = create_user(email="test@example.com")

# Act: Execute the function being tested
result = user.validate_email()

# Assert: Verify the expected outcome
assert result is True
```

### Test Naming

**Good test names**:
- ✅ `test_login_with_valid_credentials_succeeds`
- ✅ `test_empty_email_raises_validation_error`
- ✅ `user can login with correct password` (Jest)
- ✅ `returns error when password is too short` (Jest)

**Bad test names**:
- ❌ `test_login`
- ❌ `test_1`
- ❌ `testValidation`

### Writing Good Tests

1. **Test behavior, not implementation**:
   ```python
   # Good: Tests behavior
   assert user.is_authenticated() is True

   # Bad: Tests implementation
   assert user._token is not None
   ```

2. **Keep tests small and focused**:
   ```python
   # Good: One behavior per test
   def test_login_succeeds_with_valid_credentials():
       ...

   def test_login_fails_with_invalid_password():
       ...

   # Bad: Multiple behaviors in one test
   def test_login():
       # Tests success and failure in one test
       ...
   ```

3. **Use test data generators for edge cases**:
   ```python
   @pytest.mark.parametrize("email,valid", [
       ("user@example.com", True),
       ("invalid", False),
       ("", False),
       (None, False),
   ])
   def test_email_validation(email, valid):
       assert is_valid_email(email) is valid
   ```

### Refactoring Guidelines

1. **Refactor only when all tests pass**
2. **Make small, incremental changes**
3. **Run tests after each refactoring step**
4. **Don't add new functionality during refactoring**
5. **Use automated refactoring tools when available**
6. **Maintain the same test coverage**

## Common Issues

### Tests Don't Fail Initially

**Issue**: Tests pass immediately without writing production code

**Cause**: You're testing the wrong thing or implementation already exists

**Solution**:
- Ensure you're testing a new feature or behavior
- Check if the function/class already exists
- Write a test for a specific edge case or error condition
- Make the test more specific about expected behavior

### Too Much Production Code Written

**Issue**: Writing more code than needed to make test pass

**Cause**: Getting ahead of TDD cycle, thinking about implementation

**Solution**:
- Focus only on making the failing test pass
- Return hard-coded values if necessary (they'll be replaced by next tests)
- Write the absolute minimum code
- Trust that future tests will drive more implementation

### Tests Become Brittle

**Issue**: Tests break when refactoring code

**Cause**: Testing implementation details instead of behavior

**Solution**:
- Test public interfaces and behavior
- Avoid testing private methods
- Use mocking appropriately for external dependencies
- Focus on what the code should do, not how

### Slow TDD Cycle

**Issue**: Writing and running tests takes too long

**Solution**:
- Use test frameworks with watch mode (Jest/Vitest `--watch`, pytest-xdist)
- Keep test files small and focused
- Use fixtures to reduce setup duplication
- Run only the test you're working on
- Consider unit tests over integration tests for TDD

### Test Coverage Too Low

**Issue**: Missing edge cases and error handling

**Solution**:
- Write tests for all code paths
- Use parametrized tests for edge cases
- Test error conditions explicitly
- Check coverage with `pytest --cov` or Jest coverage
- Review coverage reports for untested code

## Verification Commands

After implementing TDD workflow, verify with these commands:

```bash
# Python TDD Verification
pytest tests/ -v --cov
# Expected: All tests pass, coverage 80%+

# JavaScript TDD Verification
npm test -- --coverage
# Expected: All tests pass, coverage 80%+

# Check test file exists and is named correctly
test -f tests/test_feature.py && echo "✓ Test file exists"

# Verify tests follow TDD principles
# Check for descriptive names
grep "def test_" tests/test_feature.py | wc -l
# Expected: Multiple test functions with descriptive names

# Verify production code exists
test -f feature.py && echo "✓ Production code exists"
```

**TDD Verification Checklist**:
- [ ] Test written before production code
- [ ] Test fails initially (RED)
- [ ] Minimal code written to pass test (GREEN)
- [ ] Code refactored after passing (REFACTOR)
- [ ] Test still passes after refactoring
- [ ] Tests are descriptive and focused
- [ ] Tests cover edge cases and errors
- [ ] No tests of implementation details
- [ ] All tests pass
- [ ] Code coverage is 80% or higher

## Example TDD Session

### Feature: Validate Email Address

**Step 1: Write failing test**
```python
# tests/test_email.py
def test_valid_email_format():
    assert is_valid_email("user@example.com") is True
```

**Step 2: Run test (fails)**
```bash
$ pytest tests/test_email.py
# FAILED - is_valid_email not defined
```

**Step 3: Write minimal code**
```python
# email.py
def is_valid_email(email):
    return True  # Pass the test with minimal code
```

**Step 4: Run test (passes)**
```bash
$ pytest tests/test_email.py
# PASSED
```

**Step 5: Refactor**
```python
# email.py
import re

def is_valid_email(email):
    """Validate email format using regex."""
    if not email:
        return False
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None
```

**Step 6: Run test (still passes)**
```bash
$ pytest tests/test_email.py
# PASSED
```

**Step 7: Add next test (invalid email)**
```python
def test_invalid_email_format():
    assert is_valid_email("invalid") is False
```

**Step 8: Run test (fails)**
```bash
$ pytest tests/test_email.py
# FAILED - "invalid" passes validation incorrectly
```

**Step 9: Write minimal code (already done!)**
```python
# The regex in is_valid_email handles this case
```

**Step 10: Run test (passes)**
```bash
$ pytest tests/test_email.py
# PASSED
```

**Step 11: Add more edge cases**
```python
@pytest.mark.parametrize("email,expected", [
    ("", False),
    (None, False),
    ("user@", False),
    ("@example.com", False),
    ("user@example", False),
    ("user@example.", False),
])
def test_email_edge_cases(email, expected):
    assert is_valid_email(email) is expected
```

**Continue until all behaviors are tested!**

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

1. **Gate check**: confirm env var is set; if unset, follow default behavior above.
2. **Auto-detection**: if this skill is invoked on a task that looks iterative (multiple cycles expected), prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". On "y", continue; on "n", default behavior. Cache the answer for the session.
3. **5-stage loop**: cycle Understand → Hypothesize → Experiment → Evaluate → Log & Iterate. See `autoresearch-core-skill/SKILL.md`.
4. **Evaluator contract**: emit `{"pass":bool,"score":N}` JSON from a mechanical evaluator. Pass determines keep/revert; score logged to `tdd-results.tsv`. See `autoresearch-core-skill/references/evaluator-contract.md`.
5. **Stuck detection**: 3 consecutive non-improving iterations → strategy pivot; 5 consecutive → paradigm shift. See `autoresearch-core-skill/references/stuck-detection.md`.
6. **Audit trail**: append every iteration to `tdd-results.tsv` (8-column: iteration, commit, metric, delta, status, description, timestamp, evaluator_output). See `autoresearch-core-skill/references/audit-trail.md`.
7. **Crash recovery**: syntax errors → fix immediately (don't count); runtime → max 3 fix attempts then skip; timeout → revert + log; OOM → smaller variant. See `autoresearch-core-skill/references/crash-recovery.md`.
8. **Git-as-memory**: commit before each verify; auto-revert (`git reset --hard HEAD~1`) on `pass:false`.
9. **Iteration safety**: bounded-by-default (`Iterations: 25`); safety blocks `.env`, `node_modules/`, `rm -rf`, `git push --force`. See `autoresearch-core-skill/references/iteration-safety.md`.

### Skill-specific override

**TDD mapping.** RED phase → `{"pass":false,"score":0}`; GREEN phase → `{"pass":true,"score":<passing-test-count>}`. Score is the integer count of passing tests. Default `Iterations: 25` when protocol enabled. The 'metric' is passing-test-count; direction is maximize.

### Max iterations
- Default: 25 iterations
- Hard cap: 100 (explicit `Iterations: unlimited` overrides)

