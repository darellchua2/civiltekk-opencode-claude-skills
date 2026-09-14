---
name: object-design-skill
description: Apply responsibility-driven design with object stereotypes, value objects, entities, aggregates, and encapsulation - language-agnostic
license: Apache-2.0
compatibility: opencode
category: Code Quality
---

## What I do

I help you design objects with clear responsibilities and proper encapsulation:

1. **Identify Object Stereotypes**: Classify objects as Information Holders, Structurers, Service Providers, Coordinators, Controllers, or Interfacers
2. **Design Value Objects**: Create immutable objects for domain primitives (IDs, emails, money)
3. **Design Entities**: Create objects with identity that persist through changes
4. **Apply Tell Don't Ask**: Command objects instead of interrogating them
5. **Design Aggregates**: Create clusters of objects with consistency boundaries
6. **Apply Composition over Inheritance**: Prefer composing objects over extending classes

## When to use me

Use this skill when:
- Designing new classes or modules
- Refactoring classes that have unclear responsibilities
- Creating domain models for business concepts
- Deciding between value objects and entities
- Implementing domain-driven design patterns
- Reducing coupling between objects
- Improving encapsulation and information hiding

## Prerequisites

- Understanding of object-oriented programming
- Knowledge of the business domain
- Familiarity with interfaces and abstractions
- Understanding of immutability concepts

## Responsibility-Driven Design (RDD)

The key insight: **Objects are defined by their responsibilities, not their data.**

### Finding Objects

Start with:
1. **Nouns** in requirements → candidate objects
2. **Verbs** → candidate methods/behaviors
3. **Domain concepts** → value objects

### Finding Responsibilities

Each object should answer:
- What does this object **know**?
- What does this object **do**?
- What does this object **decide**?

---

## Object Stereotypes

Every class fits one (or maybe two) stereotypes:

| Stereotype | Purpose | Example |
|------------|---------|---------|
| **Information Holder** | Knows things, holds data | `User`, `Product`, `Address` |
| **Structurer** | Maintains relationships | `OrderItems`, `UserGroup` |
| **Service Provider** | Performs work | `PaymentProcessor`, `EmailSender` |
| **Coordinator** | Orchestrates workflow | `OrderFulfillmentService` |
| **Controller** | Makes decisions, delegates | `CheckoutController` |
| **Interfacer** | Transforms between systems | `UserAPIAdapter`, `DatabaseMapper` |

### The Two Questions

For every class, ask:
1. **"What pattern is this?"** - Which stereotype? Which design pattern?
2. **"Is it doing too much?"** - Check object calisthenics rules

If you can't answer clearly, the class needs refactoring.

---

## Tell, Don't Ask

**Command objects to do work. Don't interrogate them and do the work yourself.**

```python
# BAD: Asking, then doing
if account.get_balance() >= amount:
    account.set_balance(account.get_balance() - amount)
    # more logic here...

# GOOD: Telling
result = account.withdraw(amount)
if result.is_success():
    # ...
```

The object that has the data should have the behavior.

---

## Design by Contract (DbC)

Every method has:
- **Preconditions** - What must be true BEFORE calling
- **Postconditions** - What will be true AFTER calling
- **Invariants** - What is ALWAYS true about the object

```typescript
class BankAccount {
    private balance: Money;
    
    // INVARIANT: balance is never negative
    
    // PRECONDITION: amount > 0
    // POSTCONDITION: balance decreased by amount OR error returned
    withdraw(amount: Money): WithdrawResult {
        if (amount.isNegativeOrZero()) {
            return WithdrawResult.invalidAmount();
        }
        
        if (this.balance.isLessThan(amount)) {
            return WithdrawResult.insufficientFunds();
        }
        
        this.balance = this.balance.minus(amount);
        return WithdrawResult.success(this.balance);
    }
}
```

---

## Composition Over Inheritance

**Prefer composing objects over extending classes.**

### Why Inheritance is Problematic:
- Tight coupling between parent and child
- Fragile base class problem
- Difficult to change parent without breaking children
- Forces "is-a" relationship that may not fit

### When to Use Inheritance:
- True "is-a" relationship (rare)
- Framework requirements
- Template Method pattern (intentional)

### Prefer Composition:

```python
# BAD: Inheritance
class PremiumUser(User):
    def get_discount(self) -> int:
        return 20

# GOOD: Composition
class User:
    def __init__(self, discount_policy: DiscountPolicy):
        self._discount_policy = discount_policy
    
    def get_discount(self) -> int:
        return self._discount_policy.calculate()

# Now discount behavior is pluggable
User(PremiumDiscount())    # 20%
User(StandardDiscount())   # 10%
User(NoDiscount())         # 0%
```

---

## The Law of Demeter (Principle of Least Knowledge)

**Only talk to your immediate friends.**

A method should only call:
1. Methods on `this`
2. Methods on parameters
3. Methods on objects it creates
4. Methods on its direct components

```typescript
// BAD: Reaching through objects
order.getCustomer().getAddress().getCity();

// GOOD: Ask the immediate friend
order.getShippingCity();
```

This reduces coupling - changes to `Address` don't ripple through all callers.

---

## Encapsulation

**Hide internal details, expose behavior.**

### Levels of Encapsulation:
1. **Data** - private fields, no direct access
2. **Implementation** - how things work internally
3. **Type** - concrete class hidden behind interface
4. **Design** - architectural decisions hidden from clients

```python
# BAD: Exposed internals
class Order:
    def __init__(self):
        self.items = []  # Public!
        self.total = 0   # Public!

# Client can corrupt state
order.items.append(item)
order.total = -999  # Oops!

# GOOD: Encapsulated
class Order:
    def __init__(self):
        self._items = OrderItems()  # Private
        self._total = Money(0)      # Private
    
    def add_item(self, item: Item):
        self._items.add(item)
        self._recalculate_total()
    
    def get_total(self) -> Money:
        return self._total  # Returns copy or immutable
```

---

## Value Objects vs Entities

### Value Objects
- Defined by their attributes (no identity)
- Immutable
- Comparable by value
- Examples: `Money`, `Email`, `Address`, `DateRange`

```python
from dataclasses import dataclass
from decimal import Decimal

@dataclass(frozen=True)  # Immutable
class Money:
    amount: Decimal
    currency: str
    
    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Money cannot be negative")
    
    def add(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount + other.amount, self.currency)
    
    def equals(self, other: 'Money') -> bool:
        return self.amount == other.amount and self.currency == other.currency
```

### Entities
- Have identity (survives attribute changes)
- Usually mutable (via methods)
- Comparable by identity
- Examples: `User`, `Order`, `Product`

```python
@dataclass
class User:
    id: UserId          # Identity - never changes
    email: Email        # Can change
    name: Name          # Can change
    
    def __eq__(self, other):
        if not isinstance(other, User):
            return False
        return self.id == other.id  # Identity comparison
    
    def change_email(self, new_email: Email):
        # Still same user, just different email
        self.email = new_email
```

### When to Use Which?

| Value Object | Entity |
|--------------|--------|
| No identity needed | Identity matters |
| Immutable | Mutable state |
| Compared by value | Compared by identity |
| Small, focused | Can be complex |
| `Money`, `Email`, `Address` | `User`, `Order`, `Product` |

#### Learning: `primitive-obsession-report-type`

Raw `String` used for `reportType` across API layer, service layer, and domain layer provides zero compile-time safety. A typo like `"pfd"` silently passes through. Replace with an enum value object.

```python
# BAD: raw string, no safety
def generate_report(report_type: str, data: dict):
    if report_type == "pdf":
        return PDFGenerator().render(data)
    elif report_type == "html":
        return HTMLGenerator().render(data)
    # "pfd" silently falls through

def schedule_report(report_type: str, cron: str):
    db.execute("INSERT INTO jobs (report_type, cron) VALUES (?, ?)", report_type, cron)

# GOOD: enum value object, compile-time safety
from enum import Enum

class ReportType(str, Enum):
    PDF = "pdf"
    HTML = "html"
    CSV = "csv"

def generate_report(report_type: ReportType, data: dict):
    generator = _GENERATORS[report_type]
    return generator.render(data)

def schedule_report(report_type: ReportType, cron: str):
    db.execute("INSERT INTO jobs (report_type, cron) VALUES (?, ?)", report_type.value, cron)

# schedule_report("pfd", "* * * * *")  -> TypeError from ReportType("pfd")
```

#### Learning: `enum-strategy-resolution`

An enum can serve as both a type identifier (value object) and a strategy dispatcher. Each enum member knows its own strategy, eliminating external mapping.

```python
from enum import Enum

class OutputFormat(str, Enum):
    JSON = "json"
    CSV = "csv"
    XML = "xml"

    @property
    def content_type(self) -> str:
        return _CONTENT_TYPES[self]

    @property
    def extension(self) -> str:
        return self.value

    def serialize(self, data: dict) -> bytes:
        serializer = _SERIALIZERS[self]
        return serializer(data)

_CONTENT_TYPES = {
    OutputFormat.JSON: "application/json",
    OutputFormat.CSV:  "text/csv",
    OutputFormat.XML:  "application/xml",
}

_SERIALIZERS = {
    OutputFormat.JSON: lambda d: json.dumps(d, indent=2).encode(),
    OutputFormat.CSV:  lambda d: _to_csv(d).encode(),
    OutputFormat.XML:  lambda d: _to_xml(d).encode(),
}

# Usage — the enum IS the strategy
fmt = OutputFormat.JSON
response = Response(content=fmt.serialize(data), content_type=fmt.content_type)
filename = f"report.{fmt.extension}"
```

---

## Aggregates

A cluster of objects treated as a single unit for data changes.

- One object is the **aggregate root** (entry point)
- External code only references the root
- Root enforces invariants for the entire cluster

```python
# Order is the aggregate root
class Order:
    def __init__(self, order_id: OrderId):
        self._id = order_id
        self._items: list[OrderItem] = []
        self._status = OrderStatus.PENDING
    
    # All access through the root
    def add_item(self, product: Product, quantity: int):
        item = OrderItem(product, quantity)
        self._items.append(item)
        self._validate_total()
    
    def remove_item(self, item_id: ItemId):
        self._items = [i for i in self._items if i.id != item_id]
    
    # Root enforces invariants
    def _validate_total(self):
        if self._calculate_total() > Money(MAX_ORDER_VALUE):
            raise OrderTotalExceeded()
    
    def _calculate_total(self) -> Money:
        return sum(item.total for item in self._items)

# BAD: Accessing items directly
order.items.append(new_item)  # Bypasses validation!

# GOOD: Through the root
order.add_item(product, 2)  # Validation happens
```

### Aggregate Rules

1. **Only the root has global identity**
2. **Objects inside can only be accessed through the root**
3. **Root enforces invariants for the whole aggregate**
4. **Only the root can be loaded from the repository**

---

## First-Class Collections

Any class with a collection should have no other instance variables.

```typescript
// BAD: Collection mixed with other state
class Order {
    items: Item[] = [];
    customerId: string;
    total: number;
}

// GOOD: Collection is its own class
class OrderItems {
    constructor(private items: Item[] = []) {}
    
    add(item: Item): void {
        if (this.isFull()) {
            throw new Error("Order is full");
        }
        this.items.push(item);
    }
    
    total(): Money {
        return this.items.reduce((sum, item) => sum.add(item.price), Money.zero());
    }
    
    isEmpty(): boolean {
        return this.items.length === 0;
    }
    
    private isFull(): boolean {
        return this.items.length >= MAX_ITEMS;
    }
}

class Order {
    constructor(
        private items: OrderItems,
        private customerId: CustomerId
    ) {}
}
```

---

## Steps

### Step 1: Identify Object Stereotype

1. Read the class and describe its responsibility
2. Match to one of the six stereotypes
3. If it matches multiple, consider splitting

### Step 2: Define Responsibilities

1. What does it know? (data)
2. What does it do? (behavior)
3. What does it decide? (logic)

### Step 3: Apply Tell Don't Ask

1. Find getters followed by logic
2. Move the logic into the object
3. Change to command methods

### Step 4: Check Encapsulation

1. Are all fields private?
2. Are invariants enforced?
3. Can state be corrupted from outside?

### Step 5: Choose Value Object vs Entity

1. Does it need identity?
2. Is it immutable?
3. How is it compared?

---

## Best Practices

- **One stereotype per class** - If multiple, split
- **Tell, don't ask** - Behavior, not data exposure
- **Prefer composition** - More flexible than inheritance
- **Wrap primitives** - Value objects for domain concepts
- **Enforce invariants** - In constructors and methods
- **Design by contract** - Document pre/post conditions

---

## Common Issues

### Anemic Domain Model

**Issue:** Classes with only data, no behavior

**Solution:**
- Move logic from services into domain objects
- Apply Tell Don't Ask
- Add behavior methods

### Primitive Obsession

**Issue:** Using primitives for domain concepts

**Solution:**
- Wrap in value objects
- Add validation to constructors
- Use value objects in signatures

### Leaky Encapsulation

**Issue:** Internal state exposed through getters

**Solution:**
- Replace getters with behavior methods
- Return copies or immutable versions
- Use Tell Don't Ask

---

## Verification Commands

After designing objects:

```bash
# Check for getters (potential encapsulation issues)
grep -r "def get_\|public.*get " src/ --include="*.py"

# Check for public fields
grep -r "public [a-z]" src/ --include="*.ts"

# Find primitive types in signatures
grep -r "def .*(str, int\|string, number" src/ --include="*.py"
```

**Object Design Verification Checklist:**
- [ ] Each class has a clear stereotype
- [ ] Behavior is inside objects, not services
- [ ] Tell Don't Ask is applied
- [ ] Value objects for domain primitives
- [ ] Entities have identity
- [ ] Aggregates enforce invariants
- [ ] Encapsulation is maintained
- [ ] Composition preferred over inheritance
