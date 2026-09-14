---
name: design-patterns-skill
description: Apply GoF design patterns (Creational, Structural, Behavioral) appropriately without over-engineering - language-agnostic with practical examples
license: Apache-2.0
compatibility: opencode
category: Code Quality
---

## What I do

I help you identify and apply appropriate design patterns:

1. **Pattern Recognition**: Identify when a design pattern is the right solution
2. **Prevent Over-Engineering**: Avoid forcing patterns where they don't belong
3. **Apply Creational Patterns**: Singleton, Factory, Builder, Prototype
4. **Apply Structural Patterns**: Adapter, Decorator, Proxy, Composite
5. **Apply Behavioral Patterns**: Strategy, Observer, Template Method, Command
6. **Refactor to Patterns**: Let patterns emerge from refactoring, not upfront design

## When to use me

Use this skill when:
- You have a design problem and wonder if a pattern applies
- Code has repeated type-checking or switch statements
- You need to add behavior without modifying existing code
- Objects need to be created with complex configuration
- Multiple objects need to be treated uniformly
- You're tempted to add a pattern but unsure if it's needed

**Do NOT use this skill when:**
- You want to add patterns "just in case"
- The simple solution works fine
- You're designing before you have a real problem

## Prerequisites

- Understanding of object-oriented programming
- Knowledge of interfaces and abstractions
- Familiarity with basic refactoring techniques
- A real design problem to solve (not hypothetical)

## What Are Design Patterns?

Reusable solutions to common design problems. A shared vocabulary for discussing design.

## WARNING: Don't Force Patterns

> "Let patterns emerge from refactoring, don't force them upfront."

Patterns should solve problems you **HAVE**, not problems you **MIGHT** have.

## When to Use Patterns

1. **You recognize the problem** - You've seen it before
2. **The pattern fits** - Not forcing it
3. **It simplifies** - Doesn't add unnecessary complexity
4. **Team understands it** - Shared knowledge

---

## Creational Patterns

### Singleton

**Purpose:** Ensure only one instance exists.

**When to use:** Global configuration, connection pools, logging.

**Warning:** Often overused. Consider dependency injection instead.

```python
class Logger:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def log(self, message: str):
        print(message)

# Usage
logger1 = Logger()
logger2 = Logger()
assert logger1 is logger2  # Same instance
```

### Factory

**Purpose:** Create objects without specifying exact class.

**When to use:** Object creation logic is complex, or varies by type.

```typescript
interface Notification {
    send(message: string): void;
}

class EmailNotification implements Notification {
    send(message: string) { /* email logic */ }
}

class SMSNotification implements Notification {
    send(message: string) { /* sms logic */ }
}

class NotificationFactory {
    create(type: 'email' | 'sms'): Notification {
        switch (type) {
            case 'email': return new EmailNotification();
            case 'sms': return new SMSNotification();
        }
    }
}

// Usage
const factory = new NotificationFactory();
const notification = factory.create('email');
notification.send('Hello!');
```

### Builder

**Purpose:** Construct complex objects step by step.

**When to use:** Objects with many optional parameters, test data creation.

```python
class User:
    def __init__(self, name, email, age=None, phone=None, address=None):
        self.name = name
        self.email = email
        self.age = age
        self.phone = phone
        self.address = address

class UserBuilder:
    def __init__(self, name, email):
        self._name = name
        self._email = email
        self._age = None
        self._phone = None
        self._address = None
    
    def with_age(self, age):
        self._age = age
        return self
    
    def with_phone(self, phone):
        self._phone = phone
        return self
    
    def with_address(self, address):
        self._address = address
        return self
    
    def build(self):
        return User(
            name=self._name,
            email=self._email,
            age=self._age,
            phone=self._phone,
            address=self._address
        )

# Usage
user = UserBuilder('Alice', 'alice@example.com')\
    .with_age(30)\
    .with_phone('555-1234')\
    .build()
```

### Prototype

**Purpose:** Create new objects by cloning existing ones.

**When to use:** Object creation is expensive, or you need copies with slight variations.

```typescript
interface Prototype {
    clone(): Prototype;
}

class Document implements Prototype {
    constructor(
        public title: string,
        public content: string,
        public metadata: Record<string, any>
    ) {}
    
    clone(): Document {
        return new Document(
            this.title,
            this.content,
            { ...this.metadata }  // Shallow copy
        );
    }
}

// Usage
const template = new Document('Template', 'Content', { author: 'System' });
const copy = template.clone();
copy.title = 'My Document';
```

---

## Structural Patterns

### Adapter

**Purpose:** Make incompatible interfaces work together.

**When to use:** Integrating third-party libraries, legacy code.

```python
# Third-party library with different interface
class OldPaymentAPI:
    def make_payment(self, cents: int) -> bool:
        # Legacy implementation
        pass

# Our interface
class PaymentGateway(ABC):
    @abstractmethod
    def charge(self, amount: Money) -> ChargeResult: ...

# Adapter
class OldPaymentAdapter(PaymentGateway):
    def __init__(self, old_api: OldPaymentAPI):
        self._old_api = old_api
    
    def charge(self, amount: Money) -> ChargeResult:
        cents = amount.to_cents()
        success = self._old_api.make_payment(cents)
        return ChargeResult.success() if success else ChargeResult.failed()
```

#### Learning: `zai-client-class`

Instead of per-endpoint adapters, wrap all API endpoints in a single client class that handles key resolution, base URL configuration, and error mapping centrally. This is a combined Adapter + Facade pattern.

```python
import os

class ZaiClient:
    def __init__(self):
        self.base_url = os.getenv("ZAI_API_URL", "https://api.zai.dev/v1")
        self._api_key = os.getenv("ZAI_API_KEY")
        if not self._api_key:
            raise RuntimeError("ZAI_API_KEY environment variable is required")

    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self._api_key}", "Content-Type": "application/json"}

    def _request(self, method: str, path: str, **kwargs) -> dict:
        response = requests.request(method, f"{self.base_url}{path}", headers=self._headers(), **kwargs)
        if response.status_code >= 400:
            raise ZaiApiError(response.status_code, response.json().get("error", "Unknown error"))
        return response.json()

    def search(self, query: str) -> list[dict]:
        return self._request("GET", "/search", params={"q": query})

    def summarize(self, url: str) -> dict:
        return self._request("POST", "/summarize", json={"url": url})

    def analyze(self, text: str) -> dict:
        return self._request("POST", "/analyze", json={"text": text})
```

### Decorator

**Purpose:** Add behavior to objects dynamically.

**When to use:** Adding features without modifying existing code.

```typescript
interface Notifier {
    send(message: string): void;
}

class EmailNotifier implements Notifier {
    send(message: string) {
        console.log(`Email: ${message}`);
    }
}

// Decorators
class SMSDecorator implements Notifier {
    constructor(private wrapped: Notifier) {}
    
    send(message: string) {
        this.wrapped.send(message);
        console.log(`SMS: ${message}`);
    }
}

class SlackDecorator implements Notifier {
    constructor(private wrapped: Notifier) {}
    
    send(message: string) {
        this.wrapped.send(message);
        console.log(`Slack: ${message}`);
    }
}

// Usage - compose behaviors
const notifier = new SlackDecorator(
    new SMSDecorator(
        new EmailNotifier()
    )
);
notifier.send('Alert!');  // Sends to all three
```

### Proxy

**Purpose:** Control access to an object.

**When to use:** Lazy loading, access control, logging, caching.

```python
class Image:
    def display(self):
        pass

class RealImage(Image):
    def __init__(self, filename: str):
        self._filename = filename
        self._load_from_disk()  # Expensive
    
    def _load_from_disk(self):
        print(f"Loading {self._filename}")
    
    def display(self):
        print(f"Displaying {self._filename}")

# Lazy loading proxy
class ImageProxy(Image):
    def __init__(self, filename: str):
        self._filename = filename
        self._real_image = None
    
    def display(self):
        if self._real_image is None:
            self._real_image = RealImage(self._filename)
        self._real_image.display()

# Usage
image = ImageProxy("photo.jpg")  # Not loaded yet
image.display()  # Loaded only when needed
```

### Composite

**Purpose:** Treat individual objects and compositions uniformly.

**When to use:** Tree structures, hierarchies (files/folders, UI components).

```typescript
interface Component {
    getPrice(): number;
}

class Product implements Component {
    constructor(private price: number) {}
    
    getPrice(): number {
        return this.price;
    }
}

class Box implements Component {
    private children: Component[] = [];
    
    add(component: Component): void {
        this.children.push(component);
    }
    
    getPrice(): number {
        return this.children.reduce(
            (sum, child) => sum + child.getPrice(),
            0
        );
    }
}

// Usage
const smallBox = new Box();
smallBox.add(new Product(10));
smallBox.add(new Product(20));

const bigBox = new Box();
bigBox.add(smallBox);
bigBox.add(new Product(50));

console.log(bigBox.getPrice());  // 80
```

---

## Behavioral Patterns

### Strategy

**Purpose:** Define a family of algorithms, make them interchangeable.

**When to use:** Multiple ways to do something, switchable at runtime.

```python
class PricingStrategy(ABC):
    @abstractmethod
    def calculate(self, base_price: float) -> float: ...

class RegularPricing(PricingStrategy):
    def calculate(self, base_price: float) -> float:
        return base_price

class PremiumDiscount(PricingStrategy):
    def calculate(self, base_price: float) -> float:
        return base_price * 0.8  # 20% off

class BlackFridayPricing(PricingStrategy):
    def calculate(self, base_price: float) -> float:
        return base_price * 0.5  # 50% off

class ShoppingCart:
    def __init__(self, pricing: PricingStrategy):
        self._pricing = pricing
        self._items = []
    
    def add_item(self, price: float):
        self._items.append(price)
    
    def calculate_total(self) -> float:
        base = sum(self._items)
        return self._pricing.calculate(base)

# Usage
cart = ShoppingCart(BlackFridayPricing())
cart.add_item(100)
print(cart.calculate_total())  # 50
```

#### Learning: `enum-strategy-resolution`

Use `str` + `Enum` with a default member for backward-compatible dispatch. This gives you a single dispatch point, satisfies the Open/Closed principle (add new strategies without modifying the dispatcher), and lets callers pass raw strings or enum members interchangeably.

```python
from enum import Enum

class ReportType(str, Enum):
    PDF = "pdf"
    HTML = "html"
    CSV = "csv"
    UNKNOWN = "unknown"

class ReportGenerator:
    _generators: dict[ReportType, Callable] = {}

    def __init__(self):
        self._generators = {
            ReportType.PDF: self._generate_pdf,
            ReportType.HTML: self._generate_html,
            ReportType.CSV:  self._generate_csv,
        }

    def generate(self, report_type: str | ReportType) -> bytes:
        key = ReportType(report_type)
        generator = self._generators.get(key, self._generators[ReportType.UNKNOWN])
        return generator()

    def _generate_pdf(self) -> bytes: ...
    def _generate_html(self) -> bytes: ...
    def _generate_csv(self) -> bytes: ...

# Usage — raw string or enum both work
gen = ReportGenerator()
gen.generate("pdf")                # resolves via ReportType("pdf")
gen.generate(ReportType.CSV)        # direct match
gen.generate("xlsx")                 # falls through to UNKNOWN
```

### Observer

**Purpose:** Notify multiple objects about state changes.

**When to use:** Event systems, pub/sub, reactive updates.

```typescript
interface Observer {
    update(event: Event): void;
}

class EventEmitter {
    private observers: Observer[] = [];
    
    subscribe(observer: Observer): void {
        this.observers.push(observer);
    }
    
    unsubscribe(observer: Observer): void {
        this.observers = this.observers.filter(o => o !== observer);
    }
    
    notify(event: Event): void {
        this.observers.forEach(o => o.update(event));
    }
}

// Usage
class OrderService extends EventEmitter {
    placeOrder(order: Order): void {
        // Process order...
        this.notify({ type: 'ORDER_PLACED', order });
    }
}

class EmailService implements Observer {
    update(event: Event): void {
        if (event.type === 'ORDER_PLACED') {
            this.sendConfirmation(event.order);
        }
    }
}

const orderService = new OrderService();
orderService.subscribe(new EmailService());
orderService.placeOrder(order);
```

### Template Method

**Purpose:** Define algorithm skeleton, let subclasses override steps.

**When to use:** Common algorithm with varying steps.

```python
from abc import ABC, abstractmethod

class DataExporter(ABC):
    # Template method - defines the algorithm
    def export(self, data: list):
        self.validate(data)
        formatted = self.format(data)
        self.write(formatted)
        self.notify()
    
    # Common steps
    def validate(self, data: list):
        if not data:
            raise ValueError("Empty data")
    
    def notify(self):
        print("Export complete")
    
    # Steps to override
    @abstractmethod
    def format(self, data: list) -> str: ...
    
    @abstractmethod
    def write(self, content: str): ...

class CSVExporter(DataExporter):
    def format(self, data: list) -> str:
        return '\n'.join(str(item) for item in data)
    
    def write(self, content: str):
        with open('export.csv', 'w') as f:
            f.write(content)

class JSONExporter(DataExporter):
    def format(self, data: list) -> str:
        import json
        return json.dumps(data)
    
    def write(self, content: str):
        with open('export.json', 'w') as f:
            f.write(content)
```

### Command

**Purpose:** Encapsulate a request as an object.

**When to use:** Undo/redo, queuing, logging actions.

```typescript
interface Command {
    execute(): void;
    undo(): void;
}

class AddItemCommand implements Command {
    constructor(
        private cart: Cart,
        private item: Item
    ) {}
    
    execute(): void {
        this.cart.add(this.item);
    }
    
    undo(): void {
        this.cart.remove(this.item);
    }
}

class CommandHistory {
    private history: Command[] = [];
    
    execute(command: Command): void {
        command.execute();
        this.history.push(command);
    }
    
    undo(): void {
        const command = this.history.pop();
        command?.undo();
    }
}

// Usage
const history = new CommandHistory();
history.execute(new AddItemCommand(cart, item));
history.undo();  // Removes item
```

---

## Concurrency Patterns

### Learning: `atomic-sql-update-race-free-transition`

Use a single `UPDATE ... WHERE expected_state RETURNING cols` as an optimistic lock. The `WHERE` clause acts as the guard; `RETURNING` fetches needed columns in one round-trip. Losers re-read and reconcile idempotently.

```python
# WRONG — read-then-write race; two callers both transition state
run = await db.get_run(run_id)
if run.status == "pending":
    run.status = "running"
    await db.commit()  # RACE: another worker already committed "running"
    await launch_side_effects(run)  # Duplicate side effects!

# CORRECT — atomic conditional UPDATE
from sqlalchemy import update

result = await session.execute(
    update(Run)
    .where(Run.id == run_id, Run.status == "pending")  # Optimistic lock
    .values(status="running", started_at=func.now())
    .returning(Run)  # Fetch in same round-trip
)
row = result.fetchone()
if row is None:
    # Another worker already transitioned — reconcile idempotently
    return await db.get_run(run_id)

await launch_side_effects(row)  # Exactly ONE worker reaches here
```

**Key properties:**
- **Race-free**: the database row-level lock ensures only one `UPDATE` matches
- **One round-trip**: no separate SELECT + UPDATE
- **Idempotent reconciliation**: losers simply re-read current state

**Detection:**

```bash
# Find read-then-write patterns vulnerable to races
rg 'get_.*\(\|fetch_.*\(' --type py -A 10 | rg 'status|state' | rg 'commit|save|update'
```

### Learning: `double-checked-locking-async-refresh`

When a token or cache entry needs refreshing, naive locking produces a thundering herd: every concurrent request acquires the lock serially and each one re-fetches from the upstream provider. The fix is double-checked locking: (1) check validity WITHOUT a lock, (2) if invalid, acquire the lock, (3) RE-CHECK validity under the lock, (4) refresh only if still invalid. The second check ensures exactly ONE HTTP POST refreshes the token; every other waiter sees the freshly refreshed value and skips the network call. Use `time.monotonic()` (not `time.time()`) for expiry so NTP adjustments never falsely expire or extend a token. Refresh proactively at 80% of TTL so the first request after expiry doesn't pay the refresh cost.

```python
# WRONG — every waiter acquires the lock serially and re-fetches
class TokenRefresher:
    def __init__(self):
        self._lock = asyncio.Lock()
        self._token: str | None = None
        self._expires_at = 0.0

    async def get_token(self) -> str:
        async with self._lock:                       # acquired on EVERY call once expired
            if self._is_stale():
                self._token = await self._refresh()  # N callers → N HTTP POSTs
                self._expires_at = time.monotonic() + 3600
        return self._token

# CORRECT — double-checked locking caps concurrent refreshes to exactly ONE POST
class TokenRefresher:
    def __init__(self, ttl: int = 3600):
        self._lock = asyncio.Lock()
        self._token: str | None = None
        self._expires_at = 0.0
        self._ttl = ttl

    def _is_stale(self) -> bool:
        # proactive refresh at 80% of TTL
        return time.monotonic() >= (self._expires_at - 0.2 * self._ttl)

    async def get_token(self) -> str:
        # (1) unlocked check — hot path skips the lock entirely
        if self._token and not self._is_stale():
            return self._token

        async with self._lock:
            # (2) RE-CHECK under the lock — only ONE caller refreshes
            if self._token and not self._is_stale():
                return self._token
            # (3) the single refresh
            self._token = await self._refresh()
            self._expires_at = time.monotonic() + self._ttl
        return self._token
```

**Key properties:**
- **One refresh per expiry window** — the second check under the lock guarantees only the first waiter hits the provider
- **Hot path lock-free** — callers within TTL never acquire the lock
- **Monotonic clock** — immune to NTP adjustments
- **Proactive 80% refresh** — no first-request penalty after expiry

**Detection:**

```bash
# find async refresh paths missing the second (under-lock) validity check
rg 'async with self\._lock|async with.*Lock' --type py -A 15 | rg 'await.*refresh|await.*fetch' | rg -v 'if.*stale|if.*expired'
```

**Rule:** Async token/cache refreshes must use double-checked locking (unlocked check → acquire lock → re-check → refresh only if still invalid) so exactly one caller hits the upstream provider. Always pair with `time.monotonic()` for expiry and proactive refresh at 80% of TTL.

---

## Pattern Selection Guide

| Problem | Pattern | Key Indicator |
|---------|---------|---------------|
| Multiple creation ways | Factory, Builder | Complex constructors |
| One instance needed | Singleton | Global state |
| Incompatible interfaces | Adapter | Third-party integration |
| Add behavior dynamically | Decorator | Need to combine features |
| Control object access | Proxy | Lazy loading, caching |
| Tree structures | Composite | Hierarchical data |
| Interchangeable algorithms | Strategy | Switch/if for algorithms |
| Event notification | Observer | Multiple listeners |
| Algorithm with variations | Template Method | Same steps, different details |
| Undo/redo operations | Command | Action history |

---

#### Learning: `zai-node-mixin`

Prefer a mixin over deep inheritance when you need to selectively adopt methods. A mixin respects `__init_subclass__`, avoids fragile base class issues, and lets subclasses pick only the behaviors they need.

```python
class CacheMixin:
    """Provides caching behavior to any node."""

    def get_cached(self, key: str):
        return self._cache.get(key)

    def set_cached(self, key: str, value):
        self._cache[key] = value

    def invalidate_cache(self, key: str):
        self._cache.pop(key, None)

class RetryMixin:
    """Provides retry behavior to any service call."""

    def with_retry(self, fn, max_retries: int = 3, delay: float = 1.0):
        for attempt in range(max_retries):
            try:
                return fn()
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                time.sleep(delay * (attempt + 1))

class DataPipeline(CacheMixin, RetryMixin):
    def __init__(self):
        self._cache = {}

    def fetch(self, url: str):
        cached = self.get_cached(url)
        if cached:
            return cached
        result = self.with_retry(lambda: requests.get(url).json())
        self.set_cached(url, result)
        return result

# DataPipeline has both caching and retry — no deep inheritance chain
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| **God Object** | Class does everything | Split by responsibility |
| **Spaghetti Code** | Tangled, no structure | Refactor to layers |
| **Golden Hammer** | Using one pattern for everything | Match pattern to problem |
| **Premature Optimization** | Optimizing before needed | YAGNI, profile first |
| **Copy-Paste Programming** | Duplication | Extract, Rule of Three |

---

## Steps

### Step 1: Identify the Problem

1. Describe the design problem clearly
2. Check if it matches a pattern's purpose
3. Consider if simpler solution exists

### Step 2: Verify Pattern Fit

1. Check the "Key Indicator" in Pattern Selection Guide
2. Ensure it simplifies, not complicates
3. Confirm team understands the pattern

### Step 3: Apply the Pattern

1. Start with the simplest implementation
2. Add complexity only when needed
3. Keep the pattern's intent clear

### Step 4: Verify and Refactor

1. Ensure the problem is actually solved
2. Check for over-engineering
3. Simplify if pattern adds no value

---

## Best Practices

- **Let patterns emerge** from refactoring, not upfront design
- **Start simple** - add patterns when you feel pain
- **Name patterns explicitly** in code for shared vocabulary
- **Document why** a pattern was chosen, not just what
- **Review in pairs** - patterns should be understood by all

---

## Verification Commands

After applying patterns:

```bash
# Check for pattern-related naming
grep -r "Factory\|Builder\|Strategy\|Observer\|Singleton" src/

# Count classes per file (too many might indicate over-engineering)
find src -name "*.ts" -exec grep -c "class " {} \;

# Check for pattern interfaces
grep -r "interface.*Strategy\|interface.*Observer\|interface.*Command" src/
```

**Pattern Verification Checklist:**
- [ ] Pattern solves a real problem (not hypothetical)
- [ ] Pattern simplifies the code (not complicates)
- [ ] Team understands the pattern
- [ ] Pattern is documented with reasoning
- [ ] No simpler alternative exists
