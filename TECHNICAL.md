# Canelé Technical Architecture & Engineering Documentation 🍮

This document provides a comprehensive technical overview of **Canelé**, detailing its architecture, state management patterns, local persistence models, mathematical algorithms, data processing pipelines, and Android platform configuration.

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [State Management Architecture (Riverpod 2.x)](#3-state-management-architecture-riverpod-2x)
4. [Persistence & Local Storage (Hive)](#4-persistence--local-storage-hive)
   - [Database Schema & Models](#database-schema--models)
   - [Schema Migration System](#schema-migration-system)
   - [Automated Debounced Backup Engine](#automated-debounced-backup-engine)
5. [Deterministic Quota Engine](#5-deterministic-quota-engine)
   - [Mathematical Formulation](#mathematical-formulation)
   - [Ahead-of-Schedule Forward Simulation](#ahead-of-schedule-forward-simulation)
6. [Recommendation Waterfall Pipeline (Rule Studio)](#6-recommendation-waterfall-pipeline-rule-studio)
   - [Pass Filtering & Multi-Attribute Sorters](#pass-filtering--multi-attribute-sorters)
   - [Candidate Deduplication & Slot Limits](#candidate-deduplication--slot-limits)
7. [Universal Importer & Regex Tokenizer](#7-universal-importer--regex-tokenizer)
   - [Title Cleaning & Noise Stripping](#title-cleaning--noise-stripping)
   - [Volume Number Parsing Heuristics](#volume-number-parsing-heuristics)
   - [Spreadsheet Engine (CSV & XLSX)](#spreadsheet-engine-csv--xlsx)
8. [Android Platform Configuration](#8-android-platform-configuration)
9. [Testing & Quality Assurance](#9-testing--quality-assurance)

---

## 1. High-Level Architecture

Canelé is engineered following **Clean Architecture** principles adapted for reactive, local-first Flutter applications. The codebase is organized into decoupled layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  (Material 3 UI, Pastry Design Tokens, Screens, Sheets)     │
└──────────────────────────────┬──────────────────────────────┘
                               │ Watches / Reads
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  State Management (Riverpod)                │
│ (StateNotifiers, Computed Providers, Dynamic Pipeline Ref) │
└──────────────────────────────┬──────────────────────────────┘
                               │ Invokes / Subscribes
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Domain & Business Logic                    │
│ (QuotaEngine, RuleEvaluator, SeriesService, Importer)       │
└──────────────────────────────┬──────────────────────────────┘
                               │ Reads / Writes
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Data Access & Persistence                  │
│   (Repositories, Schema Migrator, Hive Boxes, BackupEngine) │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Tech Stack & Dependencies

| Category | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Language** | [Dart](https://dart.dev) | `^3.12.2` | Core programming language with strict sound null safety |
| **Framework** | [Flutter](https://flutter.dev) | SDK 3.x | Cross-platform UI toolkit targeting Android (API 21+) |
| **State Management** | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | `^2.5.1` | Unidirectional reactive state management & dependency injection |
| **Embedded Storage** | [hive](https://pub.dev/packages/hive) & [hive_flutter](https://pub.dev/packages/hive_flutter) | `^2.2.3` / `^1.1.0` | Ultra-fast, zero-native-dependency key-value NoSQL storage |
| **Spreadsheets** | [csv](https://pub.dev/packages/csv) & [excel](https://pub.dev/packages/excel) | `^6.0.0` / `^4.0.6` | Universal CSV & binary Excel workbook parsing/generation |
| **Typography** | [google_fonts](https://pub.dev/packages/google_fonts) | `^6.2.1` | Embedded *Plus Jakarta Sans* typeface |
| **System Integrations**| [file_picker](https://pub.dev/packages/file_picker), [share_plus](https://pub.dev/packages/share_plus) | `^8.0.0` / `^9.0.0` | Android storage access framework and system share intents |
| **Identifiers & Time** | [uuid](https://pub.dev/packages/uuid), [intl](https://pub.dev/packages/intl) | `^4.4.0` / `^0.19.0` | RFC 4122 v4 UUIDs, localized date/number formatting |

---

## 3. State Management Architecture (Riverpod 2.x)

The application maintains a strictly unidirectional state flow using Riverpod `StateNotifierProvider`s and derived computed `Provider`s:

### Core Notifier Providers:
- `seriesNotifierProvider`: Manages `List<Series>` collection state and CRUD operations.
- `volumesNotifierProvider`: Manages `List<Volume>` records across all series.
- `transactionsNotifierProvider`: Manages `List<PurchaseTransaction>` ledger records.
- `ruleConfigNotifierProvider`: Manages user timeline configuration, monthly cadence, and bonus settings (`RuleConfig`).
- `rulesNotifierProvider`: Manages the ordered recommendation pass pipeline (`List<RuleModel>`).
- `themeNotifierProvider`: Manages application theme mode (`ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`).
- `backupNotifierProvider`: Listens to live storage mutations and manages auto-backup state.

### Computed Derived Providers:
```dart
// Computes dynamic quota metrics based on transactions and ruleConfig
final quotaProvider = Provider<QuotaSummary>((ref) {
  final config = ref.watch(ruleConfigNotifierProvider);
  final transactions = ref.watch(transactionsNotifierProvider);
  return QuotaEngine.calculate(config: config, transactions: transactions);
});

// Computes 4-slot recommendation queue using active passes
final recommendationSlotsProvider = Provider<List<RecommendationCandidate>>((ref) {
  final series = ref.watch(seriesNotifierProvider);
  final volumes = ref.watch(volumesNotifierProvider);
  final passes = ref.watch(rulesNotifierProvider);
  return RuleEvaluator.evaluate(seriesList: series, volumeList: volumes, passes: passes);
});
```

---

## 4. Persistence & Local Storage (Hive)

### Database Schema & Models

Data is structured in isolated Hive boxes storing JSON-compatible key-value maps:

#### 1. `Series` Model (`seriesBox`)
```dart
class Series {
  final String id;                    // UUID v4
  final String title;                 // Canonical series name
  final String type;                  // 'lightNovel', 'manga', 'comic', 'novel', etc.
  final String collectionStatus;      // 'active', 'wishlist', 'completed', 'dropped'
  final String releaseStatus;         // 'ongoing', 'completed', 'hiatus'
  final int totalReleasedVolumes;     // Total published volumes
  final List<String> tags;            // User tags e.g. ['restock_watch', 'favorite']
  final Map<String, dynamic> customMetadata;
}
```

#### 2. `Volume` Model (`volumesBox`)
```dart
class Volume {
  final String id;                    // UUID v4
  final String seriesId;              // Foreign key -> Series.id
  final double volumeNumber;          // Supports decimals (e.g., 1.0, 11.5)
  final DateTime? releaseDate;        // Publication release date
  final bool isOwned;                 // Ownership flag
  final bool isGift;                  // Gift flag
  final String availability;          // 'available', 'preorder', 'backorder', 'outOfPrint'
  final bool isRestockedWatchlist;    // Flag for restock priority triggering
}
```

#### 3. `PurchaseTransaction` Model (`transactionsBox`)
```dart
class PurchaseTransaction {
  final String id;                    // UUID v4
  final String volumeId;              // Foreign key -> Volume.id
  final DateTime purchaseDate;        // Transaction date
  final String quotaBucket;           // 'regular', 'bonus', 'gift'
  final double price;                 // Purchase price
  final String? notes;                // Transaction notes
}
```

#### 4. `RuleConfig` Model (`ruleConfigBox`)
```dart
class RuleConfig {
  final DateTime timelineStartDate;   // Start of deterministic cadence
  final int defaultRegularPerMonth;   // Monthly allowance (default: 1)
  final List<int> bonusMonths;        // Annual recurring bonus months [5, 12]
  final List<int> recurringNoBookMonths; // Annual recurring hiatus months [6]
  final List<String> noBookMonths;    // Historical one-off hiatus keys ['2024-06']
  final Map<String, int> customBonusLedger; // One-off monthly bonus keys {'2024-08': 2}
  final bool isOnboardingCompleted;   // Wizard completion flag
}
```

---

### Schema Migration System

Canelé features an explicit `DatabaseMigrator` (`lib/core/database/database_migrator.dart`) that manages versioned migrations seamlessly across updates without data loss.

- **Version 1 to Version 2**: Added `recurringNoBookMonths` support to `RuleConfig` and backfilled existing configurations with empty recurring hiatus arrays.
- Automatic version stamping in Hive metadata box `metadataBox.get('db_version')`.

---

### Automated Debounced Backup Engine

The `BackupService` (`lib/services/backup_service.dart`) automatically listens to Hive box mutations:
1. When a change is detected on `seriesBox`, `volumesBox`, `transactionsBox`, or `ruleConfigBox`, a timer is started.
2. Changes within a 2-second window are debounced to prevent excessive disk I/O.
3. Automatically writes timestamped state backups to on-device storage with rolling rotation (maintaining latest and previous backups).
4. Includes safe pausing and resumption mechanisms during bulk restore operations to prevent feedback loops.

---

## 5. Deterministic Quota Engine

### Mathematical Formulation

Given:
- $T_{\text{start}}$: Timeline start date (truncated to month $M_{\text{start}}$)
- $M_{\text{now}}$: Current active month
- $R_{\text{perMonth}}$: Base regular quota allowance per active month
- $B_{\text{months}} \subseteq \{1, \dots, 12\}$: Set of recurring bonus months
- $H_{\text{rec}} \subseteq \{1, \dots, 12\}$: Set of recurring hiatus months
- $H_{\text{oneOff}} \subseteq \{\text{"YYYY-MM"}\}$: Set of one-off hiatus months
- $B_{\text{custom}}(\text{"YYYY-MM"})$: Custom one-off bonus ledger

For each month $m \in [M_{\text{start}}, M_{\text{now}}]$:
$$\text{isNoBook}(m) = (m.\text{month} \in H_{\text{rec}}) \lor (\text{key}(m) \in H_{\text{oneOff}})$$
$$\text{ExpectedRegular}(m) = \begin{cases} 0 & \text{if } \text{isNoBook}(m) \\ R_{\text{perMonth}} & \text{otherwise} \end{cases}$$
$$\text{ExpectedBonus}(m) = \mathbb{I}(m.\text{month} \in B_{\text{months}}) + B_{\text{custom}}(\text{key}(m))$$

Total Quota Balances:
$$\text{RegularQuota}_{\text{total}} = \sum_{m} \text{ExpectedRegular}(m)$$
$$\text{BonusQuota}_{\text{total}} = \sum_{m} \text{ExpectedBonus}(m)$$
$$\text{RegularBalance} = \text{RegularQuota}_{\text{total}} - \text{Count}(\text{Transactions}_{\text{regular}})$$
$$\text{BonusBalance} = \text{BonusQuota}_{\text{total}} - \text{Count}(\text{Transactions}_{\text{bonus}})$$

---

### Ahead-of-Schedule Forward Simulation

When a user has bought more books than their accumulated quota ($\text{TotalBalance} < 0$), the engine runs a forward timeline simulation starting from $M_{\text{now}} + 1$:
1. Progressively accumulates projected monthly regular and bonus allowances into a deficit balance.
2. Identifies the exact forward month where the deficit is reduced to $\ge 0$.
3. Returns `projectedCatchUpMonth` (e.g. *"November 2026"*), displayed in the UI to give users clarity on when their budget resumes.

---

## 6. Recommendation Waterfall Pipeline (Rule Studio)

The `RuleEvaluator` (`lib/services/rule_evaluator.dart`) calculates the 4 target acquisition slots on the dashboard:

```
Unowned Released Volumes in Active Series
                  │
                  ▼
         ┌──────────────────┐
         │  Pass 1: Restock │ ──► Take up to Slot Limit ──► [Slot 1, 2]
         └────────┬─────────┘
                  │ Remaining Unfilled Slots
                  ▼
         ┌──────────────────┐
         │  Pass 2: Caught  │ ──► Take up to Slot Limit ──► [Slot 3]
         └────────┬─────────┘
                  │ Remaining Unfilled Slots
                  ▼
         ┌──────────────────┐
         │  Pass 3: Highest │ ──► Take up to Slot Limit ──► [Slot 4]
         │    Completion %  │
         └──────────────────┘
```

### Filtering & Sorting Invariants:
- Strictly excludes unreleased / future-dated volumes ($D_{\text{release}} > \text{now}$).
- Strictly excludes Out of Stock and Out of Print volumes (unless tagged as restocked).
- Strictly excludes Completed, Wishlist, and Dropped series from monthly acquisition targets.
- Enforces **1-volume-per-series deduplication** across passes when total candidate series $\ge 4$, ensuring diverse recommendations.

---

## 7. Universal Importer & Regex Tokenizer

The `UniversalImporter` (`lib/services/universal_importer.dart`) standardizes messy book metadata using a multi-pass regex pipeline:

### 1. Title Noise Normalization
```dart
// Strips binding and catalog formats:
static final _formatNoisePattern = RegExp(
  r'\s*[\(\[\{](?:light novel|manga|novel|comic|paperback|hardcover|kindle edition|audiobook|ebook|graphic novel)[\)\]\}]',
  caseSensitive: false,
);

// Strips Goodreads catalog suffixes (e.g., "(86 - Eighty-Six, #1)"):
static final _goodreadsSeriesPattern = RegExp(
  r'\s*[\(\[](?:[^\(\)\[\]]+,\s*)?#(\d+(?:\.\d+)?)[\)\]]',
  caseSensitive: false,
);
```

### 2. Volume Extraction
Extracts both integer and decimal numbers across diverse formats:
```dart
static final _volumeExtractionPattern = RegExp(
  r'(?:vol(?:ume)?\.?|book|v\.?|#|\b)\s*(\d+(?:\.\d+)?)\b',
  caseSensitive: false,
);
```

---

## 8. Android Platform Configuration

- **Minimum SDK**: `minSdk = 21` (Android 5.0 Lollipop)
- **Target / Compile SDK**: `compileSdk = 36`, `targetSdk = 36`
- **Application ID & Namespace**: `com.ytfl.canale`
- **JVM Target Compatibility**: Java 17 (`JavaVersion.VERSION_17`)
- **ABI Architecture Filters**: `arm64-v8a` optimized release builds
- **Hardware Acceleration**: Enabled in `AndroidManifest.xml`
- **Storage Access**: Uses Android Storage Access Framework (SAF) via `file_picker` and `share_plus` with `requestLegacyExternalStorage="true"` fallback for maximum device compatibility.

---

## 9. Testing & Quality Assurance

The codebase includes an automated test suite with 56 unit and widget tests covering all critical invariants:

```bash
# Run test suite
flutter test

# Run static analysis
flutter analyze
```

### Core Test Suites:
- `test/quota_engine_test.dart`: Validates deterministic arithmetic, multi-bucket ledgers, hiatus exclusions, and auto-skip forward simulations.
- `test/rule_evaluator_test.dart`: Validates priority order shifts, candidate deduplication, release date filters, and slot allocations.
- `test/series_service_test.dart`: Validates automatic volume generation, standalone series handling, and batch operations.
- `test/series_status_prompt_test.dart`: Validates automated lifecycle state transition helpers.
- `test/universal_exporter_test.dart`: Validates CSV and Excel XLSX binary structure generation.
- `test/backup_service_test.dart`: Validates auto-backup debouncing, pause/resume mechanisms, and merge operations.
- `test/widget_test.dart`: Comprehensive widget testing for Dashboard cards, Onboarding steps, Rule Studio tabs, and Stats screens.
