## Description

<!-- Provide a concise summary of the changes made and the motivation behind them. -->

## Related Issue

<!-- Link the relevant issue(s) resolved or impacted by this PR: e.g. Fixes #123, Closes #456 -->
Fixes #

---

## Type of Change

<!-- Mark the appropriate item with an [x]. -->
- [ ] `feat`: A new feature or user-facing functionality
- [ ] `fix`: A bug fix or defect correction
- [ ] `refactor`: Internal code refactoring without behavior changes
- [ ] `perf`: Performance or memory optimization
- [ ] `test`: Added or updated unit/widget tests
- [ ] `docs`: Documentation, README, or technical doc updates
- [ ] `chore`: Tooling, build config, dependency updates, or CI maintenance
- [ ] **BREAKING CHANGE**: Any change that alters stored schema format or existing API contracts

---

## Affected Subsystems

<!-- Select all domains touched by this pull request. -->
- [ ] **Core Collection**: Series, Volumes, Custom Statuses, Batch ops
- [ ] **Quota Engine**: Cadence arithmetic, forward auto-skip simulation, ledger buckets
- [ ] **Rule Studio**: Recommendation passes, waterfall evaluation, sorters, filters
- [ ] **Games Domain**: Game item model, backlog tracking, cover grid
- [ ] **Custom Spaces**: Dynamic schema, custom metadata attributes
- [ ] **Universal Importer / Exporter**: CSV, Excel XLSX, Goodreads/StoryGraph parsers
- [ ] **Persistence & Backups**: Hive boxes, debounced auto-backup engine, SAF
- [ ] **UI & Theming**: Material 3 screens, Pastry design tokens, sheets, dark mode
- [ ] **Android Platform**: Gradle, Manifest, JVM, ABI filters

---

## Architectural Invariants Verification

<!-- Canelé enforces strict architectural rules. Please verify each item. -->
- [ ] **100% Deterministic**: No black-box AI, random seeds, or nondeterministic heuristics introduced into quota or recommendation pipelines.
- [ ] **Local-First & Offline Privacy**: Zero mandatory network calls, analytics, or remote telemetry added.
- [ ] **Hive Schema Backward-Compatibility**: If any Hive model or persistence box schema was altered, migration logic and safety fallbacks are implemented.
- [ ] **Clean Architecture & Riverpod**: Strict separation between Presentation, Riverpod Notifiers, Domain Services, and Data Repositories maintained.

---

## Verification & Quality Assurance

<!-- How was this change tested? Check all that apply. -->
- [ ] Formatted using `dart format .`
- [ ] Static analysis clean via `flutter analyze` (zero errors, zero warnings)
- [ ] Automated tests pass via `flutter test`
- [ ] New unit or widget tests added covering new logic / edge cases
- [ ] Manually tested on an Android device or emulator:
  - **Device / Emulator**: <!-- e.g., Pixel 8 Pro Emulator (API 34) -->
  - **Build Mode**: `debug` / `release`

---

## UI Changes (Screenshots / Screen Recordings)

<!-- If this PR changes any visual UI components, provide side-by-side Before/After media. -->

| Before | After |
| :---: | :---: |
| *(Screenshot or N/A)* | *(Screenshot or N/A)* |

---

## Contributor Agreement

- [ ] I agree that my contributions are licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)** as outlined in the [LICENSE](LICENSE) file.
- [ ] My commits adhere to the [Conventional Commits](https://www.conventionalcommits.org/) standard outlined in [CONTRIBUTING.md](CONTRIBUTING.md).
