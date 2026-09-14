---
name: complexity-management-skill
description: Manage software complexity by minimizing accidental complexity and clearly expressing essential complexity through KISS, YAGNI, DRY principles
license: Apache-2.0
compatibility: opencode
category: Code Quality
---

## What I do

I help you manage software complexity to build maintainable systems:

1. **Identify Complexity Types**: Distinguish between essential and accidental complexity
2. **Detect Complexity Hotspots**: Find change amplification, cognitive load, and unknown unknowns
3. **Apply Reduction Strategies**: Use KISS, YAGNI, DRY, and separation of concerns
4. **Manage Technical Debt**: Know when to pay down debt and when to leave it
5. **Apply Simple Design**: Follow the four elements of simple design from XP
6. **Prevent Complexity Growth**: Apply the Boy Scout rule and continuous refactoring

## When to use me

Use this skill when:
- Code feels harder to change than it should be
- Small changes require touching many files
- You need to hold too much in your head to understand code
- Changes have surprising side effects
- Planning a refactoring effort
- Evaluating architecture for complexity issues
- Teaching developers about complexity management
- Setting up coding standards to prevent complexity

## Prerequisites

- Code to analyze
- Understanding of basic software design
- Willingness to simplify and refactor
- Authority to make changes (or ability to recommend)

## The Two Types of Complexity

### Essential Complexity
Inherent to the problem domain. Cannot be removed, only managed.
- Business rules
- Domain logic
- User requirements

### Accidental Complexity
Introduced by our solutions. CAN and SHOULD be minimized.
- Poor abstractions
- Unnecessary indirection
- Framework ceremony
- Technical debt

**Goal: Minimize accidental complexity while clearly expressing essential complexity.**

---

## Detecting Complexity

### 1. Change Amplification

**Symptom:** Small changes require touching many files.

**Detection Question:** "To add this field, I need to update how many files?"

**Example:**
```
"To add a 'nickname' field to User, I need to update:
- User entity
- UserDTO
- UserRepository
- UserService
- UserController
- User tests (5 files)
- Database migration
- Frontend components (3 files)
- API documentation"

→ This is change amplification. Good design: 1-3 files.
```

**Causes:**
- Scattered responsibilities
- Poor abstraction boundaries
- Copy-paste code

### 2. Cognitive Load

**Symptom:** Code is hard to understand, requires holding too much in memory.

**Detection Question:** "How many other classes do I need to understand to understand this one?"

**Example:**
```
To understand OrderService, you need to know:
- UserService
- InventoryService
- PaymentGateway
- EmailService
- SMSService
- LoggingService
- CachingService
- MetricsService

→ This is high cognitive load. Good design: 2-3 dependencies.
```

**Causes:**
- Tight coupling
- Hidden dependencies
- Unclear naming
- Missing documentation

### 3. Unknown Unknowns

**Symptom:** Behavior is surprising, side effects are hidden.

**Detection Question:** "What broke when I changed this unrelated thing?"

**Example:**
```
Changed: Tax calculation rounding
Broke: Monthly report generation (surprise!)

The tax rounding change affected the report because:
- Report directly queried tax calculations
- No clear interface between them
- Implicit coupling through shared data

→ This is unknown unknowns. Good design: Changes are predictable.
```

**Causes:**
- Global state
- Hidden dependencies
- Implicit contracts
- Side effects

---

## The XP Values for Fighting Complexity

From Extreme Programming:

### 1. Communication
Code should communicate clearly. Names, structure, tests all contribute.

### 2. Simplicity
Do the simplest thing that could possibly work.

### 3. Feedback
Fast feedback loops catch complexity early. TDD, CI, code review.

### 4. Courage
Refactor aggressively. Don't let complexity accumulate.

### 5. Respect
Respect future readers (including yourself). Write for humans first.

---

## KISS - Keep It Simple, Silly

> "The simplest solution that works is usually the best."

### How to Apply:
1. Start with the obvious solution
2. Only add complexity when REQUIRED
3. Prefer boring, well-understood approaches
4. Question every abstraction

**Language-Agnostic Example:**

```python
# Over-engineered
class UserServiceFactoryProvider:
    _instance = None
    
    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = UserServiceFactoryProvider()
        return cls._instance
    
    def create_factory(self):
        return UserServiceFactory()

class UserServiceFactory:
    def create(self):
        return UserService()

# KISS
class UserService:
    def get_user(self, user_id):
        ...
```

---

## YAGNI - You Aren't Gonna Need It

> "Don't build features until they're actually needed."

### Warning Signs:
- "We might need this later"
- "It would be nice to have"
- "Just in case"
- "For future extensibility"

### The Cost of YAGNI Violations:
1. **Development time** - Building unused features
2. **Maintenance burden** - Code that must be maintained
3. **Cognitive load** - More to understand
4. **Wrong abstraction** - Guessing future needs incorrectly

**Example:**

```python
# YAGNI violation: Building for hypothetical needs
class User:
    def __init__(self):
        self.name = None
        self.email = None
        # "We might need these someday"
        self.middle_name = None
        self.secondary_email = None
        self.fax_number = None
        self.linkedin_profile = None
        self.twitter_handle = None

# YAGNI: Only what's needed NOW
class User:
    def __init__(self, name: str, email: Email):
        self.name = name
        self.email = email
```

---

## DRY - Don't Repeat Yourself (with The Rule of Three)

> "Every piece of knowledge should have a single, unambiguous representation."

### BUT: The Rule of Three

**Don't extract duplication until you see it THREE times.**

Why? The wrong abstraction is worse than duplication.

```
Duplication #1 → Leave it
Duplication #2 → Note it, leave it
Duplication #3 → NOW extract it
```

**Example:**

```python
# First time - leave it
def process_user_order(order):
    validate(order)
    calculate_tax(order)
    save(order)

# Second time - note the similarity, but leave it
def process_guest_order(order):
    validate(order)
    calculate_tax(order)
    save(order)
    send_guest_email(order)

# Third time - NOW extract
def process_corporate_order(order):
    validate(order)
    calculate_tax(order)
    save(order)
    apply_corporate_discount(order)

# After three occurrences, extract the common parts
def process_order(order, post_processing):
    validate(order)
    calculate_tax(order)
    save(order)
    post_processing(order)
```

---

## Separation of Concerns

> "Each module should address a single concern."

### Concerns to Separate:
- **Business logic** vs **Infrastructure**
- **What** (policy) vs **How** (mechanism)
- **Input** vs **Processing** vs **Output**
- **Data** vs **Behavior**

**Example:**

```python
# BAD: Mixed concerns
class OrderProcessor:
    def process(self, order):
        # Validation
        if not order.items:
            raise ValueError('Empty')
        
        # Business logic
        total = sum(item.price * item.quantity for item in order.items)
        
        # Persistence
        db = Database()
        db.query("INSERT INTO orders...")
        
        # Notification
        email = EmailClient()
        email.send(order.customer.email, 'Order confirmed')

# GOOD: Separated concerns
class OrderProcessor:
    def __init__(self, validator, calculator, repository, notifier):
        self._validator = validator
        self._calculator = calculator
        self._repository = repository
        self._notifier = notifier
    
    def process(self, order):
        self._validator.validate(order)
        total = self._calculator.calculate_total(order)
        saved = self._repository.save(order)
        self._notifier.notify_confirmation(saved)
        return ProcessResult.success(saved)
```

---

## Managing Technical Debt

### Types of Technical Debt:
1. **Deliberate** - Conscious trade-off for speed
2. **Accidental** - Mistakes, lack of knowledge
3. **Bit rot** - Code degrades over time

### The Boy Scout Rule:
> "Leave the code better than you found it."

Every time you touch code:
- Improve one small thing
- Fix one naming issue
- Extract one method
- Add one missing test

### When to Pay Down Debt:
- When it's in your path (you're already there)
- When it's blocking new features
- When it's causing bugs
- During dedicated refactoring time

### When NOT to Refactor:
- Code that works and won't change
- Code being replaced soon
- When you don't have tests

---

## The Four Elements of Simple Design

In priority order (from XP):

### 1. Runs All the Tests
- If it doesn't work, nothing else matters
- Tests verify behavior
- Tests enable refactoring

### 2. Expresses Intent
- Clear names, obvious structure
- Code tells the story
- Self-documenting

### 3. No Duplication
- DRY (but Rule of Three)
- Single source of truth
- Don't repeat knowledge

### 4. Minimal
- Fewest classes and methods possible
- Remove anything unnecessary
- No speculative generality

**If these four are true, the design is simple enough.**

---

## Steps

### Step 1: Detect Complexity Hotspots

1. Identify files that change frequently together
2. Find code that requires long explanations
3. Look for surprising side effects
4. Ask: "What makes this hard to change?"

### Step 2: Classify Complexity

1. Is it essential (domain) or accidental (solution)?
2. What type? (change amplification, cognitive load, unknown unknowns)
3. What's the impact? (high, medium, low)
4. What's the fix difficulty? (easy, medium, hard)

### Step 3: Apply Reduction Strategies

1. **For change amplification:** Co-locate related code
2. **For cognitive load:** Simplify interfaces, extract methods
3. **For unknown unknowns:** Add tests, explicit interfaces

### Step 4: Verify Improvement

1. Is the code easier to change?
2. Is it easier to understand?
3. Are side effects more predictable?
4. Do tests still pass?

---

## Best Practices

### Complexity Prevention

- **Start simple** - Add complexity only when needed
- **Refactor continuously** - Don't let debt accumulate
- **Write tests** - Tests catch complexity early
- **Review code** - Fresh eyes catch complexity
- **Document decisions** - ADRs for architecture

### Code Organization

- **High cohesion** - Related code together
- **Low coupling** - Minimize dependencies
- **Clear boundaries** - Interfaces between modules
- **Small modules** - Each does one thing

---

## Common Issues

### Over-Simplification

**Issue:** Removing too much, making code harder to work with

**Solution:**
- Essential complexity is necessary
- Don't remove domain logic
- Keep tests passing

### Paralysis by Analysis

**Issue:** Afraid to make any change due to complexity

**Solution:**
- Start with small improvements
- Add tests for safety
- Refactor incrementally

### Gold Plating

**Issue:** Adding unnecessary "improvements"

**Solution:**
- Follow YAGNI
- Fix what hurts
- Don't speculate on needs

---

## Verification Commands

After reducing complexity:

```bash
# Check coupling (Python)
grep -r "import " src/ | sort | uniq -c | sort -rn | head -20

# Check file sizes (large files = high complexity)
find src -name "*.py" -exec wc -l {} \; | sort -rn | head -10

# Check cyclomatic complexity
radon cc src/ -a

# Check for code duplication
npx jscpd src/
```

**Complexity Verification Checklist:**
- [ ] Essential complexity is clear (domain logic)
- [ ] Accidental complexity minimized
- [ ] Change amplification reduced
- [ ] Cognitive load reduced
- [ ] Unknown unknowns eliminated
- [ ] Four elements of simple design satisfied
- [ ] Tests still pass
- [ ] Code is easier to change
