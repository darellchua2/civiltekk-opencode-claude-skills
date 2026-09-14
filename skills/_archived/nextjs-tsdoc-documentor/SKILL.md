---
name: nextjs-tsdoc-documentor
description: Implement TSDoc documentation for TypeScript functions in Next.js projects to ensure all functions have proper documentation following TSDoc industry standards, especially for parameters and their types
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: documentation
  scope: nextjs-typescript
  pattern: tsdoc-implementation
---

## What this skill does

- Adds TSDoc comments to all TypeScript functions in Next.js projects
- Ensures all functions with parameters have proper `@param` tags with type information
- Documents return values with `@returns` tags
- Handles async functions, React components, and utility functions
- Maintains existing TSDoc style conventions in the codebase
- Follows TSDoc standards for TypeScript code documentation
- Integrates with TypeScript's type system for better IDE support

## When to use

Use this when:
- Implementing new functions, components, or utility modules in Next.js TypeScript projects
- Refactoring code and adding missing documentation
- Preparing for code review and ensuring proper TSDoc documentation standards
- Functions lack TSDoc comments or have incomplete parameter documentation
- You need to enforce TSDoc presence as part of quality checks

**Common signals:**
- TypeScript functions without TSDoc comments
- Functions with parameters but missing `@param` tags
- Return values not documented with `@returns`
- Async functions without proper `@returns Promise<T>` documentation
- TypeScript code lacking type-aware documentation

## TSDoc Standard Format

### Basic Function
```typescript
/**
 * Calculate the sum of two numbers.
 *
 * @param a - The first number to add
 * @param b - The second number to add
 * @returns The sum of a and b
 */
function calculateSum(a: number, b: number): number {
  return a + b;
}
```

### Async Function
```typescript
/**
 * Fetch user data from the API.
 *
 * @param userId - The unique identifier of user
 * @returns A promise that resolves to the user data
 * @throws When the API request fails
 */
async function fetchUser(userId: string): Promise<User> {
  const response = await fetch(`/api/users/${userId}`);
  if (!response.ok) {
    throw new Error('Failed to fetch user');
  }
  return response.json();
}
```

### React Component
```typescript
/**
 * UserProfile component displays user information.
 *
 * @param props - Component properties
 * @param props.userId - The user's unique identifier
 * @param props.onEdit - Callback when edit button is clicked
 * @returns A React component rendering user profile
 */
export function UserProfile({ userId, onEdit }: UserProfileProps) {
  // Component implementation
}
```

### Function with Object Parameter
```typescript
/**
 * Update user profile with new data.
 *
 * @param options - Configuration options for the update
 * @param options.userId - The user's unique identifier
 * @param options.data - The new data to update
 * @param options.partial - Whether to perform partial update
 * @returns A promise that resolves when update completes
 */
async function updateUserProfile(options: {
  userId: string;
  data: Partial<User>;
  partial?: boolean;
}): Promise<void> {
  // Implementation
}
```

### Function with Optional Parameters
```typescript
/**
 * Filter items based on criteria.
 *
 * @param items - Array of items to filter
 * @param predicate - Function to test each item
 * @param options - Optional configuration
 * @param options.limit - Maximum number of results
 * @param options.reverse - Whether to reverse results
 * @returns Filtered array of items
 */
function filterItems<T>(
  items: T[],
  predicate: (item: T) => boolean,
  options?: { limit?: number; reverse?: boolean }
): T[] {
  // Implementation
}
```

### Function with Union Types
```typescript
/**
 * Set or update a value in storage.
 *
 * @param key - The storage key
 * @param value - The value to store (string, number, or JSON object)
 * @returns A promise that resolves when value is stored
 */
function setStorageValue(
  key: string,
  value: string | number | Record<string, unknown>
): Promise<void> {
  // Implementation
}
```

### Server Action (Next.js App Router)
```typescript
/**
 * Create a new project in the database.
 *
 * @param formData - Form data containing project details
 * @param formData.get - Function to get form values
 * @returns ServerActionResult with created project or error
 */
export async function createProjectAction(
  formData: FormData
): Promise<ServerActionResult<Project>> {
  // Implementation
}
```

### Generic Function
```typescript
/**
 * Map over an array and transform each element.
 *
 * @template T - The type of elements in the input array
 * @template U - The type of elements in the output array
 * @param items - Array to transform
 * @param mapper - Function to transform each element
 * @returns Transformed array
 */
function mapItems<T, U>(
  items: T[],
  mapper: (item: T) => U
): U[] {
  return items.map(mapper);
}
```

## TSDoc Implementation Rules

### Required Documentation

- **All functions** must have a TSDoc comment block
- **All parameters** must have `@param` tags with:
  - Parameter name (using dot notation for object properties)
  - Description of the parameter
  - Type information derived from TypeScript annotations
- **All return values** must have `@returns` tags with:
  - Description of what is returned
  - Return type information (leveraging TypeScript types)
- **Async functions** must document the `Promise<T>` return type
- **Functions that throw** must have `@throws` tags

### Optional Documentation

- `@example` blocks for usage examples (recommended for public APIs)
- `@see` tags for related functions
- `@deprecated` tags for deprecated functions
- `@since` tags for version information
- `@remarks` for additional information
- `@internal` for internal-only functions

### Placement and Formatting

- Place TSDoc immediately **before** the function declaration
- Use `/** */` for multi-line comments (not `/* */` or `///`)
- Start with a one-line summary describing the function's purpose
- Add empty line between summary and tags section
- Use dash `-` after parameter name in `@param` tags
- Use descriptive names for parameters in `@param` tags
- Document object properties using dot notation (e.g., `@param options.userId`)

### Type Handling

- **Primary preference**: Use TypeScript type annotations in function signature
- **TSDoc types**: Describe complex types in comments when not obvious from TypeScript
- **Generic types**: Use `@template` tags for generic type parameters
- **Union types**: Document all possible types clearly in the description
- **Optional parameters**: Document as optional in the description

## TSDoc vs JSDoc Key Differences

- **TSDoc focuses on TypeScript integration**: Leverages the type system
- **@template tags**: Used for generic type parameters
- **@remarks**: Preferred over extended descriptions for additional notes
- **@see**: Better integration with TypeScript's type system
- **Type inference**: TSDoc tools can often infer types from TypeScript signatures
- **@internal**: Tag for internal API that shouldn't be part of public API surface

## Step-by-Step Implementation

### Step 1: Identify Functions Needing Documentation

Search for TypeScript functions without TSDoc:

```bash
# Find TypeScript functions
find src -name "*.ts" -o -name "*.tsx" | while read file; do
  # Check for functions without preceding TSDoc
  grep -n "^\s*\(async\s\+\)\?\(function\|export\s\+function\|export\s+const\s+\w+\s*=\s*\(\s*(\s*\w+.*\)\s*=>\|async\s*(\s*\w+.*\)\s*=>\)" "$file"
done
```

### Step 2: Analyze Function Signature

Extract function parameters and return type from TypeScript:

```typescript
// Function signature
function createUser(name: string, age: number, email?: string): User

// Parameters to document:
// - name: string
// - age: number
// - email?: string (optional)

// Return type:
// - User

// TSDoc to generate:
/**
 * Create a new user in the system.
 *
 * @param name - The user's full name
 * @param age - The user's age
 * @param email - Optional email address for contact
 * @returns The newly created user object
 */
```

### Step 3: Generate TSDoc Comment

Create appropriate TSDoc based on function type:

```typescript
/**
 * Create a new user in the system.
 *
 * @param name - The user's full name
 * @param age - The user's age
 * @param email - Optional email address for contact
 * @returns The newly created user object
 */
function createUser(name: string, age: number, email?: string): User
```

### Step 4: Insert TSDoc into File

Place TSDoc immediately before the function declaration:

```typescript
// Before:
export async function getPosts(page: number): Promise<Post[]>

// After:
/**
 * Retrieve paginated posts from the database.
 *
 * @param page - The page number to retrieve (1-indexed)
 * @returns A promise that resolves to an array of posts
 */
export async function getPosts(page: number): Promise<Post[]>
```

## Best Practices

### Descriptive Parameter Names

- Use descriptive parameter names in TSDoc
- Match TSDoc parameter names to function signature exactly
- Explain what the parameter represents, not just its type

**Good:**
```typescript
/**
 * @param userId - The unique identifier of the user to fetch
 */
```

**Avoid:**
```typescript
/**
 * @param id - The id
 */
```

### Clear and Concise Descriptions

- Explain the purpose, not the implementation
- Describe behavior for edge cases (null, undefined, empty)
- Mention any side effects or mutations
- Keep descriptions concise but informative

**Good:**
```typescript
/**
 * Fetch user data from the database.
 * Returns null if user is not found.
 *
 * @param userId - The unique identifier of user
 * @returns The user data or null if not found
 */
```

### Type Clarity with TypeScript Integration

- Reference complex types by name when possible
- Document object structure using dot notation
- Explain union types clearly in descriptions
- Leverage TypeScript's type system for type information

**Good:**
```typescript
/**
 * Process a payment transaction.
 *
 * @param transaction - Payment details including amount and payment method
 * @returns Promise that resolves to transaction receipt
 */
async function processPayment(
  transaction: { amount: number; method: 'card' | 'paypal' }
): Promise<Receipt>
```

## Special Cases

### React Components

Document component props and return value:

```typescript
/**
 * Button component for primary actions.
 *
 * @param props - Component props
 * @param props.children - Button label or content
 * @param props.onClick - Click event handler
 * @param props.variant - Visual style variant (primary, secondary, danger)
 * @param props.disabled - Whether button is disabled
 * @returns A button element with TekkButton styling
 */
export function TekkButton({
  children,
  onClick,
  variant = 'primary',
  disabled = false,
}: TekkButtonProps) {
  // Implementation
}
```

### Generic Functions

Use `@template` tags for generic parameters:

```typescript
/**
 * Transform an array of items.
 *
 * @template T - Input type
 * @template U - Output type
 * @param items - Array to transform
 * @param transformer - Function to transform each item
 * @returns Transformed array
 */
function transformArray<T, U>(
  items: T[],
  transformer: (item: T) => U
): U[] {
  return items.map(transformer);
}
```

### Utility Functions

Keep documentation concise for simple utilities:

```typescript
/**
 * Format a date to ISO string.
 *
 * @param date - The date to format
 * @returns ISO-formatted date string
 */
function formatDate(date: Date): string {
  return date.toISOString();
}
```

### Event Handlers

Document event types and handler signatures:

```typescript
/**
 * Handle form submission.
 *
 * @param event - The submit event from the form
 * @param event.preventDefault - Prevent default form submission
 * @returns Promise that resolves when submission completes
 */
async function handleSubmit(event: React.FormEvent<HTMLFormElement>): Promise<void> {
  event.preventDefault();
  // Handle submission
}
```

### Server Actions

Document both input and return types clearly:

```typescript
/**
 * Delete a project from the database.
 *
 * @param projectId - The unique identifier of project to delete
 * @returns ServerActionResult indicating success or failure
 */
export async function deleteProjectAction(
  projectId: string
): Promise<ServerActionResult<void>> {
  // Implementation
}
```

### Internal Functions

Mark internal API functions:

```typescript
/**
 * Calculate internal hash for caching.
 *
 * @internal
 * @param data - Data to hash
 * @returns Hash string
 */
function calculateInternalHash(data: unknown): string {
  // Implementation
}
```

## Validation Checklist

Before considering a function properly documented:

- [ ] TSDoc comment exists before function
- [ ] Summary line describes function purpose
- [ ] All parameters have `@param` tags
- [ ] Parameter names match function signature exactly
- [ ] Parameter descriptions are clear and descriptive
- [ ] Return value has `@returns` tag
- [ ] Return type is documented for async functions (`Promise<T>`)
- [ ] Generic functions have `@template` tags
- [ ] Exceptions have `@throws` tags (if applicable)
- [ ] Complex types are described clearly
- [ ] Optional parameters are described as optional
- [ ] TSDoc follows TSDoc formatting conventions

## Common Issues and Solutions

### Missing Parameter Documentation

**Issue:** Function has parameters but no `@param` tags

**Solution:** Add `@param` tags for each parameter

```typescript
// Before:
function calculate(a: number, b: number) { }

// After:
/**
 * Calculate the sum of two numbers.
 *
 * @param a - First number
 * @param b - Second number
 * @returns Sum of a and b
 */
function calculate(a: number, b: number) { }
```

### Missing Return Type Documentation

**Issue:** Async function doesn't document `Promise<T>`

**Solution:** Add `@returns Promise<T>` tag

```typescript
// Before:
async function fetchData() { }

// After:
/**
 * Fetch data from the API.
 *
 * @returns Promise that resolves to fetched data
 */
async function fetchData(): Promise<Data> { }
```

### Incorrect Parameter Name

**Issue:** TSDoc parameter name doesn't match function signature

**Solution:** Ensure names match exactly

```typescript
// Before (incorrect):
/**
 * @param name - User name
 */
function createUser(username: string) { }

// After (correct):
/**
 * @param username - The username for the new user
 */
function createUser(username: string) { }
```

### Complex Type Not Documented

**Issue:** Object parameter structure not documented

**Solution:** Document using dot notation

```typescript
// Before (unclear):
/**
 * @param options - Options
 */
function configure(options: Options) { }

// After (clear):
/**
 * Configure the application with specified options.
 *
 * @param options - Configuration object
 * @param options.theme - Color theme (light, dark, system)
 * @param options.language - Display language code
 * @param options.notifications - Enable notifications
 */
function configure(options: {
  theme: 'light' | 'dark' | 'system';
  language: string;
  notifications: boolean;
}) { }
```

### Missing Template Tags for Generics

**Issue:** Generic function doesn't document type parameters

**Solution:** Add `@template` tags

```typescript
// Before (missing templates):
/**
 * Transform items.
 *
 * @param items - Items to transform
 * @param mapper - Mapping function
 * @returns Transformed items
 */
function transform<T, U>(items: T[], mapper: (item: T) => U): U[] { }

// After (with templates):
/**
 * Transform items.
 *
 * @template T - Input type
 * @template U - Output type
 * @param items - Items to transform
 * @param mapper - Mapping function
 * @returns Transformed items
 */
function transform<T, U>(items: T[], mapper: (item: T) => U): U[] { }
```

## Integration with Workflows

### PR Creation Workflow

Check for missing TSDoc during PR creation:

```bash
# Find functions without TSDoc in changed files
for file in $(git diff --name-only HEAD~1 | grep -E '\.(ts|tsx)$'); do
  # Check for function declarations without preceding TSDoc
  if grep -B 1 "function\|export.*=" "$file" | grep -q "^[^-]"; then
    echo "Potential undocumented function in $file"
  fi
done
```

### Linting Integration

Add TSDoc validation to ESLint with TypeScript support:

```json
{
  "rules": {
    "jsdoc/require-jsdoc": "error",
    "jsdoc/require-param": "error",
    "jsdoc/require-param-description": "error",
    "jsdoc/require-returns": "error",
    "jsdoc/require-returns-description": "error",
    "jsdoc/require-template": "error"
  }
}
```

### TypeScript API Extractor

Use API Extractor to validate TSDoc:

```bash
# Install API Extractor
npm install --save-dev @microsoft/api-extractor

# Run API Extractor to validate TSDoc
npx api-extractor run
```

