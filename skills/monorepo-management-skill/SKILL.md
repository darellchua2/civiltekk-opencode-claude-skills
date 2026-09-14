---
name: monorepo-management-skill
description: >-
  Manage JS/TS monorepos — Turborepo, Nx, pnpm workspaces; package boundaries,
  build caching, changesets.
license: Apache-2.0
compatibility: opencode
category: DevOps
---

## What I do

I help you set up and manage JavaScript/TypeScript monorepos:

1. **Turborepo**: Configuration, pipeline design, caching strategies
2. **Nx**: Workspace setup, generators, affected commands
3. **pnpm Workspaces**: Package management, dependency hoisting
4. **Package Boundaries**: ESLint rules for import restrictions
5. **Shared Configs**: Centralized ESLint, TypeScript, and Tailwind configs
6. **Build Caching**: Local and remote cache configuration
7. **Changesets**: Version management and changelog generation
8. **OpenCode LSP Integration**: Root-level `opencode.json` enabling typescript + eslint LSP across all packages

## When to use me

Use this skill when:
- Setting up a new monorepo (Turborepo, Nx, or pnpm workspaces)
- Configuring build pipelines and caching
- Implementing package boundary enforcement
- Creating shared configurations across packages
- Managing inter-package dependencies
- Setting up changesets for versioning
- Troubleshooting monorepo build or dependency issues
- Migrating from a single repo to monorepo structure

## Related Skills

- **typescript-dry-principle-skill**: Code deduplication within monorepo packages
- **nextjs-standard-setup-skill**: Next.js app setup within monorepo packages
- **python-ruff-linter-skill**: Python monorepos (this skill focuses on JS/TS)

---

## Step 1: Tool Selection

| Tool | Best For | Learning Curve | Build Speed |
|------|----------|---------------|-------------|
| **Turborepo** | Next.js apps, simple pipelines | Low | Very fast |
| **Nx** | Complex dependency graphs, generators | Medium | Fast |
| **pnpm workspaces** | Simple package management | Low | Standard |

**Recommendation**: Start with **Turborepo + pnpm workspaces** for Next.js projects. Use **Nx** if you need generators or complex affected-graph calculations.

---

## Step 2: Turborepo Setup

### Project Structure

```
monorepo/
├── turbo.json
├── package.json
├── pnpm-workspace.yaml
├── packages/
│   ├── ui/              # Shared component library
│   │   ├── package.json
│   │   └── src/
│   ├── config/          # Shared configurations
│   │   ├── eslint-config/
│   │   ├── typescript-config/
│   │   └── tailwind-config/
│   └── utils/           # Shared utilities
│       ├── package.json
│       └── src/
├── apps/
│   ├── web/             # Next.js app
│   │   ├── package.json
│   │   └── src/
│   └── api/             # API server
│       ├── package.json
│       └── src/
└── .changeset/
    └── config.json
```

### turbo.json

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "typecheck": {
      "dependsOn": ["^build"]
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    },
    "clean": {
      "cache": false
    }
  }
}
```

### pnpm-workspace.yaml

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

### Root package.json

```json
{
  "name": "monorepo",
  "private": true,
  "scripts": {
    "build": "turbo build",
    "dev": "turbo dev",
    "lint": "turbo lint",
    "typecheck": "turbo typecheck",
    "test": "turbo test",
    "clean": "turbo clean",
    "changeset": "changeset",
    "version": "changeset version",
    "release": "turbo build && changeset publish"
  },
  "devDependencies": {
    "turbo": "^2.0.0",
    "@changesets/cli": "^2.27.0"
  },
  "packageManager": "pnpm@9.0.0"
}
```

### OpenCode LSP Integration (root config)

Create a root-level `opencode.json` to feed real-time TypeScript and ESLint diagnostics to the agent across all packages. The typescript server picks up each package's `tsconfig.json` (which extend `@repo/typescript-config`); the eslint server uses the shared `@repo/eslint-config`. This gives ambient cross-package type-error awareness — critical in monorepos where a change in `packages/ui` can break `apps/web`.

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "typescript": {},
    "eslint": {}
  }
}
```

**Why root-level:** a single root config covers the entire workspace. Project config merges with each user's global `~/.config/opencode/opencode.json`, so only the `lsp` key needs declaring here. Check into git so the whole team inherits it.

**Monorepo note:** both servers are triggered by file extension (`.ts/.tsx/.js/.jsx/.mjs/.cjs/.mts/.cts`), so they activate per-file regardless of which package the agent is editing. No per-package `opencode.json` needed.

**Token cost:** diagnostics are injected into model context. In a large monorepo this can be significant — monitor usage and set `"lsp": false` to temporarily disable, or scope to specific servers.

Refs: [LSP](https://opencode.ai/docs/lsp/) · [Config](https://opencode.ai/docs/config/)

---

## Step 3: Shared Configurations

### TypeScript Config Package

```
packages/typescript-config/
├── package.json
├── base.json
├── nextjs.json
└── react-library.json
```

```json
// packages/typescript-config/base.json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist"
  },
  "exclude": ["node_modules", "dist"]
}
```

```json
// packages/typescript-config/nextjs.json
{
  "extends": "./base.json",
  "compilerOptions": {
    "plugins": [{ "name": "next" }],
    "allowJs": true,
    "incremental": true,
    "jsx": "preserve",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

```json
// packages/typescript-config/package.json
{
  "name": "@repo/typescript-config",
  "version": "0.0.0",
  "private": true,
  "license": "MIT",
  "files": ["base.json", "nextjs.json", "react-library.json"]
}
```

### App Usage

```json
// apps/web/tsconfig.json
{
  "extends": "@repo/typescript-config/nextjs.json",
  "compilerOptions": {
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"], "@repo/ui": ["../../packages/ui/src"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
```

### ESLint Config Package

```javascript
// packages/eslint-config/library.js
const { resolve } = require("node:path")

const project = resolve(process.cwd(), "tsconfig.json")

module.exports = {
  extends: [
    "eslint:recommended",
    "turbo",
    "prettier",
  ],
  plugins: ["import", "@typescript-eslint"],
  settings: {
    "import/resolver": {
      typescript: { project },
    },
  },
  rules: {
    "import/no-extraneous-dependencies": "error",
    "no-console": ["warn", { allow: ["warn", "error"] }],
  },
  ignorePatterns: [".next/", "dist/", "node_modules/"],
}
```

---

## Step 4: Package Boundaries

### ESLint Import Restrictions

```javascript
// packages/eslint-config/boundaries.js
const path = require("node:path")

module.exports = {
  plugins: ["boundaries"],
  rules: {
    "boundaries/element-types": [
      "error",
      {
        default: "allow",
        rules: [
          {
            from: "apps/*",
            disallowed: ["packages/*/src/**"],
            message: "Import from package entry points, not internal files",
          },
          {
            from: "packages/ui",
            disallowed: ["apps/*"],
            message: "UI library must not depend on apps",
          },
        ],
      },
    ],
  },
}
```

### Package Dependency Rules

```json
// apps/web/package.json
{
  "name": "@repo/web",
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/utils": "workspace:*",
    "next": "^14.0.0",
    "react": "^18.0.0"
  },
  "devDependencies": {
    "@repo/typescript-config": "workspace:*",
    "@repo/eslint-config": "workspace:*"
  }
}
```

**Rule**: Use `workspace:*` for monorepo internal dependencies.

---

## Step 5: Build Caching

### Local Cache

Turborepo caches by default at `node_modules/.cache/turbo/`.

### Remote Cache (Vercel)

```bash
npx turbo login
npx turbo link
turbo build --team=my-team --token=$TURBO_TOKEN
```

### Cache Customization

```json
{
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"],
      "inputs": ["src/**", "package.json", "tsconfig.json"],
      "env": ["NODE_ENV", "API_URL"]
    }
  }
}
```

### Affected Commands (Only changed packages)

```bash
turbo build --filter=...[HEAD^1]   # Build packages affected by last commit
turbo test --filter=@repo/web       # Test specific package
turbo lint --filter=apps/*          # Lint all apps
turbo build --filter=./packages/*   # Build all packages
```

---

## Step 6: Changesets for Versioning

### Setup

```bash
pnpm add -Dw @changesets/cli
pnpm changeset init
```

### .changeset/config.json

```json
{
  "$schema": "https://unpkg.com/@changesets/config@3.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "restricted",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": []
}
```

### Workflow

```bash
pnpm changeset                          # Create a changeset (select packages + version bump)
pnpm changeset version                  # Apply changesets, update package.json + CHANGELOG
turbo build && pnpm changeset publish   # Build and publish to npm
```

### Changeset File Example

```markdown
---
"@repo/ui": minor
"@repo/utils": patch
---

Added new Button component with variant support
Fixed utility function edge case
```

### CI Integration

```yaml
name: Release
on:
  push:
    branches: [main]
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with: { node-version: "20" }
      - run: pnpm install --frozen-lockfile
      - run: pnpm turbo build
      - run: pnpm changeset publish
        env:
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

## Step 7: Nx Setup (Alternative)

### Workspace Configuration

```json
// nx.json
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "cache": true,
      "inputs": ["production", "^production"]
    },
    "test": {
      "cache": true,
      "inputs": ["default", "^production"]
    },
    "lint": {
      "cache": true
    }
  },
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "production": ["default", "!{projectRoot}/**/*.test.*", "!{projectRoot}/test/**/*"],
    "sharedGlobals": ["{workspaceRoot}/tsconfig.base.json"]
  }
}
```

### Generators

```bash
npx nx g @nx/react:lib ui --directory=packages/ui
npx nx g @nx/next:app web --directory=apps/web
npx nx g @nx/js:lib utils --directory=packages/utils
```

### Affected Commands

```bash
npx nx affected --target=build          # Build affected packages
npx nx affected --target=test           # Test affected packages
npx nx affected --target=lint --base=main~1
```
