# Changelog

All notable changes to **Canelé** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-01

### Added

#### 🏠 Home Dashboard & Quota Balance
- **Real-Time Quota Ledger**:
  - Live balance tiles tracking **Regular allowance**, **Bonus books**, and **Total Open slots** available to spend this month.
  - Transparent arithmetic calculation based strictly on your start month and monthly purchasing pace—no hidden algorithms.
- **Ahead-of-Schedule Tracker**:
  - Automatically calculates when your budget resumes if you purchase books in advance (e.g. *"Normal quota pace catches up in November 2026"*).
- **Quick Quota Actions**:
  - **+1 Quick Bonus**: Instantly add an extra book allowance to the current month (for conventions, rewards, or special gifts).
  - **Skip Month**: Mark the current month as a hiatus with 0 regular quota.
- **4 Priority Acquisition Target Slots**:
  - Generates your top 4 book recommendations right on your home screen based on your custom rule studio pipeline.
- **Dashboard Stat Shortcuts**:
  - Tap directly on Total Owned, Active Series, or Total Outlay to jump straight into detailed analytics.

#### 📚 Series & Volume Management
- **Decimal & Fractional Volumes**:
  - Complete support for decimal numbers (e.g. *Vol. 11.5* side stories, special chapters, .5 bonus editions, unnumbered omnibus books).
- **Fast Series Creation Sheet**:
  - **Series Mode**: Automatically generates volume sequences (1..N) with your choice of initial owned count.
  - **Single Mode**: Quickly add standalone novels, one-shots, or artbooks.
  - Set custom tags, format types (Light Novel, Manga, Comic, Novel, Artbook, Custom), and ongoing release status.
- **Granular Volume Tracking**:
  - Tap any volume to view/edit release date, purchase price, purchase date, and personal notes.
  - Track live availability statuses: *Available*, *Pre-Order*, *Backorder*, and *Out of Print*.
  - Star hard-to-find books with the **Restock Watchlist** toggle.
  - Mark volumes as a Regular purchase, Bonus purchase, or Gift (gifts do not deduct from your budget).
- **One-Tap Bulk Marking**:
  - Mark entire volume ranges (e.g. *Vols. 1–12*) as owned or unowned in seconds from the series detail screen.
- **Smart Lifecycle Assistant**:
  - Automatically prompts to move a series from **Wishlist to Active** when you acquire its first volume.
  - Automatically prompts to move an **Active series to Completed** when you collect its final volume.

#### 🎯 Rule Studio & Custom Recommendation Pipeline
- **Customizable 4-Slot Priority Waterfall**:
  - Take complete control over which books appear in your dashboard recommendation queue.
  - Drag and drop to reorder rule priorities with real-time slot redistribution.
  - Enable or disable individual rules and set maximum slot limits per rule.
- **Pre-Built Strategy Passes**:
  - 🔄 **Stay Caught Up**: Prioritizes active series where you are only 1 volume behind current releases.
  - 🔔 **Restock Watchlist**: Highlights rare volumes that have returned to stock.
  - 📊 **Cascading Completion**: Suggests series closest to 100% completion so you can finish what you started.
  - ⏩ **Sequential Next Volume**: Always recommends the lowest unowned volume number in order.
- **Custom Rule Builder**:
  - Filter by collection status (*Active*, *Wishlist*, or *Any*).
  - Filter by missing count (*Missing exactly 1*, *Missing 2 or fewer*, or *Any*).
  - Filter by availability (*Available*, *Pre-Order*, *Backorder*, *Out of Print*).
  - Sort by Oldest Release Date, Newest Release Date, Completion Percentage, or Volume Number.
- **Cadence Configuration Studio**:
  - Adjust your timeline start month and monthly book pace.
  - Select annual recurring bonus months (e.g. birthday or holiday months).
  - Select annual recurring hiatus months (e.g. summer break).
  - Add historical one-off bonuses or past hiatus months.

#### 📦 Universal File Importer (Migrate Your Library)
- **One-Click Imports**:
  - Ingest reading history from **Goodreads CSV**, **StoryGraph CSV**, custom **CSV**, and **Microsoft Excel (.xlsx)** spreadsheets.
- **Smart Metadata Cleaner**:
  - Automatically strips format noise like `(Light Novel)`, `(Paperback)`, `(Manga)`, `(Hardcover)`, or Goodreads `#vol` tags.
  - Extracts clean series titles and volume numbers automatically.
- **Interactive Pre-Commit Review Screen**:
  - Visual review modal displaying all detected books, inferred formats, and volume spans.
  - Toggle inclusion on/off globally or per-series.
  - Edit titles, volume counts, and formats directly before importing.
  - Duplicate detection to prevent duplicate entries in your library.

#### 📊 Statistics & Deep Insights
- **Collection Breakdown**:
  - Overview of Total Owned Volumes, Total Series, and Total Financial Outlay.
  - Progress percentages across all ongoing series.
- **Acquisition Velocity**:
  - Visual breakdown of Regular vs. Bonus quota usage and historical purchasing pace.
  - Bought vs. Gifted ratio comparison.
- **Format Distribution**:
  - Visual breakdown of your library across Manga, Light Novels, Comics, and Novels.

#### 💾 Data Portability & Automatic Backups
- **100% Offline & Private**:
  - Zero cloud accounts, zero logins, zero ads, and zero telemetry tracking. All data lives on your device.
- **Full State Backup & Restore**:
  - Export and restore your complete library, settings, and custom rules via single-tap `.canele` or `.json` files or clipboard.
- **Spreadsheet Exports**:
  - Export your library to clean `.csv` or formatted Microsoft Excel (`.xlsx`) workbooks anytime.
- **Automated Hands-Free Backups**:
  - Automatically creates rolling local backups in the background to your chosen folder.
  - Built-in safe wipe utility with confirmation dialogs.

#### 🚀 In-App Update Engine
- **Seamless GitHub Releases**:
  - Check for app updates directly within the app without opening a browser.
  - One-tap APK download and direct Android package installer prompt.

#### 🍮 Bespoke Canelé Pastry Design System
- **French Canelé Palette**:
  - Warm custard creams (`#FDFBF7`), caramelized ambers (`#8C4A2F`), warm pastry crusts (`#EADBCE`), and rich espresso darks (`#251C17`).
- **Theme Modes**: Full support for **Light Mode**, **Dark Mode**, and **System Auto Mode**.
- **3x3 Grid Year Picker**: Fast and responsive decade-by-decade date selector.
- **4-Step Onboarding Setup Wizard**: Friendly step-by-step introduction to set up your timeline and rules on first launch.

---

[1.0.0]: https://github.com/YTFL/Canale/releases/tag/v1.0.0
