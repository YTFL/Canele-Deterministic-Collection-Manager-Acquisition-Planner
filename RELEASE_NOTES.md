# Canelé v1.0.0 Release Notes 🍮

> **Release Date:** September 1, 2026  
> **Target Platform:** Android (API 21+ / Android 5.0+)  
> **Tag:** `v1.0.0`

I am thrilled to announce the official **v1.0.0** release of **Canelé**, a local-first, 100% deterministic book collection manager and acquisition planner for Android!

Canelé is built specifically for light novel, manga, comic, and book collectors who want to pace their reading and purchasing habits deliberately—without relying on black-box recommendation algorithms, ad networks, or cloud subscriptions.

---

## 🌟 What's in Canelé v1.0.0

### 📐 1. Deterministic Quota & Cadence Engine
- **Transparent Arithmetic**: Your monthly allowance is calculated purely from your declared start month, monthly cadence, scheduled bonus months, and purchase logs.
- **Three Separate Quota Buckets**:
  - **Regular Quota**: Your planned monthly book budget (e.g. 1 book/month).
  - **Bonus Quota**: Extra allocations for birthdays, holidays, conventions, or personal milestones.
  - **Gifts**: Log received gifts without deducting from your purchasing quota.
- **Ahead-of-Schedule Tracker**: If you buy books ahead of schedule, Canelé automatically calculates your exact catch-up month (e.g. *"Normal quota pace catches up in November 2026"*).
- **Hiatus & No-Book Months**: Schedule recurring annual hiatus months (e.g. June vacation) or one-off skip months where quota does not accumulate.
- **Quick Actions**: Tap `+1 Bonus` to instantly credit an extra book, or `Skip Month` to take a break.

### 🎯 2. Rule Studio & 4-Slot Priority Waterfall
- **4 Priority Targets**: Automatically fills your home screen with the top 4 books you should buy next.
- **Drag-and-Drop Prioritization**: Reorder rules dynamically with live slot redistribution.
- **Pre-Built Strategy Passes**:
  - 🔄 **Stay Caught Up**: Prioritizes ongoing series where you are only 1 volume behind.
  - 🔔 **Restock Watchlist**: Bumps hard-to-find books to the front of the line when they come back in stock.
  - 📊 **Cascading Completion**: Focuses on series closest to 100% completion so you finish your backlog.
  - ⏩ **Sequential Next Volume**: Always recommends the next unowned volume in sequential order.
- **Custom Rule Engine**: Build custom recommendation passes filtered by collection status (*Active*, *Wishlist*), missing count, and availability, sorted by date or completion percentage.

### 📚 3. Series & Volume Library
- **Fractional & Decimal Volumes**: Full support for decimal volume numbers (*Vol. 11.5* side stories, special chapters, unnumbered omnibus editions).
- **Fast Series Creation**: Create entire multi-volume series in seconds with auto-generated volume lists (1..N) or add standalone single novels/artbooks.
- **Granular Volume Tracking**: Track release dates, purchase prices, transaction dates, and custom notes per volume.
- **Stock Status & Restock Watchlist**: Track whether books are *Available*, *Pre-Order*, *Backorder*, or *Out of Print*.
- **One-Tap Bulk Marking**: Mark entire volume spans (e.g. *Volumes 1 to 10*) as purchased or unowned with a single tap.
- **Smart Status Prompts**: Automatic suggestions to move Wishlist series to Active upon buying a book, and Active series to Completed when finished.

### 📦 4. Universal File Importer (Migrate in Seconds)
- **One-Click Ingestion**: Import reading lists from **Goodreads CSV**, **StoryGraph CSV**, custom **CSV**, or **Microsoft Excel (.xlsx)** workbooks.
- **Smart Cleaner**: Automatically strips clutter like `(Light Novel)`, `(Paperback)`, `(Hardcover)`, or Goodreads `#vol` tags.
- **Interactive Review Screen**: Inspect, edit, and toggle books before committing them to your library.

### 📊 5. Statistics & Library Insights
- **Overview Metrics**: Total Owned Volumes, Total Series, and Total Financial Outlay.
- **Quota Velocity**: See regular vs. bonus usage breakdown and historical purchasing speed.
- **Bought vs. Gifted**: Visual proportional breakdown between self-purchased books and gifts.
- **Format Distribution**: Breakdown across Light Novels, Manga, Comics, and Novels.

### 💾 6. Local-First Privacy & Auto-Backups
- **100% Private & Offline**: No cloud servers, no accounts, no tracking. All data remains strictly on your device.
- **Full State Backup & Restore**: One-tap JSON / `.canele` export and restore.
- **Spreadsheet Exports**: Export your active collection to standard `.csv` or formatted `.xlsx` workbooks.
- **Automatic Background Backups**: Automatically saves timestamped rolling backups to your chosen storage directory.

### 🚀 7. In-App Updates
- **Seamless GitHub Releases**: Check for updates and download new APK releases directly from GitHub within the app.

### 🍮 8. Bespoke Canelé Pastry Design
- **Warm French Pastry Theme**: Inspired by *canelé de Bordeaux* pastries (Custard Cream, Caramelized Amber, Warm Crust, Deep Caramel).
- **Light, Dark & System Modes**: Fully styled Material 3 design system.
- **3x3 Grid Year Selector**: Fast decade-by-decade date picker.
- **4-Step Setup Wizard**: Step-by-step onboarding to configure your timeline on first launch.

---

## 📦 Download & Installation

1. Download **`Canelé-v1.0.0.apk`** from the [GitHub Releases](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/releases/tag/v1.0.0) page.
2. Open the `.apk` file on your Android device and confirm installation.
3. Launch Canelé and enjoy tracking your collection!

---

## 📄 License & Open Source

Canelé is free and open-source software licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.
- **Repository:** [https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner)
- **Bug Reports & Feature Requests:** [https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues)
