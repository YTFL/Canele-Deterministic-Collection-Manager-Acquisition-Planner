# Canelé v2.0.0 Release Notes 🍮

> **Release Date:** October 26, 2026  
> **Target Platform:** Android (API 21+ / Android 5.0+)  
> **Tag:** `v2.0.0`

**Canelé v2.0.0** is our monumental, next-generation evolution! Canelé expands far beyond Books & Manga, introducing a complete **Multi-Profile Workspace Architecture**, specialized domain support with **Games Presets**, infinite flexibility with **Dynamic Custom Workspaces**, modern **Adaptive Launcher Icons & Splash Theming**, an overhauled **Multi-Space Subfolder Backup & Universal Import/Export System**, and deep architectural hardening.

---

## 🌟 What's New in Canelé v2.0.0

### 🏢 1. Multi-Profile Workspaces & Seamless Profile Switching
- **Independent Scoped Workspaces**: Create, manage, and switch between isolated collections. Each workspace maintains its own items, transactions, quotas, recommendation rules, cadence settings, and timeline configurations.
- **Top App Bar Workspace Switcher**: Quick workspace selector seamlessly integrated into the navigation title bar (`WorkspaceSwitcherAppBarTitle`). Tap to toggle between collections or launch the switcher modal.
- **Quick Switcher Modal**: Beautiful bottom sheet displaying active profiles with icons, entity counts, active workspace badge, and fast creation shortcuts.
- **Dedicated 3-Step Workspace Creator**: Create new spaces with customized names, domain presets (Books & Manga, Video Games, or Custom), and initial cadence configurations.
- **Zero-Downtime Database Migration**: Automatically migrates v1.x flat databases to v2.0 scoped profile boxes without data loss. Legacy collections are safely upgraded into the default Books & Manga workspace.

---

### 🎮 2. Dedicated Video Games Domain & Engine
- **First-Class Games Architecture**: Complete separation into a specialized game domain featuring `GameItem`, `GameSeries` (Franchises), and `GameRule`.
- **Zero-Rules & Game Cadence Enforcement**: Tailored acquisition rules and quota cadence designed specifically for video games—eliminating book/volume terminologies, chapter restocks, or print run jargon.
- **Games Dashboard & Backlog Management**:
  - Live status tracking across Backlog, Playing, and Completed states.
  - Interactive Priority Targets and Watchlist.
  - Dedicated Games acquisition logger supporting physical, digital, standard, and DLC entries.
- **Immersive Cover Grid & Game Detail View**:
  - High-density poster cover grid and banner presentation.
  - Franchise and standalone categorization.
  - DLC tracking linked chronologically to base game installations.
  - Custom game attributes including platforms, editions, user ratings, and completion dates.

---

### 🛠️ 3. Dynamic Custom Workspaces & Flexible Schemas
- **Tailor Canelé to Any Hobby**: Track vinyl records, board games, figures, scale models, films, audio gear, or bespoke physical collectibles.
- **Dynamic Field Schema Designer**:
  - Enable or disable fields on the fly: Cover Art, Platform / Format, Edition / Pressing, Rating, Price, Release Date, and Custom Attributes.
  - Custom statuses lifecycle (e.g. `Wishlist`, `Backlog`, `In Progress`, `Completed`, `Pre-ordered`).
- **Contextual Workspace Terminology**: Dynamic UI labels that automatically adjust across every screen (e.g., "Add Vinyl", "Artist", "Pressing", "Add Figure", "Manufacturer").
- **Adaptive Collection & Dashboard Views**: Dynamically alters table/grid presentation, checklist badges, and detail sheets according to your active schema.

---

### 📦 4. Multi-Space Subfolder Backup & Universal Data Portability
- **Subfolder-Structured Backup Format**: Multi-space backups now organize neatly into individual profile folders alongside a global `manifest.json`.
- **Selective Multi-Space Restore**: Pick and choose exactly which spaces to restore from a backup archive without overwriting unselected workspaces.
- **Universal Import & Export Engine**:
  - Seamlessly export individual spaces or entire multi-profile libraries to JSON or CSV.
  - Full backward compatibility for importing legacy v1.x single-workspace backup files.
  - Type-safe exporters and importers with dedicated engines for Books, Games, and Custom spaces.

---

### 🎨 5. Modern Adaptive Android Icons & Monochrome Theming
- **Android 13+ Themed / Monochrome Icons**: Full native support for Android dynamic colors and Monet monochrome launcher icons (`ic_launcher_monochrome.png`).
- **Precision Adaptive Icon Safe Zones**: Re-engineered 108dp canvas with 66dp safe-zone adherence across all densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- **Pre-Cropped Circular Legacy Icons**: Dedicated round mipmap assets for legacy launchers.
- **Canelé Caramelized Amber Splash Screen**: Seamless, flicker-free native splash transition styled in warm `#FCF7EC` and rich Canelé brand tones.

---

### ⚙️ 6. Workspace Settings, Storage Cleanup & Maintenance
- **Profile Management Studio**: Rename spaces, change icons, reconfigure custom schemas, or purge inactive workspaces.
- **Scoped Storage Cleanup**: Clean up orphan image caches, temporary export files, and deleted workspace remnants with one tap.
- **Fine-Grained Space Deletion**: Safe deletion confirmation with protection preventing deletion of the final remaining workspace.

---

### 🔧 7. Android Build, Engine & Stability Hardening
- **Gradle & NDK Modernization**: Fixed APK build failures related to NDK `abiFilters` conflict, tuned Gradle JVM daemon memory allocation, and streamlined build scripts.
- **Type-Safe Domain Exporters**: Resolved compilation issues and hardened custom metadata attributes across all export/import and test suites.
- **Comprehensive Test Coverage**: Over 110 automated tests covering workspace migrations, multi-space backups, game rule evaluators, schema customization, and UI flows.
- **Flutter Framework Modernization**: Cleaned all unused imports, removed unreferenced methods, and migrated `ReorderableListView` from deprecated `onReorder` to `onReorderItem`.

---

### 💬 8. In-App Help, Feedback Hub & UI Streamlining
- **GitHub Issue Templates Integration**:
  - Direct 1-tap links in Settings to the official GitHub Bug Report template (`bug_report.yml`) and Feature Request template (`feature_request.yml`).
  - Native Android `Intent.ACTION_VIEW` URL launcher with zero extra dependencies and automatic graceful clipboard fallback.
- **Strict 2-Line Glanceable Descriptions**: Clean, distraction-free subtitles strictly formatted to 2 lines with ellipsis overflow across all Settings tiles.
- **Streamlined Acquisition Logging**: Removed optional purchase notes input from both Books and Games acquisition sheets for a cleaner, faster logging flow.
- **Distraction-Free Game Management**: Removed game tags from game addition and collection views.

---

## 📋 Full Changelog Since v1.1.1

- `eb7cdde` **style(settings):** enforce strict 2-line descriptions and remove copy button
- `5a76561` **refactor:** remove purchase notes input and game tags from creation and acquisition sheets
- `d7a45fd` **fix(utils):** guard context with mounted check after await in external link helper
- `13a6573` **feat(settings):** add Help & Feedback section with direct GitHub issue template links
- `7b1efe4` **chore:** clean up unused imports, remove unreferenced element, and migrate onReorder to onReorderItem
- `4672cbf` **fix(custom):** resolve customAttributes compilation error in custom space exporter and tests
- `ee3a892` **feat(backup):** Multi-space subfolder backup architecture with dedicated Game and Custom domain models
- `a67b9e2` **feat(games):** Redesign Games domain with dedicated architecture, rules, UI parity, and zero-rules enforcement
- `a6c8551` **fix(android):** Fix APK build failure caused by ndk abiFilters conflict and tune Gradle JVM memory
- `9c02769` **feat(settings):** Multi-profile workspace management, storage cleanup, and final hardening (Canelé 2.0 Phase 6)
- `296faf2` **feat(backup-export):** Universal Import/Export & Multi-Profile Scoping Migration (Canelé 2.0 Phase 5)
- `cf79ad4` **feat(custom-workspaces):** Dynamic schema, custom terminology, and adaptive views (Canelé 2.0 Phase 4)
- `668a287` **feat(games):** Games Preset specialized engine, cover grid layout, backlog tracking, and detail view (Phase 3)
- `de78d88` **feat(workspaces):** Multi-Profile Workspaces & Architectural Scoping Migration (Canelé 2.0)

---

## 📦 Download & Installation

1. Download **`Canelé-v2.0.0.apk`** from the [GitHub Releases](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/releases/tag/v2.0.0) page.
2. Open the `.apk` file on your Android device and confirm installation.
3. Launch Canelé and explore multi-workspace tracking!

---

## 📄 License & Open Source

Canelé is free and open-source software licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.
- **Repository:** [https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner)
- **Bug Reports & Feature Requests:** [https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues)
