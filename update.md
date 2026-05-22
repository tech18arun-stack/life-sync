# LifeSync Upgrade Plan: Smart Financials & Indian SMS Parsing

## Overview
Upgrade the LifeSync app with an automated expense tracker that reads bank SMS messages, categorizes them using Gemini AI, and allows users to quickly add them to their records.

## Phase 1: Smart Financials & Indian SMS Parsing

### 1. SMS Parsing Integration
- **Dependency**: Add `telephony: ^2.0.0`.
- **Permissions**: Request `RECEIVE_SMS` and `READ_SMS` on Android.
- **Service**: Implement `SmsParsingService` to detect patterns (e.g., AD-HDFCBK) and extract amount/merchant.

### 2. AI Categorization
- **Service**: Implement `CategorizationService` using Gemini.
- **Logic**: Use AI to map merchant names (e.g., "Zomato") to categories (e.g., "Food").

### 3. UI Enhancements (DONE)
- **Dashboard**: Added "Detected transactions" widget.
- **Actions**: One-tap "Add" or "Ignore" detected transactions.

## Phase 2: Productivity & Life OS (DONE)
- **Habit Tracker**: Daily streaks and reminders.
- **Mood Tracker**: Log and visualize moods.
- **Dashboard Widgets**: Advanced lifecycle overview.

## Phase 3: Automation & Security
- **Recurring Expenses**: Auto-add recurring bills.
- **App Lock**: Biometric/PIN security.
