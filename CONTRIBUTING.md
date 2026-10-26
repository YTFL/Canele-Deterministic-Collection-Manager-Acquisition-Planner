# Contributing to Canelé 🍮

Thank you for your interest in contributing to **Canelé**! Canelé is an open-source, local-first Android collection manager and acquisition planner built on deterministic mathematical models and uncompromising privacy.

We welcome contributions of all kinds: bug fixes, new features, rule studio passes, documentation enhancements, translations, and architectural improvements.

---

## Table of Contents

- [Code of Conduct & Community Values](#code-of-conduct--community-values)
- [Core Architectural Invariants](#core-architectural-invariants)
- [Getting Started & Local Setup](#getting-started--local-setup)
- [Development Workflow](#development-workflow)
  - [Branching Model](#branching-model)
  - [Commit Message Guidelines](#commit-message-guidelines)
  - [Code Style & Formatting](#code-style--formatting)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [Submitting Issues](#submitting-issues)
- [Submitting Pull Requests](#submitting-pull-requests)
- [License](#license)

---

## Code of Conduct & Community Values

We strive to maintain a respectful, welcoming, and collaborative community.
- **Constructive Communication**: Be courteous, constructive, and respectful when reviewing code or discussing features.
- **Privacy First**: Never post screenshots or logs containing personal identification, sensitive financial data, or real private collection files in public issues or PRs.
- **Transparency**: Keep design decisions documented in code comments, PR descriptions, and architectural records.

---

## Core Architectural Invariants

Canelé is built around strict engineering principles. Every contribution must respect these invariants:

### 1. 100% Deterministic (Zero Black-Box AI)
- **No Stochastic Recommendations**: Quota allocations, forward catch-up projections, and Rule Studio candidate recommendations are strictly derived from declared math, explicit priorities, and auditable sort passes.
- Core business logic must never rely on opaque machine learning models or probabilistic heuristics. Given the same state, outputs must always be 100% identical and reproducible.

### 2. Local-First & Absolute Privacy
- **Zero Cloud Accounts**: Canelé does not require sign-ins, remote accounts, or third-party cloud synchronization.
- **Zero Telemetry**: No tracking libraries, analytics SDKs, or background telemetry.
- **Zero Mandatory Network Calls**: The app operates entirely offline. Any optional network interaction (e.g. currency conversion lookups or update checks) must fail gracefully without impacting core functionality and must preserve user anonymity.

### 3. Clean Architecture & Unidirectional State Flow
- Follow the established layer boundaries:
  - **Presentation Layer** (`lib/ui/`, `lib/features/`): Material 3 widgets, screens, sheets, dialogs. Never access database boxes directly.
  - **State Management** (`lib/providers/`): Riverpod `StateNotifierProvider`s and derived computed `Provider`s. State mutations must be immutable and unidirectional.
  - **Domain Layer** (`lib/models/`, `lib/services/`): Business logic, quota calculations (`QuotaEngine`), rule evaluations (`RuleEvaluator`), and importers.
  - **Data Layer** (`lib/repositories/`): Hive storage adapters, box abstractions, and schema migrators.

### 4. Safe Persistence & Migration Guarantees
- All user collection data is stored in on-device **Hive** boxes.
- Any change to model schemas (`Series`, `Volume`, `PurchaseTransaction`, `RuleConfig`, `GameItem`, etc.) must include an explicit backward-compatible migration strategy in the persistence layer.
- Never write destructive file operations without safety checks and automated backup triggers.

### 5. Design Consistency (Pastry System)
- Use Canelé's design tokens (warm crust, caramel, and vanilla hues) and Material 3 design standards rather than hardcoded colors or ad-hoc margins.
- Support both Light and Dark themes seamlessly.

---

## Getting Started & Local Setup

### Prerequisites

Ensure you have the following installed on your development machine:

1. **Flutter SDK**: `>= 3.22.0` ([Flutter Installation Guide](https://flutter.dev/docs/get-started/install))
2. **Dart SDK**: `>= 3.12.2` (Bundled with Flutter)
3. **Android Studio** or **VS Code** with Flutter and Dart extensions
4. **Android SDK**:
   - `minSdkVersion`: 21 (Android 5.0 Lollipop)
   - `compileSdkVersion`: 36
   - `targetSdkVersion`: 36
5. **Java Development Kit**: JDK 17 (Required by Gradle for Android build tools)
6. **Git**

### Initial Setup

1. **Fork and Clone the Repository**:
   ```bash
   git clone https://github.com/<your-username>/Canele-Deterministic-Collection-Manager-Acquisition-Planner.git
   cd Canele-Deterministic-Collection-Manager-Acquisition-Planner
   ```

2. **Add Upstream Remote**:
   ```bash
   git remote add upstream https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner.git
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Verify Your Environment**:
   ```bash
   flutter doctor
   ```

5. **Run the App in Debug Mode**:
   - Start an Android emulator or connect a physical Android device with USB debugging enabled.
   - Run:
     ```bash
     flutter run -d android
     ```

---

## Development Workflow

### Branching Model

Always create a dedicated topic branch off `main` for your work. Keep branches small and focused:

```bash
# Update local main
git checkout main
git pull upstream main

# Create a feature or bugfix branch
git checkout -b feat/custom-rule-filter
# or
git checkout -b fix/importer-title-cleaning
```

### Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification. Standardizing commit messages keeps the changelog clear and automated release generation reliable.

**Format**:
```text
<type>(<scope>): <short description>

[optional body explaining context, motivation, or technical details]

[optional footer(s), e.g., Fixes #123]
```

**Types**:
- `feat`: A new feature, UI screen, or domain capability
- `fix`: A bug fix or defect correction
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance or memory usage
- `test`: Adding missing tests or correcting existing tests
- `docs`: Documentation changes only
- `chore`: Maintenance tasks, dependency bumps, or build tool adjustments

**Common Scopes**:
- `quota`: Deterministic Quota Engine and cadence math
- `rules`: Rule Studio and acquisition waterfall pipeline
- `games`: Games domain space and backlog engine
- `custom`: Custom workspace preset and dynamic schema
- `importer`: Universal CSV/XLSX parser and regex title cleaning
- `backup`: Storage backup engine, SAF integration, and file export
- `ui`: Presentation widgets, sheets, dialogs, and themes
- `android`: Gradle, manifest, JVM, or native platform configurations

**Examples**:
```text
feat(rules): add release-date lookahead filter to stay-caught-up pass
fix(importer): prevent null pointer on unformatted StoryGraph date cells
docs(technical): document Hive multi-space subfolder persistence schema
```

### Code Style & Formatting

We adhere strictly to official Dart style guidelines and `package:flutter_lints`:

1. **Auto-Format Code**:
   Always run the Dart formatter before committing:
   ```bash
   dart format .
   ```

2. **Static Analysis**:
   Ensure static analysis reports zero errors and zero warnings:
   ```bash
   flutter analyze
   ```

3. **Code Conventions**:
   - Avoid `print()` calls in production code. Use appropriate logging or debug guards where needed.
   - Specify explicit types where inference could be ambiguous.
   - Follow immutable state models with `copyWith` methods for Riverpod state objects.

---

## Testing & Quality Assurance

Canelé values test coverage for all mathematical engines, recommendation passes, data parsers, and backup routines.

### Running Tests Locally

Run the complete test suite before submitting any changes:
```bash
flutter test
```

You can also use our provided validation script to run formatting, analysis, and tests in one step:
- **On Linux / macOS**:
  ```bash
  ./tool/verify.sh
  ```
- **On Windows (PowerShell)**:
  ```powershell
  .\tool\verify.ps1
  ```

### Writing New Tests
- **Business Logic & Math**: If you modify `QuotaEngine`, `RuleEvaluator`, or any service, you **must** add corresponding unit tests in `test/`.
- **Importers / Parsers**: Add test cases covering edge cases (e.g. malformed CSV rows, exotic volume numbers like *Vol. 11.5* or *Part 2*).
- **UI & Widget Tests**: Ensure complex UI states have widget test coverage in `test/widget_test.dart` or dedicated widget test files.

---

## Submitting Issues

We use structured GitHub Issue Forms to ensure all necessary diagnostic information is gathered promptly:

- **[Bug Reports](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues/new?template=bug_report.yml)**: Provide clear reproduction steps, affected domain, device model, Android OS version, and app version.
- **[Feature Requests](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues/new?template=feature_request.yml)**: Explain the motivation, proposed workflow, and how the feature aligns with Canelé's 100% deterministic and local-first invariants.
- **[Documentation](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues/new?template=documentation.yml)**: Report typos, missing guides, or propose additions to `TECHNICAL.md` or `README.md`.

*Before opening an issue, please search existing issues to avoid duplicates.*

---

## Submitting Pull Requests

1. **Keep Pull Requests Focused**: A PR should ideally solve one specific problem or add one cohesive feature.
2. **Verify Against CI**:
   - `dart format --output=none --set-exit-if-changed .` passes cleanly.
   - `flutter analyze` passes with 0 issues.
   - `flutter test` completes with 100% pass rate.
3. **Fill Out the PR Template**:
   - Complete every section in the pull request template.
   - If your change affects UI, attach Before & After screenshots or a brief screen recording.
   - Link the relevant issue (e.g., `Fixes #42`).
4. **Code Review**:
   - A maintainer will review your pull request.
   - Address feedback in a timely manner. Pushing new commits to your branch will automatically update the PR.

---

## License

Canelé is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. By contributing to Canelé, you agree that your contributions will be licensed under the AGPLv3. See [LICENSE](LICENSE) for details.
