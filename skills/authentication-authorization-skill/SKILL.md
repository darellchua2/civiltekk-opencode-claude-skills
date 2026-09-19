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

Implement authn/authz: OAuth2/OIDC flows, JWT lifecycle, sessions, RBAC/ABAC, framework integration, password hashing, CSRF. (This skill *implements*; `security-audit-skill` *audits*.)

## When to use me

Login/signup flows, OAuth social login, RBAC design, JWT management, NextAuth/Passport integration, API auth middleware, CSRF hardening, MFA.

**Related:** `security-audit-skill` (auditing/detection) · `api-design-skill` (endpoint design) · `nextjs-standard-setup-skill` (scaffolding incl. auth).

## House patterns

**two-layer-keycloak-authorization** — Keycloak defense-in-depth: Layer 1 = coarse Policy Enforcer (route-level `/admin/*` requires role, method-level DELETE scopes); Layer 2 = fine-grained app-layer composite roles (ownership `user.ownOrg === resource.orgId`, tenant scoping). Layer 2 runs EVEN IF Layer 1 passes — the Policy Enforcer cannot enforce data-level authorization.

**one-policy-per-role-type** (provenance: betekk-keycloak/LEARNINGS) — in Keycloak Authorization Services, one policy per role type (`admin-policy`, `editor-policy`, …), composed at the permission level via `ALL`/`ANY`. If a policy condition checks more than one role type, split it — collapsed policies resist audits and grant unintended access when roles change.

**stateless-cookie-cache-maxage-match-session** — with JWE cookies, `cookieCache.maxAge` MUST be `>= session.cookie.maxAge`. If the decryption cache expires first, `findSession()` returns null and silently deletes the session — users logged out mid-session with no error. The cache is an optimization and must never terminate a session.

**chunked-cookie-secure-prefix-mismatch** — always use one shared cookie utility for set/get; never hand-roll `__Secure-`/`__Host-` prefix logic per module. Browsers silently drop `__Secure-` cookies without `Secure` (or over HTTP) and `__Host-` without `Path=/`+no Domain; one module writing `__Secure-session` while another reads `session` = session loss / CSRF mismatch.

**cookie-only-proxy-with-server-rbac** — in stateless mode the middleware's ONLY job is "does a session cookie exist?" (local check). Token refresh → `customSession`/JWT callback (once per session); RBAC → per-route server layouts or resolver guards (only when that route renders). Any `await fetch` in middleware adds 50–500 ms to EVERY navigation.
Detection: `rg 'export\s+(async\s+)?function\s+middleware' --type ts -A 30 | rg 'await|fetch|http'`

> Removed 2026-09: OAuth flow tables and NextAuth/Passport/FastAPI code walkthroughs, JWT structure/rotation scripts, RBAC middleware examples, password-policy tables, CSRF/session/cookie tutorial steps — standard auth knowledge the model carries; the five house patterns above are what this config actually learned (Keycloak layering, JWE cache lifetime, cookie prefixes, middleware budget).
