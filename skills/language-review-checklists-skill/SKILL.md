---
name: language-review-checklists-skill
description: >-
  Language-specific code review checklists — Python, TypeScript/JS, Go,
  Rust, Java: idioms, type safety, concurrency, error handling, security,
  testing, framework tables, consumer-coverage grep patterns. Loaded by
  reviewer subagents. Triggers: python review checklist, typescript review
  checklist, go review checklist, rust review checklist, java review
  checklist.
license: Apache-2.0
compatibility: opencode
metadata:
  pattern: checklist
category: Code Quality
---

Knowledge extracted from `language-reviewer-subagent` (kept in sync with the
agent's Language Detection & Scope table). Apply only the sections matching
the detected language(s); for multi-language changesets apply each and report
per-language.

## Python Review Checklist

1. PEP 8 & Style
   - Line length <= 88 (black default) or 79 (PEP 8 strict)?
   - Naming: snake_case for functions/variables, PascalCase for classes, UPPER_SNAKE for constants
   - Imports: stdlib → third-party → local, no wildcard imports
   - Docstrings present for public functions/classes (PEP 257)?

2. Type Hints
   - Function signatures have type annotations?
   - Return types specified?
   - `Optional[T]` used instead of `T | None` for Python <3.10?
   - `typing.Protocol` for structural typing over ABC where appropriate?
   - Pydantic models for API boundaries?

3. Pythonic Patterns
   - List/dict/set comprehensions over loops where appropriate?
   - Context managers (`with`) for resources?
   - Generator expressions for large data (`yield`)?
   - `dataclasses` or `attrs` instead of manual `__init__`?
   - `pathlib.Path` instead of `os.path`?
   - f-strings instead of `.format()` or `%`?

4. Error Handling
   - Specific exceptions, not bare `except:` or `except Exception:`
   - Custom exception hierarchy for the project?
   - `try/except/else/finally` used correctly?
   - No silent catches (empty `except` blocks)?

5. Security
   - No `eval()`, `exec()`, or `__import__()` with user input?
   - SQL parameterization (not string formatting)?
   - No hardcoded secrets or credentials?
   - Input validation at API boundaries?
   - `pickle.loads()` avoided for untrusted data?

6. Async & Concurrency
   - `asyncio` patterns correct (no blocking calls in async functions)?
   - `async with` for async resources?
   - Proper task cancellation and cleanup?
   - Thread safety for shared state?

7. Testing
   - pytest conventions followed?
   - Fixtures used appropriately (not over-mocked)?
   - Parametrized tests for edge cases?
   - Test isolation (no shared mutable state)?

### Python Framework-Specific Checks

| Framework | Key Patterns to Check |
|-----------|----------------------|
| **FastAPI** | Dependency injection, Pydantic models, async handlers, proper status codes |
| **Django** | ORM efficiency (select_related/prefetch_related), middleware, view patterns |
| **Flask** | Blueprint organization, proper app factory, request context |
| **SQLAlchemy** | Session management, relationship loading, migration compatibility |

**Backend Patterns**: use `python-backend-skill` + `fastapi-pydantic-orm-patterns-skill` for SQLAlchemy detached-instance bugs, Pydantic-on-JSONB pitfalls, async SSE durability, enum strategy resolution, two-phase dataclass initialization, and `global _service` singletons (prefer FastAPI `Depends()` with `app.state` lifecycle).

## TypeScript/JavaScript Review Checklist

1. Type Safety
   - No `any` types (use `unknown` if truly unknown)?
   - Proper generic constraints?
   - Discriminated unions for state modeling?
   - `readonly` for immutable data?
   - Proper `null`/`undefined` handling (optional chaining, nullish coalescing)?
   - Type guards and narrowing correct?

2. Modern ES Patterns
   - `const` over `let`, `let` over `var`?
   - Arrow functions for callbacks?
   - Destructuring where appropriate?
   - Template literals instead of string concatenation?
   - `async/await` over raw promises?
   - ES modules (`import/export`) over CommonJS?

3. React / Next.js (if applicable)
   - Component naming: PascalCase?
   - Hooks rules followed (no conditional hooks)?
   - Proper `useMemo`/`useCallback` (not overused, not missing)?
   - Server vs Client Components correctly separated?
   - Key props on lists (stable, unique)?
   - No prop drilling beyond 2 levels (use context or state management)?

4. Error Handling
   - Proper error boundaries in React?
   - try/catch around async operations?
   - Error types specific (not generic `Error`)?
   - Proper error propagation in async chains?

5. Security
   - No `eval()`, `Function()`, or `innerHTML` with user input?
   - XSS prevention (proper escaping/sanitization)?
   - No hardcoded API keys or secrets?
   - CORS configured correctly?
   - Input validation with Zod/schemas at API boundaries?

6. Performance
   - Bundle size awareness (no unnecessary imports)?
   - Lazy loading where applicable?
   - Proper memoization strategy?
   - No unnecessary re-renders in React?
   - Efficient data fetching patterns (SWR, React Query)?

7. Testing
   - Jest/Vitest conventions followed?
   - Testing Library patterns (user-centric queries)?
   - Mock usage appropriate (not over-mocked)?
   - Async test patterns correct?

### TypeScript/JavaScript Framework-Specific Checks

| Framework | Key Patterns to Check |
|-----------|----------------------|
| **Next.js** (verify current major version) | App Router patterns, Server Actions, metadata API, proper `"use client"` directives |
| **React** (verify current major version) | Server Components, Suspense boundaries, use() hook, transition patterns |
| **Node.js** | Stream handling, proper error events, graceful shutdown, no synchronous I/O |
| **Express/Fastify** | Middleware ordering, error handling middleware, request validation |

**React Anti-Pattern**: `react-hooks-antipatterns-skill` (hooks) + `react-render-antipatterns-skill` (render). **TypeScript DRY**: `typescript-dry-principle-skill`.

## Go Review Checklist

1. Go Idioms
   - Proper package naming (lowercase, single word, no underscores)?
   - `gofmt` compliant formatting?
   - Exported names have doc comments?
   - Receiver names consistent within a type (not mixing `s` and `self`)?
   - Error messages lowercase, no trailing punctuation?
   - `go vet` clean?

2. Error Handling
   - Explicit error checking (no `_ = someFunc()`)?
   - Errors wrapped with context (`fmt.Errorf("doing X: %w", err)`)?
   - Custom error types for sentinel errors (`errors.Is`/`errors.As`)?
   - No `panic` in library code (only in `main`/tests)?

3. Concurrency
   - Goroutines properly managed (no leaked goroutines)?
   - Channels vs mutexes chosen correctly?
   - `sync.WaitGroup` used for goroutine coordination?
   - `context.Context` passed as first parameter?
   - No shared mutable state without synchronization?
   - `select` with proper default/cancel handling?

4. Interfaces
   - Small, focused interfaces (1-2 methods)?
   - Interfaces defined by consumer, not producer?
   - Implicit satisfaction (no `var _ Interface = (*Type)(nil)`)?
   - `io.Reader`/`io.Writer` patterns followed?

5. Data Structures
   - Slices pre-allocated when size known (`make([]T, 0, n)`)?
   - Maps with proper concurrency protection if shared?
   - Structs organized by field size (alignment)?
   - Proper use of value vs pointer receivers?

6. Testing
   - Table-driven tests with `t.Run` subtests?
   - Test files in same package (`_test` suffix)?
   - Benchmark tests (`BenchmarkXxx`) for hot paths?
   - `t.Parallel()` where safe?
   - Test helpers use `t.Helper()`?

7. Performance
   - No unnecessary allocations in hot paths?
   - `strings.Builder` for string concatenation?
   - `sync.Pool` for reusable allocations?
   - Proper use of `copy()` for slice operations?
   - Buffered I/O where appropriate?

### Go Framework-Specific Checks

| Framework | Key Patterns to Check |
|-----------|----------------------|
| **net/http** | Handler signatures, proper response writing, context usage, middleware pattern |
| **Gin/Echo** | Route grouping, middleware ordering, proper error handling middleware |
| **gRPC** | Proto file conventions, streaming patterns, interceptors, error codes |
| **Cobra** | Command structure, flag handling, proper help text |

## Rust Review Checklist

1. Ownership & Borrowing
   - Borrow checker satisfied without excessive cloning?
   - Lifetimes annotated where needed, elided where possible?
   - No unnecessary `Arc<Mutex<T>>` when `Rc<RefCell<T>>` suffices (single-threaded)?
   - Proper use of `Cow<str>` for borrowed/owned string flexibility?
   - `Rc`/`Arc` cycles avoided (no `Rc<RefCell>` circular references)?

2. Error Handling
   - `Result<T, E>` used instead of panics for recoverable errors?
   - `thiserror`/`anyhow` used appropriately (thiserror for libraries, anyhow for apps)?
   - Error types implement `std::error::Error`?
   - `?` operator used instead of `match` on Result?
   - No `unwrap()` or `expect()` in library code (only in tests/main)?

3. Unsafe Safety
   - `unsafe` blocks minimized and clearly documented with safety invariants?
   - Raw pointer dereferences justified?
   - No undefined behavior (aliasing violations, uninitialized memory)?
   - `unsafe` blocks reviewed with extra scrutiny?

4. Idiomatic Patterns
   - Builder pattern for complex construction?
   - `From`/`Into` traits for conversions?
   - `Iterator` trait implemented for custom iterators?
   - `newtype` pattern for domain primitives?
   - `Deref`/`DerefMut` not abused (only for smart pointers)?
   - Proper trait object (`dyn`) vs generics trade-off?

5. Concurrency
   - `Send`/`Sync` bounds respected?
   - Proper channel usage (`mpsc`, `crossbeam`)?
   - `tokio`/`async-std` patterns correct (no blocking in async)?
   - `parking_lot` vs `std::sync` chosen appropriately?
   - Lock ordering consistent to prevent deadlocks?

6. Performance
   - Zero-cost abstractions used (generics, enums, traits)?
   - No unnecessary heap allocations (`String` vs `&str`, `Vec` vs slice)?
   - `#[inline]` only where benchmarks justify?
   - Proper use of `Cow` to avoid allocations?
   - Stack allocation preferred where possible?

7. Testing
   - `#[test]` unit tests present?
   - `#[tokio::test]` for async tests?
   - Property-based testing (`proptest`) for complex logic?
   - Integration tests in `tests/` directory?
   - Doc tests for public API examples?

### Rust Framework-Specific Checks

| Framework | Key Patterns to Check |
|-----------|----------------------|
| **Tokio** | Runtime configuration, task spawning, proper `async`/`await`, channel patterns |
| **Axum** | Handler signatures, extractor usage, middleware with layers, state management |
| **Actix** | Actor patterns, message handling, supervisor strategy |
| **Clap** | Command-line argument parsing, derive vs builder patterns |

## Java Review Checklist

1. Java Idioms
   - Effective Java compliance (Bloch's items respected)?
   - Naming: camelCase for methods/variables, PascalCase for classes/interfaces, UPPER_SNAKE for constants?
   - Package names lowercase, no underscores, reverse-DNS style?
   - `final` used for effectively-final locals, parameters, and fields where appropriate?
   - `equals`/`hashCode`/`toString` overridden together (or none)?
   - Checkstyle/SpotBugs clean?

2. Exceptions
   - Checked vs unchecked chosen correctly (checked for recoverable, unchecked for programmer errors)?
   - No swallowed exceptions (empty `catch` blocks)?
   - Custom exception hierarchy follows `RuntimeException` base for most modern code?
   - Exceptions chained (`new X("msg", cause)`) rather than losing the cause?
   - try-with-resources used for all `AutoCloseable`?
   - No `catch (Exception e)` or `catch (Throwable t)` over-broad catches?

3. Generics & Types
   - No raw types (`List` instead of `List<String>`)?
   - Generic bounds used correctly (`<T extends Comparable<T>>`)?
   - PECS principle applied (`<? extends T>` for producers, `<? super T>` for consumers)?
   - Diamond operator `<>` used for instantiation?
   - Generic methods favored over `Object` + casts?

4. Concurrency
   - `java.util.concurrent` primitives preferred over `synchronized`/`wait`/`notify`?
   - Proper synchronization of shared mutable state (no data races)?
   - `volatile` used only for visibility flags, not atomicity?
   - `Atomic*` classes for atomic counters/references?
   - `CompletableFuture` composed correctly (no blocking joins in async chains)?
   - `ExecutorService` shut down properly (try-with-resources or `shutdown()` in `finally`)?
   - No shared mutable state across threads without synchronization?

5. Null Handling
   - `Optional<T>` used as return type for methods that may not return a value (never as field/parameter)?
   - `Objects.requireNonNull` on constructor/method parameters?
   - Null-annotations (`@NonNull`, `@Nullable`) consistent (JSR-305, JSpecify, or Spring)?
   - No `Optional.get()` without `isPresent()` check?
   - Stream pipelines null-safe (no `null` in streams)?

6. Modern Java (11+/17+/21)
   - `record` for transparent data carriers (vs manual POJO with getters/equals/hashCode)?
   - `sealed` classes/interfaces used to restrict subtypes?
   - Pattern matching for `instanceof` (`if (o instanceof Foo f)`)?
   - Switch expressions with arrow syntax and exhaustiveness (esp. with sealed types)?
   - Text blocks (`"""..."""`) for multi-line strings?
   - `var` used only where type is obvious from initializer (not for "shorter code")?

7. Streams & Collections
   - Stream chains single-purpose and side-effect-free?
   - `.collect(Collectors.toList())` produces mutable copy (or `.toUnmodifiableList()` for immutable)?
   - `EnumSet`/`EnumMap` chosen for enum-keyed collections?
   - `List.of()`/`Map.of()` for immutable literals (not `Collections.unmodifiableList`)?
   - No mutation of collection elements inside `forEach`?
   - No `.stream()` used purely for iteration (use enhanced `for` loop)?

8. Resource Management
   - try-with-resources for all `Closeable`/`AutoCloseable` (streams, connections, files)?
   - No `finalizer` methods (`finalize()`) — deprecated for removal (JEP 421, Java 18+) but NOT yet removed; verify current status before asserting removal.
   - `Cleaner` used only as last resort for native resources?
   - I/O streams properly chained and closed in correct order?
   - Connection pools (`HikariCP`) used for database access (not raw `DriverManager`)?

9. Testing
   - JUnit 5 conventions followed (`@Test`, `@BeforeEach`/`@AfterEach`, `@ParameterizedTest`)?
   - Mockito patterns clean (no over-mocking; prefer interface mocks over concrete)?
   - AssertJ fluent assertions used (`assertThat(x).isEqualTo(y)`) over JUnit `assertEquals`?
   - Test isolation (no shared mutable state across tests)?
   - Test names follow a convention (`methodName_state_expected` or `should_X_when_Y`)?
   - No production code reaching into test internals via reflection?

10. Security
    - Input validation at API boundaries (Bean Validation `@Valid`, manual checks)?
    - SQL via `PreparedStatement`/JPA named queries — never string concatenation?
    - No `Runtime.exec()` or `ProcessBuilder` with user-controlled input?
    - No hardcoded secrets, API keys, or passwords (use env vars / secret managers)?
    - XML parsing hardened against XXE (`XMLConstants.FEATURE_SECURE_PROCESSING`)?
    - Deserialization of untrusted input avoided (no `ObjectInputStream` on untrusted data)?

### Java Framework-Specific Checks

| Framework | Key Patterns to Check |
|-----------|----------------------|
| **Spring Boot** | `@Transactional` boundaries correct (not on private methods), `@RestController` signatures, `@ControllerAdvice` exception handlers, DI via constructors (not `@Autowired` on fields), proper `@RequestMapping` paths and HTTP methods, `@Service`/`@Repository` stereotypes used, configuration properties validated |
| **Quarkus** | CDI vs Spring DI (no `@Autowired`), native image compatibility (no runtime reflection), `@Blocking`/`@NonBlocking` on reactive paths, `@ConfigProperty` usage, Panache repository patterns |
| **Micronaut** | Compile-time DI (no reflection), `@Singleton` vs `@Context` scope, AOP via `@Around`, proper HTTP filters, no `@Inject` on private fields (compile-time constraints) |
| **Jakarta EE** | CDI scopes correct (`@RequestScoped`, `@SessionScoped`, `@ApplicationScoped`), JPA session management (no `LazyInitializationException`), EJB patterns (`@Stateless` vs `@Singleton`), Bean Validation on JAX-RS endpoints, proper `persistence.xml` config |

**Java Linting**: `language-linting-skill` for Checkstyle/SpotBugs/PMD command guidance and rule references.

## Consumer-Coverage Grep Patterns (no CodeGraph)

Fallback enumeration patterns for the direct-consumer gate, per language:

### Python
- Imports: `grep -rn 'from\s\+<module>\s\+import\|import\s\+<module>' --include="*.py"`
- Symbol usage: `grep -rn '\b<SymbolName>\b' --include="*.py"`
- Subclass overrides: `grep -rn 'class\s\+\w+\s*(.*<BaseClassName>' --include="*.py"`
- Decorator usage: `grep -rn '@<decorator>' --include="*.py"`

### TypeScript/JavaScript
- Imports: `grep -rn 'import\s\+.*from\s\+[''"]\./.*<module>' --include="*.ts" --include="*.tsx"`
- Type references: `grep -rn ':\s*<TypeName>' --include="*.ts" --include="*.tsx"`
- Component usage: `grep -rn '<ComponentName' --include="*.tsx" --include="*.jsx"`
- Hook usage: `grep -rn '<hookName>\(' --include="*.ts" --include="*.tsx"`

### Go
- Imported packages: `grep -rn '"<pkg/path>"' --include="*.go"`
- Symbol usage: `grep -rn '\b<SymbolName>\b' --include="*.go"`
- Interface implementations: `grep -rn 'func\s.*(.*).*<InterfaceName>' --include="*.go"`

### Rust
- Use statements: `grep -rn 'use\s\+crate::<path>::<Symbol>' --include="*.rs"`
- Symbol usage: `grep -rn '\b<SymbolName>\b' --include="*.rs"`
- Trait implementations: `grep -rn 'impl\s\+<TraitName>\s\+for' --include="*.rs"`
- Macro invocations: `grep -rn '<macro_name>!' --include="*.rs"`

### Java
- Imports: `grep -rn 'import\s\+.*\.<ClassName>;' --include="*.java"`
- Method calls: `grep -rn '\.<methodName>(' --include="*.java"`
- Implementations: `grep -rn 'implements\s\+.*<InterfaceName>' --include="*.java"`
- Subclasses: `grep -rn 'extends\s\+<BaseClassName>' --include="*.java"`
