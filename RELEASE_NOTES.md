# Canelé v1.0.0 — The Golden Crust Debut 🍮

> **Release Date:** September 1, 2026  
> **Tag:** `v1.0.0`  
> **Status:** Stable Release  
> **License:** [GNU AGPL-3.0](LICENSE)

We are thrilled to announce the official **v1.0.0 release of Canelé**, the deterministic, local-first book collection manager and acquisition cadence planner designed specifically for collectors of light novels, manga, comics, and literature.

---

## 🌟 What is Canelé?

Most modern cataloging apps try to predict what you should read using black-box machine learning algorithms or lock your personal collection behind mandatory cloud logins and subscription paywalls.

**Canelé takes a fundamentally different path:**
- **Zero Black-Box AI**: All monthly recommendations are derived from explicit, user-configured multi-pass priority rules.
- **Strictly Local-First**: Your database is stored locally on your device with embedded Hive NoSQL boxes.
- **Deterministic Quota Mathematics**: Plan your reading and acquisition budget through an auditable quota ledger with auto-skip projection math.
- **Bespoke Pastry Aesthetic**: A warm, polished UI inspired by the French *canelé de Bordeaux* pastry.

---

## 🚀 Flagship Features in v1.0.0

### 1. 📐 Deterministic Quota & Cadence Engine
- **Triple-Bucket Ledger**: Track acquisitions across **Regular**, **Bonus**, and **Gift** categories. Gifts never consume budget quota.
- **Recurring & One-Off Bonuses**: Schedule recurring bonus months (e.g. May birthdays or December holidays) or log manual +1 bonuses on the fly.
- **No-Book Month Exclusion**: Designate no-buy periods so your cadence expectation isn't distorted.
- **Forward Auto-Skip Simulation**: If you acquire books ahead of schedule, Canelé automatically computes the exact future month (e.g. *"November 2026"*) when your quota catches back up.

### 2. 🎯 Multi-Pass Recommendation Waterfall (Rule Studio)
- **Visual Sequential Queue**: Build an auditable rule pipeline that inspects your backlog each month to fill up to 4 recommendation slots.
- **Starter Rule Presets**:
  - *Stay Caught Up*: Targets active series missing exactly 1 released volume.
  - *Prioritize Restocked Volumes*: Automatically elevates restocked watchlist items.
  - *Series Closer to Completion*: Targets series with highest completion percentage first.
  - *Sequential Next Volume*: Recommends the next unread volume in sequential order.
- **Deduplication & Take Limits**: Built-in 1-volume-per-series deduplication prevents a single series from dominating your monthly quota.

### 3. 📦 Universal Smart File Importer
- **Multi-Format Parsing**: Ingest entire book libraries from **Goodreads CSV**, **StoryGraph CSV**, **Generic CSV**, and **Microsoft Excel (`.xlsx`)** spreadsheets.
- **Smart Title Normalization**: Automated regex cleans format/binding noise (`(Light Novel)`, `(Manga)`, `(Paperback)`, `(Hardcover)`) and extracts decimal volume numbers (e.g. *Vol. 11.5* side stories).
- **Interactive Review Table**: Preview and modify series details before confirming the import.

### 4. 📊 Statistics & Deep Insights
- **Key Metrics Dashboard**: Instant overview of Total Owned volumes, Total Series, and Active vs. Completed progress.
- **Bought vs. Gifted Split**: Visual metric breakdown comparing self-purchased books against gifts.
- **Format Distribution**: Visual pie/bar charts illustrating the balance between Light Novels, Manga, Comics, and Books.

### 5. 💾 Sovereign Local Storage & Auto-Backup Hub
- **Automated Rolling Backups**: Dual-file rolling backup system (`canele_autobackup.json` and `canele_autobackup_prev.json`) executes in the background on every change.
- **Full Database Portability**: One-tap export and restore of full database state (`.canele` / `.json`).
- **Spreadsheet Export**: Export your complete catalog into clean CSV or styled Excel `.xlsx` spreadsheets.

---

## 📦 Download & Installation

| Platform | Package / Binary | Installation |
| :--- | :--- | :--- |
| **Android** | `app-release.apk` | Download and install APK directly (Android 5.0+ / API 21+) |
| **Android** | `app-release.aab` | Google Play Store Bundle |
| **Desktop** | Windows / Linux / macOS | Standalone desktop binary from release assets |
| **Web** | Static Web Build | Host statically on GitHub Pages, Cloudflare, or local browser |

---

## ⚡ Quick Start in 3 Steps

1. **Launch Canelé** on your device and complete the 4-step setup wizard to configure your timeline start month and monthly cadence.
2. **Import or Add Series**: Ingest your existing library using the **File Hub** (Goodreads / CSV / Excel) or tap **Add Series** to create series with auto-generated volume numbers.
3. **Check Your Dashboard**: View your monthly target queue, quota balance, and acquisition pace calculated deterministically.

---

## 🧪 Quality & Test Metrics

- **Static Analyzer**: `flutter analyze` — **0 issues**.
- **Automated Tests**: 56 unit and widget tests covering arithmetic, parsers, and UI flows with 100% pass rate.
- **Dependencies**: Built on Flutter 3.22+, Dart 3.4+, Riverpod 2.5+, and Hive 2.2+.

---

## 🤝 Open Source & Community

Canelé is free and open-source software under the **[GNU Affero General Public License v3.0](LICENSE)**.

- **GitHub Repository**: [https://github.com/YTFL/Canale](https://github.com/YTFL/Canale)
- **Technical Documentation**: [TECHNICAL.md](TECHNICAL.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

*Crafted with care and warm custard amber.* 🍮
