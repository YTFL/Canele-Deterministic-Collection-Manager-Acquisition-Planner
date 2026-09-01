# Changelog

All notable changes to **Canelé** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-01

### Added
- **Deterministic Quota Engine**:
  - Transparent arithmetic calculation based on user-defined timeline start date and monthly quota allowances.
  - Multi-bucket quota separation distinguishing **Regular**, **Bonus**, and **Gift** allocations.
  - Ahead-of-schedule auto-skip simulation with exact forward catch-up month calculation (e.g., *"November 2026"*).
  - Configurable recurring annual bonus months (e.g., birthday/holiday bonus months).
  - Configurable recurring and historical "No-Book Months" with timeline exclusion rules.
- **Multi-Pass Acquisition Waterfall (Rule Studio)**:
  - 4-slot acquisition target pipeline on the home dashboard.
  - Dynamic rule prioritization system with draggable reordering and per-pass candidate limits.
  - Built-in strategies: *Stay Caught Up*, *Restock Watchlist*, *Cascading Completion*, and *Sequential Next Volume*.
  - Custom rule creation with status filters (`active`, `wishlist`, `any`), missing count triggers (`equals_1`, `less_equal_2`, `any`), and multi-attribute sorting (`releaseDateAsc`, `releaseDateDesc`, `seriesCompletionDesc`, `volumeNumberAsc`).
- **Series & Volume Library**:
  - Full support for decimal and fractional volumes (e.g., *Vol. 11.5* side stories, special chapters, unnumbered omnibus editions).
  - One-tap Bulk Marking modal to rapidly mark or unmark volume sequences.
  - Granular stock tracking: *Available*, *Pre-Order*, *Backorder*, and *Out of Print*.
  - Smart status management with automated lifecycle prompts (e.g., Wishlist to Active when acquiring a volume; Active to Completed when collecting the final volume).
- **Universal File Importer**:
  - Support for **Goodreads CSV**, **StoryGraph CSV**, generic **CSV**, and **Microsoft Excel (.xlsx)** files.
  - Intelligent regex title cleaner that strips format noise (`(Light Novel)`, `(Paperback)`, `(Hardcover)`, `(Kindle Edition)`) and extracts clean series names and volume numbers.
  - Interactive pre-commit review screen allowing users to toggle, inspect, and bulk-import books.
- **Statistics & Deep Insights Screen**:
  - Metrics for Total Owned volumes, Total Series, Acquisition Pace, and Spending Outlays.
  - Visual breakdown charts for format distribution and bought vs. gifted ratios.
  - Direct dashboard navigation into detailed insights.
- **Data Portability & Auto-Backup**:
  - Full application state export and restore (`.canele` / `.json`).
  - Collection exports to `.csv` and formatted `.xlsx` workbooks.
  - Non-intrusive background auto-backup service with debounced writes and rolling history.
  - Safety-first complete database wipe with explicit confirmation dialogs.
- **Bespoke Canelé Pastry Design System**:
  - Warm French pastry palette (Custard Cream, Caramelized Amber, Warm Crust, Deep Caramel).
  - System, Light, and Dark Mode themes.
  - 3x3 grid year pagination selector dialog.

[1.0.0]: https://github.com/YTFL/Canale/releases/tag/v1.0.0
