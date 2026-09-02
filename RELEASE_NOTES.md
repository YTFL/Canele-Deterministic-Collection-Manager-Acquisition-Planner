# Canelé v1.1.0 Release Notes 🍮

> **Release Date:** September 2, 2026  
> **Target Platform:** Android (API 21+ / Android 5.0+)  
> **Tag:** `v1.1.0`

**Canelé v1.1.0** introduces full **multi-currency support**, **live and offline exchange rate conversion**, **series-level & default volume pricing**, **enhanced spend analytics**, and a **v2 database schema migration** while preserving 100% offline, local-first privacy.

---

## 🌟 What's New in Canelé v1.1.0

### 💱 1. Native Multi-Currency Support (`CAD`, `USD`, `INR`, `JPY`)
- **Global Currency Options**: Full native support for Canadian Dollar (`CA$`), US Dollar (`$`), Indian Rupee (`₹`), and Japanese Yen (`¥`).
- **Locale-Aware Formatting**: Accurate currency symbol placement and native numeric rules (e.g. Indian numbering format for `INR`, zero-decimal notation for `JPY`).
- **Adaptive Symbol Scaling**: Automated scaling and typography rendering for multi-character symbols (`CA$`, `Rs`) across badges, dialogs, and input prefixes.
- **Primary Collection Currency**: Choose your preferred base currency during the initial 4-step onboarding or change it anytime in **Settings & Data**.
- **Unified Normalization**: All collection dashboards, quota summaries, and financial outlay metrics automatically normalize into your selected primary currency.

### 📚 2. Series-Level & Default Volume Pricing
- **Default Price Per Volume**: Specify a default volume price/currency on each series (e.g. $14.99 USD) that automatically serves as the baseline for all unpriced volumes.
- **Combined Series / Box Set Pricing**: Assign a flat combined bundle price for an entire series or box set when individual volume prices are not applicable.
- **Creation & Edit Flows**: Easily configure series pricing directly inside the **Add Series Sheet** and **Edit Series Dialog**.

### 📖 3. Granular Volume Price & Acquisition Logging
- **Volume & Transaction Pricing**: Record purchase prices and individual currency tags when acquiring a volume or editing volume details.
- **Auto Price Pre-Filling**: Logging an acquisition automatically pre-fills the unowned volume's catalog price or the series default price.
- **Volume Badges**: Volume checklist tiles now display clear, formatted price and currency badges.

### 🔄 4. Resilient Offline Exchange Rate Engine
- **Baseline Seed Rates**: Bundled offline conversion rates ensure that multi-currency calculations work immediately without requiring an internet connection.
- **Dual API Redundancy**: Automatically syncs rates with fallback between **Open Exchange Rates** and **Frankfurter API**.
- **24-Hour Cooldown Protection**: Manual sync button with a built-in rate-limit cooldown indicator to respect external provider quotas and prevent unnecessary network calls.

### 📊 5. Enhanced Financial & Spend Analytics
- **Total Spend & Average Cost / Volume**: Dedicated section in Statistics displaying lifetime financial investment and true average cost per purchased book (excluding gifts).
- **Dual Currency Insights**: Series detail screens now display total series spend alongside converted values when prices are logged in secondary currencies.
- **Exchange Provenance Notice**: Transparent indicator in analytics showing whether baseline offline rates or recently synced live rates were used.

### 📦 6. Universal Importer & Exporter Enhancements
- **Multi-Currency Spreadsheets (CSV & Excel)**: Universal collection exports (`.csv` and `.xlsx`) now include dedicated `Total Spent (<Base Currency>)` columns calculated with converted multi-currency values.
- **Universal Importer Currency Intelligence**: Automatic currency symbol and code detection (`CA$`, `CAD`, `₹`, `INR`, `Rs`, `¥`, `JPY`, `$`, `USD`) when importing custom CSV files.

### 🎨 7. UI & UX Refinements
- **Streamlined Series Header**: Relocated the **Bulk Mark Volumes** action into the series detail app bar overflow menu for a cleaner layout.
- **Input & Dropdown Components**: Standardized input fields and currency dropdown fields across all modal dialogs.

### 🛡️ 8. Database Schema Migration (v2)
- **Automatic Migration**: Automated upgrade on startup to schema version 2, cleanly backfilling existing rule configs, series prices, and standardizing transaction records without data loss.

---

## 📦 Download & Installation

1. Download **`Canelé-v1.1.0.apk`** from the [GitHub Releases](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/releases/tag/v1.1.0) page.
2. Open the `.apk` file on your Android device and confirm installation.
3. Launch Canelé and enjoy tracking your collection!

---

## 📄 License & Open Source

Canelé is free and open-source software licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.
- **Repository:** [https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner)
- **Bug Reports & Feature Requests:** [https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues](https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues)
