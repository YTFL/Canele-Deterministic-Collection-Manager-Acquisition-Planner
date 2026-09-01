# Canelé v1.0.0 Release Notes 🍮

> **Release Date:** September 1, 2026  
> **Target Platform:** Android (API 21+ / Android 5.0+)  
> **Tag:** `v1.0.0`

I am thrilled to announce the official **v1.0.0** release of **Canelé**, a local-first, 100% deterministic book collection manager and acquisition planner for Android.

Canelé is engineered specifically for book, manga, and light novel collectors who want to pace their reading and purchases deliberately—without depending on opaque algorithms, ad trackers, or cloud subscriptions.

---

## 🌟 Highlights

### 1. Mathematical Quota Cadence Engine
Say goodbye to arbitrary wishlists. Canelé computes your acquisition budget deterministically:
- **Set Your Start Date & Pace:** Choose when your tracking begins and how many books you want to buy each month (e.g. 1 book/month).
- **Separated Quota Buckets:** Distinguishes between **Regular purchases**, **Bonus acquisitions** (holidays, birthdays, rewards), and **Gifts** (which never consume your budget).
- **Auto-Skip Simulation:** Bought 4 books during a convention sale? Canelé calculates your exact forward catch-up date (e.g., *"Normal quota pace catches up in November 2026"*), preventing quota anxiety.
- **No-Book Months:** Configure recurring or one-off hiatus months where quota does not accumulate.

### 2. Rule Studio & 4-Slot Priority Waterfall
Take full control over what books you should buy next with an auditable recommendation pipeline:
- **Sequential Passes:** The engine runs candidate books through an ordered priority waterfall to fill your 4 monthly dashboard target slots.
- **Built-in Strategies:**
  - 🔄 *Stay Caught Up:* Recommends active series missing just 1 volume.
  - 🔔 *Restock Priority:* Bumps restocked volumes to the front of the line.
  - 📊 *Cascading Completion:* Prioritizes series closest to 100% completion.
  - ⏩ *Sequential Next Volume:* Always suggests the lowest unowned volume first.
- **Custom Rule Studio:** Create custom passes with custom status filters, availability conditions, and sorting criteria.

### 3. Comprehensive Series & Volume Tracking
- **Fractional & Decimal Volumes:** Native support for *Vol. 11.5* side stories, omnibus editions, and unnumbered special releases.
- **Bulk Marking:** Mark volume spans (e.g., *Volumes 1 to 15*) as owned or unowned in seconds.
- **Smart Lifecycle Assistant:** Prompts to transition Wishlist items to Active upon purchase, and Active series to Completed when finished.

### 4. Universal Importer & Smart Metadata Cleaning
- **Multi-Format Support:** Import existing collections from **Goodreads CSV**, **StoryGraph CSV**, generic **CSV**, or **Microsoft Excel (.xlsx)** files.
- **Regex Normalization:** Automatically strips format noise (`(Light Novel)`, `(Paperback)`, `(Manga)`) and extracts clean titles and volume numbers.
- **Interactive Review:** Inspect and toggle parsed items before importing.

### 5. Local-First & 100% Private
- **Zero Cloud Dependence:** All data is stored locally on your device via embedded Hive NoSQL boxes.
- **Full Portability:** One-click full state JSON backups, automated rolling local backups, and clean CSV/Excel collection exports.

---

## 📦 Download & Installation

1. Download **`Canelé-v1.0.0.apk`** from the assets below.
2. Open the `.apk` file on your Android device and confirm installation.
3. Launch Canelé and complete the friendly 4-step onboarding wizard.

---

## 📄 License & Source Code

Canelé is free and open-source software licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.
- Repository: [https://github.com/YTFL/Canale](https://github.com/YTFL/Canale)
- Issues & Feedback: [https://github.com/YTFL/Canale/issues](https://github.com/YTFL/Canale/issues)
