---
name: python-docstring-generator
description: Implement docstring documentation for Python functions to ensure all functions have proper documentation following PEP 257 industry standards, especially for parameters and their types
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: documentation
  scope: python
  pattern: docstring-implementation
---

## What this skill does

- Adds docstrings to all Python functions and methods
- Ensures all functions with parameters have proper parameter documentation with type information
- Documents return values with `Returns:` sections
- Handles async functions, classes, and utility functions
- Maintains existing docstring style conventions in codebase (Google, NumPy, or Sphinx)
- Follows PEP 257 standards for Python code documentation
- Integrates with Python's type hints for better IDE support

## When to use

Use this when:
- Implementing new functions, classes, or utility modules in Python projects
- Refactoring code and adding missing documentation
- Preparing for code review and ensuring proper docstring standards
- Functions lack docstrings or have incomplete parameter documentation
- You need to enforce docstring presence as part of quality checks

**Common signals:**
- Python functions without docstrings
- Functions with parameters but missing parameter documentation
- Return values not documented
- Async functions without proper return type documentation
- Python code lacking type-aware documentation

## Python Docstring Standard Formats

### Google Style (Recommended for most projects)

#### Basic Function
```python
def calculate_sum(a: int, b: int) -> int:
    """Calculate the sum of two numbers.

    Args:
        a: The first number to add.
        b: The second number to add.

    Returns:
        The sum of a and b.
    """
    return a + b
```

#### Async Function
```python
async def fetch_user(user_id: str) -> User:
    """Fetch user data from API.

    Args:
        user_id: The unique identifier of user.

    Returns:
        The user data object.

    Raises:
        APIError: When the API request fails.
    """
    response = await fetch(f"/api/users/{user_id}")
    if not response.ok:
        raise APIError('Failed to fetch user')
    return response.json()
```

#### Class Method
```python
class UserProfile:
    """User profile display component.

    This class manages user profile data and display logic.

    Attributes:
        user_id: The user's unique identifier.
        on_edit: Callback when edit button is clicked.
    """

    def __init__(self, user_id: str, on_edit: Callable):
        """Initialize user profile.

        Args:
            user_id: The user's unique identifier.
            on_edit: Callback when edit button is clicked.
        """
        self.user_id = user_id
        self.on_edit = on_edit
```

#### Function with Dataclass/Dictionary Parameter
```python
from dataclasses import dataclass

@dataclass
class UpdateOptions:
    """Options for updating user profile."""
    user_id: str
    data: dict[str, Any]
    partial: bool = False

async def update_user_profile(options: UpdateOptions) -> None:
    """Update user profile with new data.

    Args:
        options: Configuration options for the update.
            user_id: The user's unique identifier.
            data: The new data to update.
            partial: Whether to perform a partial update.

    Returns:
        None
    """
    # Implementation
```

#### Function with Optional Parameters
```python
def filter_items(
    items: list[T],
    predicate: Callable[[T], bool],
    limit: int | None = None,
    reverse: bool = False
) -> list[T]:
    """Filter items based on criteria.

    Args:
        items: Array of items to filter.
        predicate: Function to test each item.
        limit: Maximum number of results.
        reverse: Whether to reverse results.

    Returns:
        Filtered list of items.
    """
    # Implementation
```

#### Function with Union Types
```python
def set_storage_value(
    key: str,
    value: str | int | dict[str, Any]
) -> None:
    """Set or update a value in storage.

    Args:
        key: The storage key.
        value: The value to store (string, number, or JSON object).

    Returns:
        None
    """
    # Implementation
```

#### Generic Function (Python 3.12+ Type Syntax)
```python
from typing import TypeVar

T = TypeVar('T')
U = TypeVar('U')

def map_items(items: list[T], mapper: Callable[[T], U]) -> list[U]:
    """Map over a list and transform each element.

    Type Parameters:
        T: The type of elements in the input list.
        U: The type of elements in the output list.

    Args:
        items: List to transform.
        mapper: Function to transform each element.

    Returns:
        Transformed list.
    """
    return [mapper(item) for item in items]
```

### NumPy Style (Common in scientific computing)

```python
def calculate_sum(a: int, b: int) -> int:
    """Calculate the sum of two numbers.

    Parameters
    ----------
    a : int
        The first number to add.
    b : int
        The second number to add.

    Returns
    -------
    int
        The sum of a and b.
    """
    return a + b
```

### Sphinx/reStructuredText Style (Common in Python documentation)

```python
def calculate_sum(a: int, b: int) -> int:
    """Calculate the sum of two numbers.

    :param a: The first number to add.
    :type a: int
    :param b: The second number to add.
    :type b: int
    :returns: The sum of a and b.
    :rtype: int
    """
    return a + b
```

## Python Docstring Implementation Rules

### Required Documentation

- **All functions** must have a docstring
- **All parameters** must be documented with:
  - Parameter name
  - Description of the parameter
  - Type information from type hints
- **All return values** must be documented with:
  - Description of what is returned
  - Return type information (leveraging type hints)
- **Async functions** must document return type clearly
- **Functions that raise exceptions** must have `Raises:` section

### Optional Documentation

- `Examples:` blocks for usage examples (recommended for public APIs)
- `See Also:` or `See:` for related functions
- `Deprecated:` for deprecated functions
- `Version:` for version information
- `Note:` for additional information
- `Attributes:` for class attributes
- `Type Parameters:` for generic type parameters

### Placement and Formatting

- Place docstring **immediately after** function/class declaration
- Use triple quotes `"""` for docstrings
- Start with a one-line summary describing the function's purpose
- Add empty line between summary and sections
- Use indentation consistently within docstring
- Document parameter types using Python type hints

### Type Handling

- **Primary preference**: Use Python type hints in function signature
- **Docstring types**: Describe complex types when not obvious from hints
- **Generic types**: Use `Type Parameters:` section or type variable documentation
- **Union types**: Document all possible types clearly in description
- **Optional parameters**: Document default values and optional nature

## PEP 257 Style Guidelines

### Google Style (Recommended)

- Use `Args:` for parameters
- Use `Returns:` for return values
- Use `Raises:` for exceptions
- Use `Attributes:` for class attributes
- Use `Yields:` for generator functions
- Use `Examples:` for code examples

### NumPy Style (Scientific Projects)

- Use `Parameters ----------` for parameters
- Use `Returns -------` for return values
- Use `Raises ------` for exceptions
- Use `Attributes -------` for class attributes

### Sphinx Style (Documentation Projects)

- Use `:param name:` for parameters
- Use `:type name:` for parameter types
- Use `:returns:` or `:return:` for return values
- Use `:rtype:` for return types
- Use `:raises:` for exceptions

## Step-by-Step Implementation

### Step 1: Identify Functions Needing Documentation

Search for Python functions without docstrings:

```bash
# Find Python functions
find src -name "*.py" -type f | while read -r file; do
  # Check for functions without docstrings
  grep -n "^\s*\(async\s\+\)\?\(def \|class \)" "$file"
done
```

### Step 2: Analyze Function Signature

Extract function parameters and return type from Python:

```python
# Function signature
def create_user(name: str, age: int, email: str | None = None) -> User:
    pass

# Parameters to document:
# - name: str
# - age: int
# - email: str | None (optional)

# Return type:
# - User

# Docstring to generate:
"""
Create a new user in the system.

Args:
    name: The user's full name.
    age: The user's age.
    email: Optional email address for contact.

Returns:
    The newly created user object.
"""
```

### Step 3: Generate Docstring

Create appropriate docstring based on function type:

```python
def create_user(name: str, age: int, email: str | None = None) -> User:
    """Create a new user in the system.

    Args:
        name: The user's full name.
        age: The user's age.
        email: Optional email address for contact.

    Returns:
        The newly created user object.
    """
    # Implementation
```

### Step 4: Insert Docstring into File

Place docstring immediately after function declaration:

```python
# Before:
async def get_posts(page: int) -> list[Post]:

# After:
async def get_posts(page: int) -> list[Post]:
    """Retrieve paginated posts from the database.

    Args:
        page: The page number to retrieve (1-indexed).

    Returns:
        A list of post objects.
    """
```

## Best Practices

### Descriptive Parameter Names

- Use descriptive parameter names in docstrings
- Match docstring parameter names to function signature exactly
- Explain what parameter represents, not just its type

**Good:**
```python
"""
Args:
    user_id: The unique identifier of user to fetch.
"""
```

**Avoid:**
```python
"""
Args:
    id: The id.
"""
```

### Clear and Concise Descriptions

- Explain purpose, not implementation
- Describe behavior for edge cases (None, empty lists, etc.)
- Mention any side effects or mutations
- Keep descriptions concise but informative

**Good:**
```python
"""Fetch user data from database.

Returns None if user is not found.

Args:
    user_id: The unique identifier of user.

Returns:
    The user data or None if not found.
"""
```

### Type Clarity with Type Hints

- Reference complex types by name when possible
- Document object structure using separate sections
- Explain union types clearly in descriptions
- Leverage Python's type hints for type information

**Good:**
```python
"""Process a payment transaction.

Args:
    transaction: Payment details including amount and payment method.

Returns:
    Promise that resolves to transaction receipt.
"""
async def process_payment(
    transaction: dict[str, Any]
) -> Receipt:
```

## Special Cases

### Class Methods

Document method parameters and return values:

```python
class TekkButton:
    """Button component for primary actions.

    This component provides styled button functionality
    with Tekk-specific behavior and styling.

    Attributes:
        variant: Visual style variant (primary, secondary, danger).
        disabled: Whether button is disabled.
    """

    def __init__(
        self,
        variant: str = 'primary',
        disabled: bool = False
    ):
        """Initialize the button component.

        Args:
            variant: Visual style variant (primary, secondary, danger).
            disabled: Whether button is disabled.
        """
        self.variant = variant
        self.disabled = disabled
```

### Generic Functions

Document type parameters:

```python
from typing import TypeVar

T = TypeVar('T')
U = TypeVar('U')

def transform_list(
    items: list[T],
    transformer: Callable[[T], U]
) -> list[U]:
    """Transform a list of items.

    Type Parameters:
        T: The input element type.
        U: The output element type.

    Args:
        items: List to transform.
        transformer: Function to transform each element.

    Returns:
        Transformed list of items.
    """
    return [transformer(item) for item in items]
```

### Utility Functions

Keep documentation concise for simple utilities:

```python
def format_date(date: datetime) -> str:
    """Format a date to ISO string.

    Args:
        date: The date to format.

    Returns:
        ISO-formatted date string.
    """
    return date.isoformat()
```

### Generator Functions

Document what is yielded:

```python
def iterate_items(items: list[T]) -> Iterator[T]:
    """Iterate over items with processing.

    Args:
        items: List of items to iterate.

    Yields:
        Processed items from the list.
    """
    for item in items:
        yield process(item)
```

### Context Managers

Document enter and exit behavior:

```python
class DatabaseConnection:
    """Database connection context manager.

    Manages database connection lifecycle automatically.

    Attributes:
        connection: The underlying database connection.
    """

    def __enter__(self):
        """Enter context and establish connection.

        Returns:
            The database connection object.
        """
        self.connection = connect()
        return self.connection

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Exit context and close connection.

        Args:
            exc_type: Exception type if raised, otherwise None.
            exc_val: Exception value if raised, otherwise None.
            exc_tb: Exception traceback if raised, otherwise None.

        Returns:
            False to propagate exceptions.
        """
        if self.connection:
            self.connection.close()
```

### Decorators

Document decorator behavior:

```python
def timing_decorator(func: Callable) -> Callable:
    """Decorator to measure and log function execution time.

    Args:
        func: The function to decorate.

    Returns:
        Wrapped function with timing logging.
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        logger.info(f"{func.__name__} took {end - start:.2f}s")
        return result
    return wrapper
```

### Internal Functions

Mark internal API functions:

```python
def _calculate_internal_hash(data: Any) -> str:
    """Calculate internal hash for caching.

    Note:
        This is an internal function not meant for public use.

    Args:
        data: Data to hash.

    Returns:
        Hash string.
    """
    # Implementation
```

## Validation Checklist

Before considering a function properly documented:

- [ ] Docstring exists after function/class declaration
- [ ] Summary line describes function purpose
- [ ] All parameters have documentation
- [ ] Parameter names match function signature exactly
- [ ] Parameter descriptions are clear and descriptive
- [ ] Return value is documented
- [ ] Return type is clear for async functions
- [ ] Exceptions are documented (if applicable)
- [ ] Complex types are described clearly
- [ ] Optional parameters are documented with default values
- [ ] Docstring follows PEP 257 formatting conventions
- [ ] Type hints are present for all parameters and return values

## Common Issues and Solutions

### Missing Parameter Documentation

**Issue:** Function has parameters but no parameter documentation.

**Solution:** Add parameter documentation for each parameter.

```python
# Before:
def calculate(a: int, b: int) -> int:
    pass

# After:
def calculate(a: int, b: int) -> int:
    """Calculate the sum of two numbers.

    Args:
        a: First number.
        b: Second number.

    Returns:
        Sum of a and b.
    """
```

### Missing Return Type Documentation

**Issue:** Async function doesn't document return type.

**Solution:** Add return type documentation.

```python
# Before:
async def fetch_data() -> Data:
    pass

# After:
async def fetch_data() -> Data:
    """Fetch data from API.

    Returns:
        The fetched data object.
    """
```

### Incorrect Parameter Name

**Issue:** Docstring parameter name doesn't match function signature.

**Solution:** Ensure names match exactly.

```python
# Before (incorrect):
"""
Args:
    name: User name.
"""
def create_user(username: str) -> User:
    pass

# After (correct):
def create_user(username: str) -> User:
    """Create a new user.

    Args:
        username: The username for the new user.
    """
```

### Complex Type Not Documented

**Issue:** Dictionary parameter structure not documented.

**Solution:** Document dictionary structure separately.

```python
# Before (unclear):
"""
Args:
    options: Configuration options.
"""
def configure(options: dict[str, Any]) -> None:
    pass

# After (clear):
def configure(options: dict[str, Any]) -> None:
    """Configure the application with specified options.

    Args:
        options: Configuration dictionary with the following keys:
            theme: Color theme (light, dark, system).
            language: Display language code.
            notifications: Enable notifications.
    """
```

### Missing Type Hints

**Issue:** Function lacks type hints.

**Solution:** Add type hints to function signature.

```python
# Before (missing types):
def create_user(name, age, email=None):
    pass

# After (with types):
def create_user(
    name: str,
    age: int,
    email: str | None = None
) -> User:
    """Create a new user.

    Args:
        name: The user's full name.
        age: The user's age.
        email: Optional email address.

    Returns:
        The newly created user object.
    """
```

## Integration with Workflows

### PR Creation Workflow

Check for missing docstrings during PR creation:

```bash
# Find functions without docstrings in changed files
for file in $(git diff --name-only HEAD~1 | grep -E '\.py$'); do
  # Check for function declarations without docstrings
  python3 -c "
import ast
import sys

with open('$file', 'r') as f:
    try:
        tree = ast.parse(f.read())
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if not ast.get_docstring(node):
                    print(f'Undocumented function: {node.name} at line {node.lineno}')
    except SyntaxError as e:
        print(f'Error parsing $file: {e}')
        sys.exit(1)
"
done
```

### Linting Integration with Ruff

Add docstring validation to Ruff configuration:

```toml
# pyproject.toml
[tool.ruff.lint]
select = [
    "D",  # pydocstyle
]

[tool.ruff.lint.pydocstyle]
convention = "google"  # Options: google, numpy, pep257
```

Common Ruff docstring rules:
- `D100`: Missing docstring in public module
- `D101`: Missing docstring in public class
- `D102`: Missing docstring in public method
- `D103`: Missing docstring in public function
- `D104`: Missing docstring in public package
- `D107`: Missing docstring in `__init__`
- `D417`: Missing argument descriptions in the docstring

### Type Checking with mypy

Use mypy to validate type hints:

```bash
# Install mypy
pip install mypy

# Run mypy to check type hints
mypy src/
```

### Documentation Generation with Sphinx

Generate API documentation from docstrings:

```bash
# Install Sphinx
pip install sphinx sphinx-rtd-theme

# Initialize Sphinx documentation
sphinx-quickstart

# Configure autodoc in conf.py
extensions = ['sphinx.ext.autodoc', 'sphinx.ext.napoleon']

# Generate HTML documentation
make html
```

