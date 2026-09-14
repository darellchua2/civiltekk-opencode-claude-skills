---
name: clean-architecture-skill
description: Apply clean architecture principles with vertical slicing, dependency rule, clear layer boundaries, and feature-first organization - language-agnostic
license: Apache-2.0
compatibility: opencode
category: Code Quality
---

## What I do

I help you design and organize software architecture for maintainability and testability:

1. **Establish Layer Boundaries**: Separate code into Presentation, Application, Domain, and Infrastructure layers
2. **Apply Dependency Rule**: Ensure dependencies point inward toward domain logic
3. **Organize by Feature**: Structure code using vertical slicing (feature-first organization)
4. **Design Contracts**: Define clear interfaces between components
5. **Handle Cross-Cutting Concerns**: Manage logging, auth, validation across features
6. **Create Walking Skeletons**: Start with minimal end-to-end slices that prove the architecture

## When to use me

Use this skill when:
- Starting a new project and need to structure the codebase
- Refactoring a "big ball of mud" into organized layers
- Planning how to separate business logic from infrastructure
- Designing microservices or bounded contexts
- Setting up testing strategy with proper isolation
- Onboarding developers who need to understand the codebase structure
- Evaluating existing architecture for improvement opportunities

## Prerequisites

- Understanding of basic software architecture concepts
- Knowledge of dependency injection
- Familiarity with interfaces and abstractions
- Clear understanding of the business domain

## The Goal of Architecture

Enable the development team to:
1. **Add** features with minimal friction
2. **Change** existing features safely
3. **Remove** features cleanly
4. **Test** features in isolation
5. **Deploy** independently when possible

---

## Architectural Principles

### 1. Vertical Boundaries (Features/Slices)

Organize by **feature**, not by technical layer.

```
BAD: Layer-first organization
src/
  controllers/
    UserController
    OrderController
  services/
    UserService
    OrderService
  repositories/
    UserRepository
    OrderRepository

GOOD: Feature-first organization
src/
  users/
    UserController
    UserService
    UserRepository
    User
  orders/
    OrderController
    OrderService
    OrderRepository
    Order
```

**Why:** Changes to "users" feature stay in `users/`. High cohesion within features.

### 2. Horizontal Boundaries (Layers)

Separate concerns into layers with clear dependencies.

```
┌──────────────────────────────────────┐
│           Presentation               │  UI, Controllers, CLI
├──────────────────────────────────────┤
│           Application                │  Use Cases, Orchestration
├──────────────────────────────────────┤
│             Domain                   │  Business Logic, Entities
├──────────────────────────────────────┤
│          Infrastructure              │  Database, APIs, External
└──────────────────────────────────────┘
```

### 3. The Dependency Rule

**Dependencies point INWARD.**

```
Infrastructure → Application → Domain
      ↓               ↓            ↓
   (outer)        (middle)      (inner)
```

- Inner layers know NOTHING about outer layers
- Domain has zero dependencies on infrastructure
- Use interfaces to invert dependencies

**Language-Agnostic Example:**

```python
# Domain defines the interface (inner)
class UserRepository(ABC):
    @abstractmethod
    def save(self, user: User) -> None: ...
    
    @abstractmethod
    def find_by_id(self, id: UserId) -> Optional[User]: ...

# Infrastructure implements it (outer)
class PostgresUserRepository(UserRepository):
    def save(self, user: User) -> None:
        # SQL implementation
        
    def find_by_id(self, id: UserId) -> Optional[User]:
        # SQL implementation

# Domain service uses the interface
class UserService:
    def __init__(self, repo: UserRepository):
        self._repo = repo  # Depends on abstraction
```

### 4. Contracts

Interfaces define boundaries between components.

```typescript
// The contract
interface PaymentGateway {
    charge(amount: Money, card: CardDetails): Promise<ChargeResult>;
    refund(chargeId: string): Promise<RefundResult>;
}

// Multiple implementations possible
class StripeGateway implements PaymentGateway { }
class PayPalGateway implements PaymentGateway { }
class MockGateway implements PaymentGateway { }  // For tests
```

### Learning: `doc-claimed-purity-vs-reality`

A layer rule documented as "the domain layer is pure and has no I/O" but violated by more than 10 call sites is a false contract. Either the rule is wrong for this codebase, or it is unenforced. Leaving the doc and the code in disagreement trains every new developer to ignore BOTH — the next rule they see, they assume is aspirational too. If violations exceed a threshold (10 is a reasonable heuristic), either enforce the boundary with a tool (ESLint `no-restricted-imports`, `eslint-plugin-import` boundaries, dependency-cruiser, or `madge` in CI) OR update the doc to describe what the code actually does. Do not let docs and code drift.

```typescript
// PROBLEM: doc says "domain is pure" but 14 domain files import the DB
// src/domain/order/aggregate.ts
import { PrismaClient } from '@prisma/client'   // violation #14
// ... 13 more like it ...

// OPTION A — enforce the rule in CI (preferred when the rule is correct)
// .eslintrc.js
module.exports = {
  rules: {
    'no-restricted-imports': ['error', {
      patterns: [
        { group: ['@prisma/client', 'pg', 'redis'], message: 'Domain layer must be pure — no I/O imports' }
      ],
      paths: [
        { name: '@prisma/client', message: 'Move to infrastructure/' }
      ]
    }]
  },
  overrides: [{
    files: ['src/domain/**'],
    rules: { 'no-restricted-imports': 'error' }
  }]
}

// OPTION B — update the doc to match reality
// "The domain layer MAY import read-side query helpers from infrastructure
//  via the QueryPort interface (see ADR-009). Direct PrismaClient imports
//  are still prohibited; route through QueryPort implementations."
```

**Detection:**

```bash
# count violations of a documented layer rule
rg "from '@prisma/client'|from 'pg'|import.*prisma" src/domain/ --type ts -l | wc -l
npx madge --circular --extensions ts src/domain/
```

**Rule:** A layer rule with >10 violations is a false contract. Either enforce it with tooling (`no-restricted-imports`, madge, dependency-cruiser) or rewrite the doc to match reality. Never let architecture docs and code drift — the drift itself becomes the de facto standard.

### 5. Cross-Cutting Concerns

Concerns that span multiple features: logging, auth, validation, error handling.

**Options:**
- Middleware/interceptors
- Decorators
- Aspect-oriented approaches
- Base classes (use sparingly)

```python
# Middleware approach
class LoggingMiddleware:
    def handle(self, request, next_handler):
        print(f"Request: {request.path}")
        response = next_handler(request)
        print(f"Response: {response.status}")
        return response
```

---

## Common Architectural Styles

### Layered Architecture

Traditional layers: Presentation → Business → Persistence

**Pros:** Simple, well-understood
**Cons:** Can become a "big ball of mud" without discipline

### Hexagonal Architecture (Ports & Adapters)

Domain at center, adapters around the edges.

```
        ┌─────────────────────┐
        │     HTTP Adapter    │
        └─────────┬───────────┘
                  │
┌─────────────────▼─────────────────┐
│              DOMAIN                │
│   ┌─────────────────────────┐     │
│   │      Business Logic      │     │
│   │      Use Cases           │     │
│   └─────────────────────────┘     │
└─────────────────┬─────────────────┘
                  │
        ┌─────────▼───────────┐
        │   Database Adapter   │
        └─────────────────────┘
```

**Ports:** Interfaces defined by the domain
**Adapters:** Implementations that connect to the outside world

### Clean Architecture

Similar to Hexagonal, with explicit layers:

1. **Entities** - Enterprise business rules
2. **Use Cases** - Application business rules
3. **Interface Adapters** - Controllers, Presenters, Gateways
4. **Frameworks & Drivers** - Web, DB, External interfaces

---

## Feature-Driven Structure

### Frontend Structure

```
src/
  features/
    auth/
      components/
        LoginForm.tsx
        SignupForm.tsx
      hooks/
        useAuth.ts
      services/
        authService.ts
      types/
        auth.types.ts
      index.ts  # Public API
    checkout/
      components/
      hooks/
      services/
      types/
      index.ts
  shared/
    components/  # Truly shared UI
    hooks/       # Truly shared hooks
    utils/       # Truly shared utilities
```

### Learning: `cross-container-hook-borrowing`

A feature container (`features/reports/_containers/ReportList/index.tsx`) must NEVER import from a sibling container via a relative path (`../../_containers/ReportDetail/useReportDetail`). Relative cross-container imports create invisible coupling: refactoring `ReportDetail` silently breaks `ReportList`, the dependency graph hides the edge, and moving one container forces the other to follow. If a hook is genuinely needed by two containers, extract it to the feature's `hooks/` directory (for intra-feature reuse) or to `domains/{feature}/hooks/` (for cross-feature reuse). Containers import ONLY from `@/`-aliased shared locations or from their own feature's `hooks/`.

```typescript
// BAD — sibling container imported via relative path; invisible coupling
// features/reports/_containers/ReportList/index.tsx
import { useReportDetail } from '../../_containers/ReportDetail/useReportDetail'
// refactoring ReportDetail's folder structure silently breaks ReportList

// GOOD — extract the shared hook to the feature's hooks directory
// features/reports/hooks/useReportDetail.ts  ← extracted
import { useReportDetail } from '@/features/reports/hooks/useReportDetail'
// or for cross-feature reuse: src/domains/reports/hooks/useReportDetail.ts
```

**Detection:**

```bash
# find relative imports crossing container boundaries
rg "from\s+['\"](\.\./)+.*_containers" --type ts --type tsx
rg "from\s+['\"](\.\./)+.*(use|hook)" --type ts --type tsx -g '*_containers/*'
```

**Rule:** Containers import only from `@/`-aliased shared locations or their own feature's `hooks/`. If you need a sibling container's hook, extract it to `hooks/` or `domains/{feature}/hooks/` first. Never reach across container boundaries with relative imports.

### Backend Structure

```
src/
  modules/
    users/
      domain/
        User.ts
        UserRepository.ts  # Interface
      application/
        CreateUser.ts      # Use case
        GetUser.ts         # Use case
      infrastructure/
        PostgresUserRepo.ts
      presentation/
        UserController.ts
        UserDTO.ts
    orders/
      domain/
      application/
      infrastructure/
      presentation/
  shared/
    domain/        # Shared value objects
    infrastructure/ # Shared infra utilities
```

---

## The Walking Skeleton

Start with a minimal end-to-end slice:

1. **Thinnest possible feature** that touches all layers
2. **Deployable** from day one
3. **Proves the architecture** works

**Example Walking Skeleton for E-commerce:**
- User can view ONE product (hardcoded)
- User can add it to cart
- User can "checkout" (just logs)

From there, flesh out each feature fully.

---

## Testing Architecture

```
┌────────────────────────────────────────────┐
│            E2E / Acceptance Tests          │  Few, slow, high confidence
├────────────────────────────────────────────┤
│            Integration Tests               │  Some, medium speed
├────────────────────────────────────────────┤
│              Unit Tests                    │  Many, fast, isolated
└────────────────────────────────────────────┘
```

**Test by Layer:**
- **Domain:** Unit tests (most tests here)
- **Application:** Integration tests with mocked infrastructure
- **Infrastructure:** Integration tests with real dependencies
- **E2E:** Critical paths only

---

## Architecture Decision Records (ADRs)

Document significant decisions:

```markdown
# ADR 001: Use PostgreSQL for Persistence

## Status
Accepted

## Context
We need a database. Options: PostgreSQL, MongoDB, MySQL

## Decision
PostgreSQL for:
- ACID compliance
- Team familiarity
- JSON support for flexibility

## Consequences
- Need PostgreSQL expertise
- Schema migrations required
- Excellent query capabilities
```

---

## Steps

### Step 1: Analyze Current Structure

1. Map current code organization
2. Identify layer boundaries (or lack thereof)
3. Check dependency directions
4. Find coupling hotspots

### Step 2: Define Target Architecture

1. Choose architectural style (Layered, Hexagonal, Clean)
2. Define layer boundaries
3. Establish naming conventions
4. Create dependency rules

### Step 3: Create Walking Skeleton

1. Implement thinnest possible feature
2. Touch all layers end-to-end
3. Verify testability
4. Validate deployment pipeline

### Step 4: Organize by Feature

1. Group related code together
2. Create feature directories
3. Establish public APIs per feature
4. Minimize cross-feature dependencies

### Step 5: Enforce Dependency Rule

1. Create interfaces in inner layers
2. Implement in outer layers
3. Use dependency injection
4. Add architecture tests

---

## Best Practices

### Layer Communication

- Inner layers define interfaces
- Outer layers implement interfaces
- Communication through abstractions
- Minimize layer crossing

### Feature Organization

- High cohesion within features
- Low coupling between features
- Shared code is truly shared
- Clear public APIs

### Testing Strategy

- Domain: Pure unit tests
- Application: Mock infrastructure
- Infrastructure: Real dependencies
- E2E: Critical paths only

---

## Common Issues

### Circular Dependencies

**Issue:** Modules depend on each other

**Solution:**
- Extract shared code to separate module
- Use interfaces to break cycles
- Apply dependency inversion

### Domain Knowing About Infrastructure

**Issue:** Business logic imports database types

**Solution:**
- Define interfaces in domain
- Implement in infrastructure
- Use dependency injection

### "Utils" Package Growing Forever

**Issue:** Shared utilities becoming a dumping ground

**Solution:**
- Question if code is truly shared
- Move to feature if only used there
- Create focused utility modules

---

## Red Flags in Architecture

- **Circular dependencies** between modules
- **Domain depending on infrastructure**
- **Framework code in business logic**
- **No clear boundaries** between features
- **Shared mutable state** across modules
- **"Util" or "Common" packages** that grow forever
- **Database schema driving domain model**

---

## Verification Commands

After restructuring:

```bash
# Check for circular dependencies (Python)
pip install pydeps && pydeps src --no-output -T png

# Check dependency direction (TypeScript)
npx madge --circular src/

# Verify layer isolation
grep -r "from.*infrastructure" src/domain/  # Should be empty
grep -r "import.*database" src/domain/      # Should be empty
```

**Architecture Verification Checklist:**
- [ ] Dependencies point inward
- [ ] Domain has no infrastructure dependencies
- [ ] Each feature is self-contained
- [ ] Clear public APIs per feature
- [ ] Cross-cutting concerns handled uniformly
- [ ] Tests can run in isolation
- [ ] Walking skeleton works end-to-end
