---
name: authentication-authorization-skill
description: >-
  Implement authentication and authorization — OAuth2/OIDC, JWT, sessions,
  RBAC/ABAC, NextAuth/Auth.js, Passport.js, password hashing, CSRF.
license: Apache-2.0
compatibility: opencode
category: Security
---

## What I do

I help you implement secure authentication and authorization systems:

1. **OAuth2/OIDC**: Authorization code, client credentials, PKCE flows
2. **JWT**: Token creation, validation, rotation, and best practices
3. **Session Management**: Secure session handling and storage
4. **RBAC/ABAC**: Role-based and attribute-based access control
5. **Framework Integration**: NextAuth/Auth.js, Passport.js, FastAPI security
6. **Password Security**: Hashing, salting, and password policies
7. **CSRF Protection**: Token-based and same-site cookie patterns

## When to use me

Use this skill when:
- Implementing login/signup flows
- Setting up OAuth2 social login (Google, GitHub, etc.)
- Designing role-based access control
- Configuring JWT token management
- Integrating NextAuth/Auth.js or Passport.js
- Implementing API authentication middleware
- Setting up password hashing and verification
- Adding CSRF protection to forms
- Implementing multi-factor authentication

## Related Skills

- **security-audit-skill**: Handles security *auditing* and vulnerability scanning. This skill handles auth *implementation*. CSRF here focuses on implementation patterns; security-audit focuses on detecting CSRF vulnerabilities.
- **api-design-skill**: API endpoint design. This skill handles authentication middleware for those endpoints.
- **nextjs-standard-setup-skill**: Project scaffolding that may include auth setup.

---

## Step 1: OAuth2/OIDC Flows

### Flow Selection

| Flow | Use Case | Client Type |
|------|----------|-------------|
| Authorization Code + PKCE | SPAs, mobile apps | Public |
| Authorization Code | Server-side web apps | Confidential |
| Client Credentials | Service-to-service | Confidential |
| Device Code | CLI tools, IoT | Public |

### Authorization Code + PKCE (Next.js)

```typescript
import NextAuth from "next-auth"
import Google from "next-auth/providers/google"

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    }),
  ],
  pages: {
    signIn: "/login",
    error: "/login",
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
        token.role = user.role
      }
      return token
    },
    async session({ session, token }) {
      session.user.id = token.id
      session.user.role = token.role
      return session
    },
  },
  session: {
    strategy: "jwt",
    maxAge: 24 * 60 * 60,
  },
})
```

### Client Credentials (Python/FastAPI)

```python
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

async def get_service_token(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    if payload.get("type") != "service":
        raise HTTPException(status_code=403, detail="Service token required")
    return payload
```

---

## Step 2: JWT Best Practices

### Token Structure

```json
{
  "sub": "user_abc123",
  "email": "user@example.com",
  "role": "admin",
  "type": "access",
  "iat": 1705312200,
  "exp": 1705315800,
  "jti": "unique-token-id",
  "iss": "my-api",
  "aud": "my-api-users"
}
```

### Token Creation (Python)

```python
from datetime import datetime, timedelta, timezone
from jose import jwt

def create_access_token(subject: str, role: str, expires_delta: timedelta | None = None):
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    return jwt.encode(
        {
            "sub": subject,
            "role": role,
            "type": "access",
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "jti": str(uuid4()),
            "iss": settings.APP_NAME,
            "aud": "my-api-users",
        },
        settings.SECRET_KEY,
        algorithm="HS256",
    )

def create_refresh_token(subject: str):
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    return jwt.encode(
        {
            "sub": subject,
            "type": "refresh",
            "exp": expire,
            "jti": str(uuid4()),
        },
        settings.SECRET_KEY,
        algorithm="HS256",
    )
```

### Token Validation

```python
from jose import JWTError, jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=["HS256"],
            audience="my-api-users",
            issuer=settings.APP_NAME,
        )
        if payload.get("type") != "access":
            raise HTTPException(401, "Invalid token type")
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(401, "Invalid token")
    except JWTError:
        raise HTTPException(401, "Token validation failed")
    return await get_user(user_id)
```

### Token Rotation

```python
@router.post("/auth/refresh")
async def refresh_token(refresh_token: str):
    payload = verify_token(refresh_token, token_type="refresh")

    if await is_token_revoked(payload["jti"]):
        raise HTTPException(401, "Token revoked")

    await revoke_token(payload["jti"])

    access = create_access_token(payload["sub"], role=payload.get("role", "user"))
    refresh = create_refresh_token(payload["sub"])

    return {"access_token": access, "refresh_token": refresh, "token_type": "bearer"}
```

### Best Practices

| Practice | Why |
|----------|-----|
| Short-lived access tokens (15min) | Limits damage from theft |
| Longer refresh tokens (7 days) | Reduces re-auth frequency |
| Store refresh tokens in httpOnly cookie | Not accessible via JavaScript |
| Never store tokens in localStorage | XSS vulnerability |
| Include `jti` for revocation | Enable server-side revocation |
| Use `iss` and `aud` claims | Prevent token confusion |
| Rotate signing keys periodically | Limit blast radius |

---

## Step 3: RBAC/ABAC

### Role-Based Access Control (RBAC)

```python
from enum import Enum
from functools import wraps

class Role(str, Enum):
    ADMIN = "admin"
    EDITOR = "editor"
    VIEWER = "viewer"

ROLE_PERMISSIONS = {
    Role.ADMIN: {"users:read", "users:write", "users:delete", "posts:read", "posts:write", "posts:delete"},
    Role.EDITOR: {"posts:read", "posts:write", "users:read"},
    Role.VIEWER: {"posts:read", "users:read"},
}

class RequirePermission:
    def __init__(self, permission: str):
        self.permission = permission

    async def __call__(self, current_user=Depends(get_current_user)):
        user_permissions = ROLE_PERMISSIONS.get(Role(current_user.role), set())
        if self.permission not in user_permissions:
            raise HTTPException(403, f"Permission '{self.permission}' required")
        return current_user

@router.delete("/api/v1/users/{user_id}")
async def delete_user(
    user_id: str,
    current_user=Depends(RequirePermission("users:delete")),
):
    ...
```

### Next.js Route Protection

```typescript
import { auth } from "@/auth"
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export async function middleware(request: NextRequest) {
  const session = await auth()

  if (!session) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  if (request.nextUrl.pathname.startsWith("/admin") && session.user.role !== "admin") {
    return NextResponse.redirect(new URL("/unauthorized", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/dashboard/:path*", "/admin/:path*", "/api/v1/((?!auth).*)"],
}
```

### two-layer-keycloak-authorization

Defense-in-depth with Keycloak: use coarse Policy Enforcer (route-level) for bulk access control + fine-grained app-layer composite roles for business logic. Never rely on a single authorization layer.

```
┌─────────────────────────────────────────────────────┐
│                    Request Flow                      │
│                                                      │
│  Client ──► API Gateway ──► Policy Enforcer ──► App  │
│                (Layer 1)        (Layer 2)            │
│                                                      │
│  Layer 1: Keycloak Policy Enforcer (coarse)          │
│    - Route-level: /admin/* requires role=admin       │
│    - Method-level: DELETE requires role=editor        │
│    - Enforced by Keycloak Authorization Services      │
│                                                      │
│  Layer 2: App-layer composite roles (fine-grained)   │
│    - Business rules: user.ownOrg === resource.orgId  │
│    - Attribute checks: user.department === "finance"  │
│    - Data scoping: WHERE tenant_id = user.tenant_id   │
│                                                      │
│   Layer 2 runs EVEN IF Layer 1 passes.             │
│     Never skip Layer 2 — Policy Enforcer alone        │
│     cannot enforce data-level authorization.          │
└─────────────────────────────────────────────────────┘
```

```typescript
// Layer 1: Policy Enforcer config (keycloak.json)
{
  "policy-enforcer": {
    "enforcement-mode": "PERMISSIVE",
    "paths": [
      { "path": "/admin/*", "roles-allowed": ["admin"] },
      { "path": "/api/v1/resources/*", "method-scopes": {
          "DELETE": "resources:delete"
        }
      }
    ]
  }
}

// Layer 2: App-layer fine-grained check (always runs)
async function deleteResource(req, res) {
  const user = req.kauth.grant.access_token.content

  // Layer 1 already verified role — now check data ownership
  const resource = await getResource(req.params.id)
  if (resource.tenantId !== user.tenant_id) {
    return res.status(403).json({ error: 'Cross-tenant access denied' })
  }

  await deleteResource(req.params.id)
}
```

### one-policy-per-role-type

<!-- Provenance: betekk-keycloak/LEARNINGS/ -->

In Keycloak Authorization Services, create one policy per role type (e.g., `admin-policy`, `editor-policy`, `viewer-policy`) rather than collapsing multiple role types into a single policy with OR logic. Collapsed policies make permission audits harder and risk unintended access grants when roles are added or removed.

**Rule:** If a policy checks more than one role type in its condition, split it. Each policy should evaluate exactly one role type, then compose at the permission level using `ALL` / `ANY` logic.

```typescript
// BAD — collapsed policy, hard to audit
// Keycloak policy condition: role = admin OR role = editor OR role = viewer
// Adding a new role type requires modifying this policy (blast radius)

// GOOD — one policy per role type
// admin-policy:   role = admin
// editor-policy:  role = editor
// viewer-policy:  role = viewer
// Permission: ANY(admin-policy, editor-policy, viewer-policy)
// Adding a new role type = add one new policy, no modification to existing ones
```

---

## Step 4: Password Security

### Hashing

```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

### Password Policy

```python
from pydantic import BaseModel, Field, field_validator
import re

class PasswordInput(BaseModel):
    password: str = Field(..., min_length=12, max_length=128)

    @field_validator("password")
    @classmethod
    def validate_strength(cls, v):
        checks = [
            (len(v) >= 12, "Must be at least 12 characters"),
            (re.search(r"[A-Z]", v), "Must contain uppercase letter"),
            (re.search(r"[a-z]", v), "Must contain lowercase letter"),
            (re.search(r"\d", v), "Must contain a digit"),
            (re.search(r"[!@#$%^&*(),.?\":{}|<>]", v), "Must contain special character"),
        ]
        failures = [msg for passed, msg in checks if not passed]
        if failures:
            raise ValueError("; ".join(failures))
        return v
```

---

## Step 5: CSRF Protection

### SameSite Cookies

```python
app.add_middleware(
    SessionMiddleware,
    secret_key=settings.SECRET_KEY,
    same_site="lax",
    https_only=not settings.DEBUG,
)
```

### Double Submit Cookie (API)

```typescript
import { NextRequest, NextResponse } from "next/server"

export function middleware(request: NextRequest) {
  if (["POST", "PUT", "PATCH", "DELETE"].includes(request.method)) {
    const cookieToken = request.cookies.get("csrf-token")?.value
    const headerToken = request.headers.get("x-csrf-token")

    if (!cookieToken || cookieToken !== headerToken) {
      return NextResponse.json({ error: "CSRF token mismatch" }, { status: 403 })
    }
  }
  return NextResponse.next()
}
```

---

## Step 6: Session Management

### Token Storage Decision Matrix

| Storage | Access | Security | Best For |
|---------|--------|----------|----------|
| httpOnly cookie | Server only | High (no XSS) | Refresh tokens |
| Memory (state) | Client only | Medium (XSS but not persisted) | Short-lived access tokens |
| localStorage | Client | Low (XSS accessible) | Never for sensitive tokens |
| Session storage | Client | Medium (tab-scoped) | Temporary state |

### Session Invalidation

```python
BLOCKLIST_KEY = "token:blocklist"

async def revoke_token(jti: str):
    await redis_client.set(f"{BLOCKLIST_KEY}:{jti}", "1", ex=86400 * 7)

async def is_token_revoked(jti: str) -> bool:
    return await redis_client.exists(f"{BLOCKLIST_KEY}:{jti}")

### stateless-cookie-cache-maxage-match-session

When using JWE (JSON Web Encryption) cookies, the `cookieCache.maxAge` (how long the cached decryption result lives) must be `>= session.expiresIn`. If the JWE cached entry expires before the session itself, `findSession()` returns `null` and silently deletes the session — users get logged out mid-session without any error.

```typescript
// VULNERABLE — cookieCache expires before session
const sessionConfig = {
  secret: process.env.SESSION_SECRET,
  cookie: {
    maxAge: 24 * 60 * 60, // session lives 24h
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
  },
  // cookieCache decryption result expires in 1h — session dies at 1h
}

// SECURE — cookieCache maxAge >= cookie maxAge
const sessionConfig = {
  secret: process.env.SESSION_SECRET,
  cookie: {
    maxAge: 24 * 60 * 60, // session lives 24h
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
  },
  cookieCache: {
    maxAge: 24 * 60 * 60, // >= session maxAge — decryption cache never causes premature logout
  },
}
```

**Rule**: Always set `cookieCache.maxAge >= session.cookie.maxAge`. The cache is just an optimization — it should never be the reason a session terminates.

---

## Step 7: Cookie Security

### chunked-cookie-secure-prefix-mismatch

Always use a shared cookie utility for setting and reading cookies — never roll your own `__Secure-` prefix logic. Browsers silently reject `__Secure-` cookies that are missing `Secure` flag or set over HTTP, while `__Host-` cookies additionally require `Path=/` and no `Domain`. Inconsistent prefix handling across hand-rolled code leads to cookies being silently dropped, causing session loss or CSRF token mismatch.

**Warning**: If one module sets `__Secure-session` and another reads `session`, the read finds nothing. If one sets `__Secure-session` without the `Secure` flag, the browser drops it silently.

```typescript
// VULNERABLE — hand-rolled prefix logic scattered across codebase
// Module A
document.cookie = `__Secure-session=${token}; path=/; SameSite=Lax`

// Module B (forgets prefix, reads wrong cookie name)
function getSession() {
  return document.cookie
    .split('; ')
    .find(row => row.startsWith('session='))
    ?.split('=')[1]
}

// SECURE — shared cookie utility
const cookies = {
  set(name: string, value: string, options: CookieOptions) {
    const prefix = options.secure ? '__Secure-' : ''
    const fullName = `${prefix}${name}`
    const parts = [`${fullName}=${value}`]
    if (options.secure) parts.push('Secure')
    if (options.httpOnly) parts.push('HttpOnly')
    if (options.sameSite) parts.push(`SameSite=${options.sameSite}`)
    if (options.path) parts.push(`Path=${options.path}`)
    if (options.maxAge) parts.push(`Max-Age=${options.maxAge}`)
    document.cookie = parts.join('; ')
  },

  get(name: string): string | undefined {
    // Try both prefixed and non-prefixed names
    for (const prefix of ['__Secure-', '__Host-', '']) {
      const fullName = `${prefix}${name}`
      const match = document.cookie
        .split('; ')
        .find(row => row.startsWith(`${fullName}=`))
      if (match) return match.split('=')[1]
    }
    return undefined
  },
}

// Usage — consistent everywhere
cookies.set('session', token, {
  secure: true,
  httpOnly: true,
  sameSite: 'lax',
  path: '/',
  maxAge: 86400,
})
const session = cookies.get('session') // always finds it
```

### `cookie-only-proxy-with-server-rbac`

In stateless mode, the proxy/middleware's ONLY job is "does a session cookie exist?" — a fast, local check that adds negligible latency. Pushing token refresh (a network call to the IdP) or RBAC (a database or policy lookup) into the middleware adds 50–500 ms to EVERY navigation, because the middleware runs on every matched route. Move token refresh to `customSession` (runs once per session, not per request) and move RBAC to per-route server layouts or resolver-level guards (runs only for the route actually being rendered). The middleware should never make a network call.

```typescript
// WRONG — middleware does refresh + RBAC on every navigation (50-500ms each)
export async function middleware(request: NextRequest) {
  const token = request.cookies.get('session')
  if (!token) return NextResponse.redirect(new URL('/login', request.url))

  // network call #1 — refresh token if expiring (adds latency to every nav)
  const refreshed = await refreshIfExpiring(token.value)
  // network call #2 — RBAC lookup (adds latency to every nav)
  const role = await getUserRole(refreshed.userId)
  if (!canAccess(request.nextUrl.pathname, role)) {
    return NextResponse.redirect(new URL('/forbidden', request.url))
  }
  const response = NextResponse.next()
  response.cookies.set('session', refreshed.token, { httpOnly: true, secure: true })
  return response
}

// CORRECT — middleware only checks cookie existence; refresh + RBAC move server-side
export async function middleware(request: NextRequest) {
  const token = request.cookies.get('session')
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url))  // local check only
  }
  return NextResponse.next()  // no network call — fast on every navigation
}

// auth.config.ts — token refresh runs once per session, not per request
export const { auth, signIn, signOut } = NextAuth({
  session: { strategy: 'jwt' },
  callbacks: {
    async jwt({ token, user }) {
      if (user) return { ...token, ...user }
      // refresh only when the JWT is close to expiry — not on every request
      if (Date.now() < (token.exp ?? 0) * 1000 - 5 * 60 * 1000) return token
      return await refreshAccessToken(token)
    },
  },
})

// app/admin/layout.tsx — RBAC at the route layout level, not in middleware
export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await auth()
  if (session?.user?.role !== 'admin') {
    redirect('/forbidden')  // runs only when this layout renders, not on every nav
  }
  return <>{children}</>
}
```

**Detection:**

```bash
rg 'export\s+(async\s+)?function\s+middleware' --type ts -A 30 | rg 'await|fetch|http'
```

**Rule:** In stateless mode, middleware checks ONLY for cookie existence. Move token refresh to `customSession`/JWT callbacks (once per session) and RBAC to per-route server layouts or resolver guards (only when that route renders). Never make a network call from the proxy/middleware — it runs on every navigation.
