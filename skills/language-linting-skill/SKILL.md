---
name: language-linting-skill
description: Multi-language linting — Python Ruff, JS/TS ESLint, Java Checkstyle/PMD/SpotBugs, C# dotnet format/Roslyn/StyleCop — extending linting-workflow with per-language rules, configs, and error guidance
license: Apache-2.0
compatibility: opencode
category: Language-Specific
---

## What I do

I implement per-language linting by extending the `linting-workflow` framework:

1. **Detect Language & Environment**: Identify the project language(s) and toolchain (Poetry/pip, npm/yarn/pnpm, Maven/Gradle, .NET SDK)
2. **Detect Linter Configuration**: Check which linter is installed and how it is configured
3. **Delegate to Linting Workflow**: Use `linting-workflow` for the core run-fix-verify loop
4. **Provide Per-Language Guidance**: Interpret error codes and rule violations (Ruff F/E/W, ESLint rules, Checkstyle/PMD/SpotBugs, CAxxxx/SAxxxx/IDExxxx)
5. **Ensure Coding Standards**: PEP 8, JavaScript/TypeScript style guides, Google Java Style, .NET coding conventions

## When to use me

Use this skill when:
- Writing or modifying code that needs to follow industry standards (Python, JS/TS, Java, C#)
- Before committing changes to ensure code quality
- When you see linter errors (Ruff, ESLint, Checkstyle, PMD, SpotBugs, dotnet format) and need help fixing them
- Setting up a new project with proper linting configuration
- You want to ensure code quality in automated workflows

**Framework**: This skill extends `linting-workflow` for generic linting, adding per-language linter guidance.

## Language Detection & Linter Selection

| Language | File Patterns | Primary Linter | Auto-Fix Command |
|----------|--------------|----------------|------------------|
| Python | `*.py`, `pyproject.toml`/`requirements.txt` | Ruff | `ruff check --fix .` |
| JS/TS | `*.{js,ts,jsx,tsx,mjs,cjs}`, `package.json` | ESLint | `npx eslint --fix .` |
| Java | `*.java`, `pom.xml`/`build.gradle` | Checkstyle + PMD + SpotBugs | Limited (formatter plugins) |
| C# | `*.cs`, `*.csproj`/`*.sln` | dotnet format + analyzers | `dotnet format` |

## Delegate to Linting Workflow

Use `linting-workflow` framework for:
- Language detection
- Linter detection
- Package manager detection
- Running linting with appropriate commands
- Auto-fix application
- Error resolution guidance
- Verification and re-running

## Error Resolution Template

For each violation found:

```
1. **File**: <file>
   Line: <line>
   Error: <error message>
   Code: <rule/diagnostic ID — F401 | no-unused-vars | Checkstyle rule | CA1822 | etc.>

2. **Rule Explanation**:
   <Description of what the linter is checking>

3. **Recommended Fix**:
   <Step-by-step fix instructions>

4. **Example**:
   // Before (incorrect)
   <code>

   // After (corrected)
   <code>

5. **Apply Fix**:
   <Action to take>
```

---

## Python: Ruff

### Detection

```bash
# Check for Python files
ls *.py 2>/dev/null

# Check for Python project files
[ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ]

# Check for Ruff
grep -q "ruff" pyproject.toml || grep -q "ruff" requirements.txt

# Check if Poetry is installed
poetry --version 2>/dev/null
```

### Common Ruff Error Codes

| Error Code | Description | Common Fix |
|------------|-------------|-----------|
| F401 | Unused imports | Remove or use import |
| F841 | Unused variables | Remove or use variable |
| E501 | Line too long (>default 88) | Break into multiple lines |
| E722 | Do not use bare except | Use specific exception types |
| W291 | Trailing whitespace | Remove trailing spaces |
| E731 | Do not assign a lambda expression | Use def instead of lambda assignment |
| F821 | Undefined name | Define the name or add missing import |
| E231 | Whitespace after ':' | Fix whitespace around punctuation |
| I001 | Import block is unsorted | Run ruff check --select I001 --fix |
| S101 | Use of assert detected | Use pytest.raises or remove assert |
| N801 | Class name should use CapWords | Rename class to CapWords convention |
| SIM | Code can be simplified | Apply suggested simplification |

### Ruff Configuration

```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "W"]
ignore = []
```

### Commands

```bash
# Poetry + Ruff
poetry run ruff check .
poetry run ruff check . --fix
poetry add --group dev ruff

# Direct Ruff
ruff check .
ruff check . --fix

# Selective checks
ruff check --select E,F,W .
ruff check --ignore E501 .
ruff check --select I001 --fix .
```

Python-specific best practices: PEP 8 style; type hints; PEP 257 docstrings; `ruff check --select I001` or isort for import order; Poetry for dependency isolation.

If Ruff is not installed: `poetry add --group dev ruff` or `pip install ruff`.

---

## JavaScript/TypeScript: ESLint

### Detection

```bash
# Check for JS/TS files
ls *.js *.jsx *.ts *.tsx 2>/dev/null

# Check for ESLint
grep -q "eslint" package.json

# Check for ESLint config files (legacy + flat)
[ -f .eslintrc.json ] || [ -f .eslintrc.js ] || [ -f .eslintrc.yaml ] || [ -f eslint.config.js ] || [ -f eslint.config.ts ] || [ -f eslint.config.mjs ]

# TypeScript project?
[ -f tsconfig.json ]  # → typescript, else javascript
```

### Package Manager Detection

```bash
if [ -f package-lock.json ]; then
  PKG_MANAGER="npm";  LINT_CMD="npm run lint";  LINT_FIX_CMD="npm run lint -- --fix"
elif [ -f yarn.lock ]; then
  PKG_MANAGER="yarn"; LINT_CMD="yarn lint";     LINT_FIX_CMD="yarn lint --fix"
elif [ -f pnpm-lock.yaml ]; then
  PKG_MANAGER="pnpm"; LINT_CMD="pnpm run lint"; LINT_FIX_CMD="pnpm run lint --fix"
fi
```

### Common ESLint Error Codes

| Error Code | Description | Common Fix |
|------------|-------------|-------------|
| no-unused-vars | Variables/imports defined but not used | Remove or use variable/import |
| semi | Missing semicolons | Add semicolons to statements |
| eqeqeq | Use == instead of === | Change == to === |
| no-console | Console statements found | Remove console.log/console.error |
| prefer-const | Variable could be const | Change let to const |
| no-undef | Undefined variable used | Define variable or import |
| quotes | Inconsistent quote style | Use consistent quotes (' or ") |
| indent | Incorrect indentation | Fix indentation level |
| no-trailing-spaces | Trailing whitespace | Remove trailing spaces |
| comma-dangle | Trailing comma in object/array | Remove trailing comma |
| no-extra-semi | Extra semicolon | Remove extra semicolon |

### TypeScript / React / Prettier Configuration

TypeScript:
```bash
npm install --save-dev @typescript-eslint/parser @typescript-eslint/eslint-plugin
```
```json
{
  "parser": "@typescript-eslint/parser",
  "parserOptions": { "ecmaVersion": 2020, "sourceType": "module", "ecmaFeatures": { "jsx": true } },
  "plugins": ["@typescript-eslint"],
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"]
}
```

React:
```bash
npm install --save-dev eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-jsx-a11y
```
```json
{
  "extends": ["eslint:recommended", "plugin:react/recommended", "plugin:react-hooks/recommended"],
  "plugins": ["react", "react-hooks", "jsx-a11y"],
  "rules": { "react/prop-types": "off", "react/react-in-jsx-scope": "off" }
}
```

Prettier integration (avoid formatting conflicts):
```bash
npm install --save-dev eslint-config-prettier eslint-plugin-prettier
```
```json
{ "extends": ["prettier"], "plugins": ["prettier"], "rules": { "prettier/prettier": "error" } }
```

### Commands

```bash
# npm / yarn / pnpm
npm run lint [-- --fix]
yarn lint [--fix]
pnpm run lint [--fix]

# Direct ESLint
npx eslint . [--fix]

# Install
npm install --save-dev eslint
yarn add --dev eslint
pnpm add -D eslint
```

JS/TS-specific best practices: `@typescript-eslint` for TypeScript projects; eslint-config-prettier for formatting; React projects use eslint-plugin-react + react-hooks + jsx-a11y; prefer const/let over var; arrow functions, template literals, destructuring where appropriate.

---

## Java: Checkstyle, PMD, SpotBugs

### Detection

```bash
# Check for Java files
ls *.java 2>/dev/null

# Maven or Gradle
[ -f pom.xml ] || [ -f build.gradle ] || [ -f build.gradle.kts ]

# Linter plugins configured?
grep -q "checkstyle" pom.xml 2>/dev/null || grep -q "checkstyle" build.gradle 2>/dev/null
grep -q "pmd" pom.xml 2>/dev/null || grep -q "pmd" build.gradle 2>/dev/null
grep -q "spotbugs" pom.xml 2>/dev/null || grep -q "spotbugs" build.gradle 2>/dev/null

# Spring Boot indicators
grep -q "@SpringBootApplication" -r src/ 2>/dev/null   # or spring-boot-starter deps

# Java version
java -version 2>&1 | head -1
```

### Common Checkstyle Violations

| Rule | Description | Common Fix |
|------|-------------|-----------|
| `FileLength` | File exceeds max lines | Split into smaller classes |
| `LineLength` | Line exceeds 120/140 chars | Break into multiple lines |
| `MethodLength` | Method exceeds 150 lines | Extract methods |
| `ParameterNumber` | Method has too many params | Use parameter object |
| `UnusedImports` | Import statement not used | Remove import |
| `Indentation` | Incorrect indentation | Match project indentation level |
| `JavadocMethod` | Missing Javadoc on public method | Add `/** */` documentation |
| `FinalParameters` | Parameter should be final | Add `final` modifier |
| `EmptyBlock` | Empty code block `{}` | Add implementation or comment |
| `MagicNumber` | Unexplained numeric literal | Extract to named constant |

### Common PMD Violations

| Rule | Category | Description | Common Fix |
|------|----------|-------------|-----------|
| `UnusedLocalVariable` | Unused code | Remove variable |
| `GodClass` | Design | Class is too complex | Split responsibilities |
| `ExcessiveMethodLength` | Design | Method too long | Extract methods |
| `NPathComplexity` | Complexity | Too many branches | Simplify / refactor |
| `AvoidDeeplyNestedIfStmts` | Complexity | Deeply nested if statements | Use guard clauses or polymorphism |
| `ConsecutiveAppendsShouldReuse` | Performance | StringBuilder append chain | Chain `.append()` calls |
| `AvoidInstantiatingObjectsInLoops` | Performance | Object creation in loop | Move outside loop or use pool |
| `EmptyCatchBlock` | Error handling | Empty catch block | Log or rethrow exception |

### Common SpotBugs Bug Categories

| Pattern | Category | Description | Common Fix |
|---------|----------|-------------|-----------|
| `NP_NULL_*` | Correctness | Null pointer dereference | Add null-check |
| `EI_EXPOSE_REP*` | Malicious code | Exposes internal representation | Return defensive copy |
| `MS_*` | Malicious code | Mutable static field | Make final or use unmodifiable |
| `RCN_*` | Correctness | Redundant null-check | Simplify |
| `SBSC_USE_STRINGBUFFER` | Performance | String concatenation in loop | Use StringBuilder |
| `DM_STRING_CTOR` | Performance | Unnecessary String constructor | Use string literal |
| `EI2_*` | Bad practice | Storing reference to external object | Store defensive copy |

### Maven / Gradle Configuration

Maven (pom.xml):
```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-checkstyle-plugin</artifactId>
      <version>3.5.0</version>
      <configuration>
        <configLocation>google_checks.xml</configLocation>
        <failOnViolation>true</failOnViolation>
      </configuration>
    </plugin>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-pmd-plugin</artifactId>
      <version>3.24.0</version>
      <configuration>
        <rulesets>
          <ruleset>/rulesets/java/quickstart.xml</ruleset>
        </rulesets>
      </configuration>
    </plugin>
    <plugin>
      <groupId>com.github.spotbugs</groupId>
      <artifactId>spotbugs-maven-plugin</artifactId>
      <version><verify-latest></version>
    </plugin>
  </plugins>
</build>
```

Gradle (build.gradle):
```groovy
plugins {
    id 'checkstyle'
    id 'pmd'
    id 'com.github.spotbugs' version '6.0.18'
}

checkstyle {
    toolVersion = '10.17.0'
    config = resources.text.fromFile('config/checkstyle/checkstyle.xml')
}

pmd {
    toolVersion = '7.3.0'
    ruleSetFiles = files('config/pmd/pmd-rules.xml')
}

spotbugs {
    effort = 'max'
    reportLevel = 'medium'
}
```

### Spring Boot Linting

**Spring-specific checks**:
- `@Transactional` methods should not be private/final/static
- Controller methods should return proper response types
- Constructor injection over field injection (`@Autowired` on fields)
- Proper use of `@Service`, `@Repository`, `@Component` stereotypes
- No business logic in controllers

**Spring Boot rules to enforce**:
- Javadoc on public APIs
- No `System.out.println` (use SLF4J logger)
- Proper exception handling (no empty catch blocks)
- No utility class instantiation
- Indentation: 4 spaces (Spring convention) or 2 spaces (Google)
- Import ordering (no wildcard imports)

### Auto-Fix (limited)

Java linting has limited auto-fix — most violations require manual changes. Formatters:
```bash
# Maven — run all linters
mvn checkstyle:check pmd:check spotbugs:check

# spring-javaformat (Spring convention formatter)
mvn spring-javaformat:apply

# Gradle — run all linters
./gradlew checkstyleMain pmdMain spotbugsMain
./gradlew spotlessApply   # if spotless plugin configured

# Google Java Format (standalone)
java -jar google-java-format.jar --replace $(find . -name "*.java")
```

Suppress false positives sparingly: `@SuppressWarnings("RuleName")`. Verify with `mvn clean install` or `./gradlew clean build`.

---

## C#: dotnet format, Roslyn, StyleCop

### Detection

```bash
# Check for C# files
ls *.cs 2>/dev/null

# Check for .NET project files
[ -f *.csproj ] || [ -f *.sln ] || [ -f Directory.Build.props ]

# dotnet format (built into .NET 6+ SDK)
dotnet format --verify-no-changes --dry-run 2>/dev/null

# .editorconfig (drives dotnet format + Roslyn analyzers)
[ -f .editorconfig ]

# StyleCop / Roslyn analyzers
grep -q "StyleCop.Analyzers" *.csproj 2>/dev/null
grep -q "AnalysisLevel" *.csproj 2>/dev/null

# SDK version
dotnet --version 2>/dev/null
```

### Common Diagnostic IDs

| Diagnostic ID | Source | Description | Common Fix |
|---------------|--------|-------------|-----------|
| CA1062 | Roslyn | Validate arguments of public methods | Add null-check parameter validation |
| CA1822 | Roslyn | Mark members as static | Add `static` modifier |
| CA2007 | Roslyn | Consider configuring await | Add `ConfigureAwait(false)` |
| CA1063 | Roslyn | Implement IDisposable correctly | Follow standard dispose pattern |
| CA1031 | Roslyn | Do not catch general exception types | Catch specific exception types |
| SA1101 | StyleCop | Prefix local calls with `this.` | Add `this.` qualifier |
| SA1127 | StyleCop | Use generic constraint syntax | Use `where T : class` syntax |
| SA1200 | StyleCop | Using directive must be placed correctly | Move `using` inside/outside namespace |
| SA1600 | StyleCop | Elements must be documented | Add XML documentation comments |
| IDE0058 | IDE | Expression value is never used | Use discard `_` or assign to variable |
| IDE0090 | IDE | Use `new(...)` target-typed | Use target-typed `new()` |
| CS0168 | Compiler | Variable declared but never used | Remove unused variable |
| CS0219 | Compiler | Variable assigned but never used | Remove or use variable |

### .editorconfig

```ini
[*.cs]
indent_style = space
indent_size = 4
end_of_line = lf
dotnet_sort_system_directives_first = true
dotnet_separate_import_directive_groups = false
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_new_line_before_catch = true
csharp_new_line_before_finally = true
csharp_indent_braces = false
csharp_style_var_when_type_is_apparent = true:suggestion
csharp_prefer_braces = true:suggestion

# Naming conventions
dotnet_naming_rule.private_fields_underscore.symbols = private_fields
dotnet_naming_rule.private_fields_underscore.style = underscore_capital
dotnet_naming_rule.private_fields_underscore.severity = warning

# Analyzer severity
dotnet_diagnostic.CA1822.severity = warning
dotnet_diagnostic.CA2007.severity = warning
dotnet_diagnostic.IDE0003.severity = suggestion
```

### Analyzer Package Configuration

```xml
<!-- StyleCop (style rules) — in .csproj or Directory.Build.props -->
<PackageReference Include="StyleCop.Analyzers" Version="<verify-latest-stable>" PrivateAssets="all" />
<AdditionalFiles Include="stylecop.json" />

<!-- Roslyn (code quality) -->
<PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="<verify-latest>" PrivateAssets="all" />
<AnalysisLevel>latest-recommended</AnalysisLevel>
<TreatWarningsAsErrors>true</TreatWarningsAsErrors>
```

### .NET 10+ Specific Checks

- Primary constructors for dependency injection
- Collection expressions where applicable (`[]` syntax)
- Pattern matching improvements
- `required` keyword on properties
- File-scoped types for implementation hiding

**C# rules to enforce**: file-scoped namespaces (`namespace Foo;`); `var` when type is apparent, explicit otherwise; braces for all control structures; `using` order (System first); `Async` suffix on async methods; no magic numbers/strings; proper disposal (`using` declarations, `IAsyncDisposable`); record types for DTOs, classes for domain entities.

Suppress false positives sparingly: `[SuppressMessage(...)]`.

### Commands

```bash
# Fix all format issues (whitespace, braces, using directives)
dotnet format

# Targeted fixes
dotnet format whitespace
dotnet format style          # code style rules
dotnet format analyzers      # CAxxxx, IDExxxx fixes

# Check only (no changes)
dotnet format --verify-no-changes --dry-run
dotnet format --verify-no-changes --report report.json

# Verify after fixes
dotnet build -warnaserror
```

---

## Auto-Fix Strategy

1. Always attempt auto-fix FIRST (`ruff --fix`, `eslint --fix`, `dotnet format`, `spring-javaformat:apply`)
2. Re-run linter after auto-fix to confirm resolution
3. Report only remaining issues that require manual intervention
4. Never auto-fix files with uncommitted changes without explicit approval

## Severity Classification

| Severity | Meaning | Action |
|----------|---------|--------|
| ERROR | Code will fail or has bugs | Must fix before merge |
| WARNING | Potential issues or bad patterns | Should fix, can defer |
| INFO | Style/suggestions | Optional improvement |

## Troubleshooting Checklist

Before linting:
- [ ] Language(s) identified from file extensions and build files
- [ ] Linter installed and configured
- [ ] Package manager / build tool detected
- [ ] Configuration files exist

After linting:
- [ ] Linting completed successfully
- [ ] Auto-fix applied (if errors found)
- [ ] Errors categorized and displayed (per-language totals in multi-language projects)
- [ ] User receives per-language guidance
- [ ] Linting re-run after fixes

## Multi-Language Projects

1. Detect all languages first by scanning file extensions
2. Run each language's linter on its files (Ruff → .py, ESLint → .js/.ts, Checkstyle/SpotBugs → .java, dotnet format → .cs)
3. Merge results into one report; report per-language totals
4. Flag shared config issues (e.g., `.editorconfig`, Prettier) once

## References

- [Ruff documentation](https://docs.astral.sh/ruff/)
- [ESLint documentation](https://eslint.org/docs/latest/)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- [Checkstyle documentation](https://checkstyle.sourceforge.io/)
- [PMD rules index](https://docs.pmd-code.org/pmd-doc-7.x/pmd_rules_java.html)
- [SpotBugs bug descriptions](https://spotbugs.readthedocs.io/en/stable/bugDescriptions.html)
- [.NET coding conventions](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/style-rules/)
- [dotnet format documentation](https://learn.microsoft.com/dotnet/core/tools/dotnet-format)
- [StyleCop.Analyzers rules](https://github.com/DotNetAnalyzers/StyleCopAnalyzers)
- [Roslyn analyzer rules](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/)
- Framework: `linting-workflow-skill`
