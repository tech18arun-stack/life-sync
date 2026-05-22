# LifeSync — Comprehensive App Context Prompt

> **Purpose:** This document describes every aspect of the LifeSync Flutter application — architecture, features, screens, services, data models, premium tiers, tech stack, and design system — so that an AI assistant can understand the full context and provide accurate, consistent help.

---

## 1. App Identity

| Property | Value |
|---|---|
| **App Name** | LifeSync |
| **Tagline** | Plan • Track • Achieve |
| **Target Audience** | Indian families & individuals |
| **Current Version** | 4.6.4 (config: 4.6.0) |
| **Min Supported Version** | 3.0.0 |
| **Package Name** | `lifesync` |
| **Support Email** | support@edizo.in |
| **Website** | https://www.edizo.in |
| **Backend API** | https://api.edizo.in/v1 |

---

## 2. Tech Stack

### Frontend
| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart, SDK ≥3.9.2) |
| **State Management** | `provider ^6.1.1` |
| **UI Theme** | `google_fonts` (Inter), Glassmorphism, Dark/Light |
| **Charts** | `fl_chart ^0.66.0`, `syncfusion_flutter_gauges ^27.1.48` |
| **Icons** | `font_awesome_flutter ^10.7.0`, `cupertino_icons` |
| **Animations** | `shimmer ^3.0.0`, Flutter native animations |
| **Markdown** | `flutter_markdown ^0.7.7+1` |
| **Local Storage** | `shared_preferences ^2.5.4` |
| **File System** | `path_provider ^2.1.5`, `file_picker ^10.3.10`, `open_filex ^4.7.0` |
| **HTTP** | `http ^1.2.0`, `dio ^5.9.2` |
| **Notifications** | `flutter_local_notifications ^19.5.0`, `timezone ^0.10.1` |
| **Biometrics** | `local_auth 2.2.0` |
| **Contacts** | `flutter_contacts ^1.1.9+2` |
| **SMS Tracking** | `telephony ^0.2.0` |
| **Permissions** | `permission_handler ^12.0.1` |
| **URL Launcher** | `url_launcher ^6.3.1` |
| **Deep Links** | `deep_link_service.dart` (custom) |
| **Payments** | `razorpay_flutter ^1.4.1` |
| **Package Info** | `package_info_plus ^8.3.1` |
| **UUID** | `uuid ^4.2.2` |

### Backend
| Layer | Technology |
|---|---|
| **BaaS** | Appwrite (self-hosted at api.edizo.in) |
| **SDK** | `appwrite ^14.0.0` |
| **Database** | Appwrite DB (`Life_db`) |
| **File Storage** | Appwrite Buckets (`health-images`) |
| **Auth** | Appwrite Auth (Email+Password, Google OAuth) |

### AI
| Layer | Technology |
|---|---|
| **AI Model** | Google Gemini (`gemini-2.5-flash`) |
| **SDK** | `google_generative_ai ^0.4.7` |
| **API Key** | User-provided, stored in `SharedPreferences` |

### Ads
| Layer | Technology |
|---|---|
| **Ad Network** | Start.io (StartIO) |
| **App ID** | `201957244` |
| **Ad Formats** | Banner (bottom), Interstitial, Video Interstitial |
| **Condition** | Shown only to non-premium users |

### Payments
| Layer | Technology |
|---|---|
| **Gateway** | Razorpay |
| **Key** | `rzp_live_SSlQnbynKOMOSg` |

---

## 3. Premium Tier System

LifeSync has **three tiers**: Basic, Premium, and Ultra.

### Basic (Free)
- Manual expense & income tracking
- Budget management
- Basic AI Insights (requires watching rewarded ads)
- Start.io banner + interstitial ads shown

### Premium (₹29/month or ₹299/year)
- Ad-free experience
- SMS automated transaction detection
- Premium Glassmorphic UI
- All AI features (no ads gate)
- Cloud Sync (Appwrite)

### Ultra (₹49/month)
- All Premium features
- Custom app icon
- Interactive Circular Balance Dials
- Real-time money tracking
- Quick Menu on home screen
- Advanced Financial Activity Charts
- Priority 24/7 Support

### Premium Logic
- `user.isPremiumActive` → has active premium subscription
- `user.isUltra` → has Ultra plan
- Premium expiry popup shown 2x/day (morning 6–12 & evening 17–22 slots) for up to 30 days after expiry
- Ads shown every 3rd action (video interstitial) or alternating (regular interstitial)

---

## 4. App Architecture

```
life-sync/
├── config.json                    # Remote app config (feature flags, plans, ads)
├── appwrite_schema.json           # Full Appwrite DB schema
├── uineeds.md                     # UI design system doc (Fintastics-inspired)
├── update.md                      # Feature upgrade roadmap
├── social_media_prompts.md        # Marketing prompts
├── app_store_long_description.txt # Play Store description
└── frontend/                      # Flutter app
    ├── lib/
    │   ├── main.dart              # App entry point, providers, routing
    │   ├── models/                # Data models
    │   ├── providers/             # State management (ChangeNotifier)
    │   ├── services/              # Business logic & API calls
    │   ├── screens/               # Full-page screens (29 screens)
    │   ├── widgets/               # Reusable UI components (29 widgets)
    │   └── utils/                 # Theme, responsive helpers
    ├── android/                   # Android-specific config
    ├── ios/                       # iOS-specific config
    ├── assets/
    │   └── logo.png               # App logo
    └── pubspec.yaml               # Dependencies
```

### Startup Flow
1. `ConfigService.initialize()` — fetches remote config (feature flags)
2. `AppwriteService.initialize()` — sets up Appwrite client
3. `SecurityService.initialize()` — loads biometric/app-lock state
4. `NotificationService.initialize()` — registers Android notification channels
5. `DeepLinkService.initDeepLinks()` — handles incoming deep links
6. `StartIOAds.initialize()` — initializes ad SDK (if enabled + not premium)
7. App starts at `SplashScreen` → checks auth → routes to `HomeScreen` or `LoginScreen`

---

## 5. Routing

| Route | Screen |
|---|---|
| `/` | `SplashScreen` |
| `/maintenance` | `MaintenanceScreen` |
| `/onboarding` | `OnboardingScreen` |
| `/login` | `LoginScreen` |
| `/home` | `HomeScreen` |

All other screens are pushed via `Navigator.push` (no named routes).

---

## 6. State Management (Providers)

All providers use `ChangeNotifier` via the `provider` package. Most are `ChangeNotifierProxyProvider` that re-initialize when auth state changes.

| Provider | Depends On | Responsibility |
|---|---|---|
| `AuthProvider` | — | Login, logout, register, Google OAuth, premium upgrade |
| `ThemeProvider` | — | Light/dark mode toggle |
| `FinancialDataManager` | AuthProvider | Expenses, income, budgets, detected SMS transactions |
| `FamilyProvider` | AuthProvider | Family member profiles |
| `FamilyNumberProvider` | AuthProvider | Family contact numbers |
| `TaskProvider` | AuthProvider | Task CRUD |
| `HealthProvider` | AuthProvider | Health records |
| `ReminderProvider` | FinancialDataManager | Reminders & bill tracking |
| `SavingsGoalProvider` | AuthProvider | Savings goals |
| `FamilyEventProvider` | — | Family events (local) |
| `AnalyticsProvider` | FinancialDataManager | Computed analytics data |
| `SubscriptionProvider` | AuthProvider | Subscription management |
| `HabitProvider` | AuthProvider | Habit tracking & streaks |
| `MoodProvider` | AuthProvider | Daily mood logging |
| `GeminiService` | — | AI features (initialized globally) |
| `SmsParsingService` | — | SMS transaction detection |
| `CategorizationService` | GeminiService | AI expense categorization |

---

## 7. Data Models

### User (`models/user.dart`)
- `id`, `name`, `email`, `phone`, `avatar`
- `userType` (admin/client), `role` (owner/member)
- `parentUserId`, `familyId`, `relation`
- `isActive`, `lastLogin`, `createdAt`, `updatedAt`
- `isPremiumActive` (computed), `isUltra` (computed)
- `premiumExpiryDate`, `planType`

### Expense (`models/expense.dart`)
- `id`, `userId`, `description`, `amount`, `category`, `date`
- `paymentMethod`, `notes`, `familyMemberId`
- `contactName`, `phoneNumber`

### Income (`models/income.dart`)
- `id`, `userId`, `description`, `amount`, `source`, `date`
- `isRecurring`, `recurringFrequency`, `notes`, `familyMemberId`
- `contactName`, `phoneNumber`

### Budget (`models/budget.dart`)
- `id`, `userId`, `category`, `allocatedAmount`, `spentAmount`
- `month`, `year`, `isActive`, `alertThreshold`
- Computed: `isOverBudget`, `percentageUsed`, `remainingAmount`

### Task (`models/task.dart`)
- `id`, `userId`, `title`, `description`, `category`
- `priority` (High/Medium/Low), `status` (Pending/In Progress/Completed)
- `dueDate`, `isCompleted`, `completedAt`, `assignedTo`, `notes`

### Reminder (`models/reminder.dart`)
- `id`, `userId`, `title`, `description`, `type`
- `amount`, `dueDate`, `isPaid`, `repeatInterval`, `notes`
- Types: EMI, Loan, Recharge, Bill, Subscription, General

### SavingsGoal (`models/savings_goal.dart`)
- `id`, `userId`, `title`, `description`
- `targetAmount`, `currentAmount`, `targetDate`
- `category`, `priority`, `isCompleted`, `notes`
- Computed: `percentageCompleted`, `remainingAmount`

### Habit (`models/habit.dart`)
- `id`, `userId`, `title`, `icon`, `color`
- `frequency` (daily/weekly), `streak`, `lastCompleted`

### HabitLog (`models/habit_log.dart`)
- `id`, `userId`, `habitId`, `date`, `status`

### Mood (`models/mood.dart`)
- `id`, `userId`, `score` (1–5), `note`, `factors`, `date`

### HealthRecord (`models/health_record.dart`)
- `id`, `userId`, `memberName`, `recordType`, `date`
- `description`, `diagnosis`, `treatment`, `nextVisit`
- `doctorName`, `doctorPhone`, `hospitalName`
- `medication`, `dosage`, `frequency`, `notes`
- `imageUrls`, `filePaths`, `attachments`

### FamilyMember (`models/family_member.dart`)
- `id`, `userId`, `name`, `relationship`, `birthDate`
- `phoneNumber`, `email`, `notes`

### FamilyNumber (`models/family_number.dart`)
- `id`, `userId`, `name`, `phoneNumber`, `category`
- `isEmergency`, `isPrimary`, `notes`

### Subscription (`models/subscription.dart`)
- `id`, `userId`, `name`, `amount`, `nextBillingDate`
- `category`, `billingCycle`, `icon`

### FamilyEvent (`models/family_event.dart`)
- Local-only (SharedPreferences), not yet Appwrite-synced

---

## 8. Services

### `AppwriteService` (`services/appwrite_service.dart`)
- Initializes Appwrite `Client` with endpoint and project ID
- Exposes: `account`, `databases`, `storage`
- Database ID: `Life_db` (constant)

### `AuthService` (`services/auth_service.dart`)
- Login/register/logout with Appwrite Accounts
- Google OAuth flow via `signInWithGoogle()`
- `refreshCurrentUser()` — re-fetches profile after premium upgrade
- `upgradeToPremium(days, planType)` — sets premium status in Appwrite

### `ConfigService` (`services/config_service.dart`)
- Fetches remote `config.json` from Appwrite storage
- Exposes feature flags: `maintenanceMode`, `loginEnabled`, `registrationEnabled`
- `adsEnabled`, `startioEnabled`, `startioAppId`
- `habitTrackerEnabled`, `moodTrackerEnabled`, `aiInsightsEnabled`
- Plan costs: `premiumMonthlyCost` (₹29), `premiumUltraMonthlyCost` (₹49), `premiumYearlyCost` (₹299)
- `debugPrintConfig()` — prints all config values

### `GeminiService` (`services/gemini_service.dart`)
- Model: `gemini-2.5-flash`
- API key stored in `SharedPreferences` (user-provided)
- Features:
  - `generateBudgetTips(expenses, budgets, monthlyIncome)` → markdown string
  - `calculateFinancialHealth(income, expenses, savings, budgets)` → score map
  - `analyzeTrends(expenses, days)` → string analysis
  - `predictMonthlyExpenses(historicalExpenses, monthsBack)` → JSON map
  - `getCategoryInsights(category, categoryExpenses)` → string
  - `analyzeBudgetPerformance(budgets, totalIncome)` → string
  - `analyzeSavingsGoals(goals, income, expenses)` → string
  - `generateReportInsights(income, expenses, categoryExpenses, lastMonth…)` → string
  - `suggestReminders(expenses)` → string
  - `categorizeTransaction(description)` → category string
  - `getChatResponse(message, history)` → string (for AI Advisor chat)

### `NotificationService` (`services/notification_service.dart`)
- Uses `flutter_local_notifications`
- Channels: Budget alerts, Task reminders, Savings milestones, Event reminders, Morning summaries
- Schedule notifications for: task due dates (+1 day warning), reminders, savings goal milestones (25%, 50%, 75%, 100%)

### `SmsParsingService` (`services/sms_parsing_service.dart`)
- Reads bank SMS (India) using `telephony`
- Detects transaction patterns (debit/credit, amount, merchant)
- Returns `DetectedTransaction` list for user review

### `CategorizationService` (`services/categorization_service.dart`)
- Wraps `GeminiService.categorizeTransaction()`
- Maps merchant names to expense categories

### `SecurityService` (`services/security_service.dart`)
- Biometric / PIN app lock using `local_auth`
- `initialize()` loads lock preference from SharedPreferences

### `RazorpayService` (`services/razorpay_service.dart`)
- Handles Razorpay payment flow for premium upgrades

### `StartIOAds` (`services/startio_ads.dart`)
- `initialize(appId)` — initializes SDK
- `showInterstitial(context)` — shows interstitial
- `showVideoInterstitial(context)` — shows rewarded video
- `StartioBanner` widget — renders banner ad

### `StorageService` (`services/storage_service.dart`)
- Appwrite file storage for health record images
- Upload/download/delete files in `health-images` bucket

### `DeepLinkService` (`services/deep_link_service.dart`)
- Handles incoming URL deep links (e.g., password reset links)

---

## 9. Screens (29 screens)

| Screen | File | Description |
|---|---|---|
| Splash | `splash_screen.dart` | App boot, auth check, routing |
| Onboarding | `onboarding_screen.dart` | First-launch feature walkthrough |
| Login | `login_screen.dart` | Email/password + Google OAuth |
| Register | `register_screen.dart` | New user signup |
| Home | `home_screen.dart` | Main dashboard (2100+ lines) |
| Profile | `profile_screen.dart` | User profile, premium upgrade, settings |
| Expenses | `expenses_screen.dart` | Expense list, filters, add/edit/delete |
| Income | `income_screen.dart` | Income list & management |
| Recent Income | `recent_income_screen.dart` | Quick income history view |
| Budget | `budget_screen.dart` | Budget categories, progress, AI Smart Plan |
| Analytics | `analytics_screen.dart` | Spending trends, charts, AI insights |
| Reports | `reports_screen.dart` | Monthly/weekly reports, AI report generation |
| Financial Calendar | `financial_calendar_screen.dart` | Calendar view of transactions & events |
| Savings Goals | `savings_goals_screen.dart` | Goal tracking with milestones |
| Reminders | `reminder_screen.dart` | Bill/EMI/subscription reminders |
| Tasks | `tasks_screen.dart` | To-do list with priority & due dates |
| Health | `health_screen.dart` | Family health records & vitals |
| Habits | `habits_screen.dart` | Habit tracker with streaks |
| History | `history_screen.dart` | Global transaction/activity history |
| Family Accounts | `family_user_accounts_screen.dart` | Family member management |
| Subscriptions | `subscriptions_screen.dart` | Subscription tracking |
| AI Advisor | `ai_advisor_screen.dart` | Gemini-powered chat financial advisor |
| Settings | `settings_screen.dart` | App settings, theme, security, AI config |
| Notification History | `notification_history_screen.dart` | Past notification log |
| Data Privacy | `data_privacy_screen.dart` | Privacy policy & data controls |
| Privacy Policy | `privacy_policy_screen.dart` | Legal privacy policy |
| Biometric Auth | `biometric_auth_screen.dart` | App lock / biometric gate |
| Ad Test | `ad_test_screen.dart` | Dev screen for testing ads |
| Maintenance | `maintenance_screen.dart` | Shown when `maintenanceMode: true` |

### Home Screen Sections (in order)
1. **Premium Header** — "Hello, {Name}!" + plan badge + search & notification icons
2. **Upgrade Banner** — Shown if not Ultra; promotes next plan
3. **Plan-Based Balance Section:**
   - **Ultra:** Glass balance card + two `CircularBalanceDial` widgets (Balance & Income)
   - **Premium:** Single gradient balance card with income/expense stats
   - **Basic:** Simple balance card with "Unlock Premium" prompt
4. **Quick Menu** (Ultra only) — Wallet top-up, budget creation, card lock
5. **Premium Action Buttons** — Add Expense, Add Income, Add Budget, View Analytics, etc.
6. **Upcoming Payments** — Horizontal scroll of pending reminders
7. **Mood Tracker Widget** — Daily mood logging
8. **Habit Tracker Widget** — Today's habits with streak rings
9. **AI Insight Card** — Financial health score + Gemini tips (if AI enabled)
10. **Savings Goals Section** — Goal progress cards
11. **Recent Transactions** — Latest expenses/income list

---

## 10. Widgets (29 reusable widgets)

| Widget | File | Description |
|---|---|---|
| CircularBalanceDial | `circular_balance_dial.dart` | Animated circular gauge (Ultra feature) |
| WalletCard | `wallet_card.dart` | Gradient balance card |
| PremiumComponents | `premium_components.dart` | PremiumCard, PremiumButton, PremiumExpiredPopup, etc. |
| PremiumGate | `premium_gate.dart` | Locks content behind premium paywall |
| HabitTrackerWidget | `habit_tracker_widget.dart` | Habit rings with streak display |
| MoodTrackerWidget | `mood_tracker_widget.dart` | Emoji mood selector + trend chart |
| AiTipsCard | `ai_tips_card.dart` | Displays Gemini AI financial tips |
| SpendingTrendsChart | `spending_trends_chart.dart` | fl_chart line/bar chart |
| CategoryBreakdownWidget | `category_breakdown_widget.dart` | Pie/bar breakdown of spending categories |
| MonthlyComparisonWidget | `monthly_comparison_widget.dart` | Month-over-month comparison bars |
| ExpensePredictionCard | `expense_prediction_card.dart` | AI-predicted next month expenses |
| DetectedTransactionsWidget | `detected_transactions_widget.dart` | SMS-detected transactions review |
| UpcomingPaymentCard | `upcoming_payment_card.dart` | Reminder payment card (horizontal scroll) |
| TaskItem | `task_item.dart` | Individual task row with swipe actions |
| AddExpenseDialog | `add_expense_dialog.dart` | Bottom sheet for adding expenses |
| AddIncomeDialog | `add_income_dialog.dart` | Bottom sheet for adding income |
| AddBudgetDialog | `add_budget_dialog.dart` | Dialog for budget creation |
| SmartBudgetDialog | `smart_budget_dialog.dart` | AI-powered smart budget creation |
| AddReminderDialog | `add_reminder_dialog.dart` | Reminder creation form |
| AddTaskDialog | `add_task_dialog.dart` | Task creation dialog |
| AddHealthRecordDialog | `add_health_record_dialog.dart` | Health record entry form |
| AddVitalsDialog | `add_vitals_dialog.dart` | Vitals (BP, sugar, weight) entry |
| AddInsuranceDialog | `add_insurance_dialog.dart` | Insurance record entry |
| BmiCalculatorDialog | `bmi_calculator_dialog.dart` | BMI calculation tool |
| RewardedAdDialog | `rewarded_ad_dialog.dart` | Watch-ad-to-unlock AI features dialog |
| AppUpdaterDialog | `app_updater_dialog.dart` | Force/voluntary update prompt |
| HorizontalActionCarousel | `horizontal_action_carousel.dart` | Horizontal scrollable action buttons |
| StartioBannerAd | `startio_banner_ad.dart` | Bottom banner ad wrapper |
| AppLifecycleManager | `app_lifecycle_manager.dart` | Handles app foreground/background events |

---

## 11. Database Schema (Appwrite — `Life_db`)

### Collections

| Collection | Key Fields |
|---|---|
| `user_profiles` | name, email, phone, avatar, user_type, role, parent_user_id, family_id, relation, is_active |
| `expenses` | user_id, description, amount, category, date, payment_method, notes, family_member_id |
| `incomes` | user_id, description, amount, source, date, is_recurring, recurring_frequency, family_member_id |
| `budgets` | user_id, category, allocated_amount, spent_amount, month, year, is_active, alert_threshold |
| `family_members` | user_id, name, relationship, birth_date, phone_number, email, notes |
| `family_numbers` | user_id, name, phone_number, category, is_emergency, is_primary |
| `tasks` | user_id, title, description, category, priority, status, due_date, is_completed, assigned_to |
| `savings_goals` | user_id, title, description, target_amount, current_amount, target_date, category, priority |
| `reminders` | user_id, title, description, type, amount, due_date, is_paid, repeat_interval |
| `health_records` | user_id, member_name, record_type, date, diagnosis, treatment, next_visit, doctor_name, medication, image_urls |
| `subscriptions` | user_id, name, amount, next_billing_date, category, billing_cycle, icon |
| `habits` | user_id, title, icon, color, frequency, streak, last_completed |
| `habit_logs` | user_id, habit_id, date, status |
| `moods` | user_id, score, note, factors, date |
| `user_activity` | user_id, activity_type, service_name, duration_seconds, timestamp |

### Buckets
| Bucket | Max Size | Allowed Types |
|---|---|---|
| `health-images` | 5 MB | png, jpg, jpeg, gif, webp |

---

## 12. Design System

### Color Palette
- **Primary Gradient:** `Color(0xFF8A56FF)` → `Color(0xFF5E35B1)` (Deep Purple)
- **Blue Gradient:** `Color(0xFF8E54E9)` → `Color(0xFF4776E6)`
- **Indigo Accent:** `Color(0xFF6366F1)`
- **Violet Accent:** `Color(0xFF8B5CF6)`
- **Success Green:** `Color(0xFF2E7D32)`
- **Error Red:** `Color(0xFFD32F2F)`
- **Amber:** `Color(0xFFF59E0B)`
- **Teal:** `Color(0xFF10B981)`

### Typography
- Font: **Google Fonts Inter** (applied globally via `GoogleFonts.interTextTheme`)
- Headings: `FontWeight.w700`
- Body: `FontWeight.w400/w500`
- Primary color: `AppTheme.primaryColor`

### Border Radius Standards
- Small cards: **24px**
- Large cards: **32px**
- Buttons / inputs: **50px** (pill shape)
- Main panels: `BorderRadius.only(topLeft: 40, topRight: 40)`

### Glassmorphism Pattern
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
    ),
  ),
)
```

### Key Design Principles
1. Glassmorphism via `BackdropFilter` for premium cards
2. Gradient backgrounds on main wallet/balance cards
3. Micro-animations for all primary interactions
4. Bouncing physics scrolling (`BouncingScrollPhysics`)
5. Dark/Light mode fully supported (via `ThemeProvider`)
6. Bottom nav bar: `StartioBanner` shown to non-premium users
7. Dynamic mesh gradient background on home screen

---

## 13. Key Business Logic

### Financial Health Score (0–100)
- **Savings Rate** (40 pts): ≥30% = 40, ≥20% = 30, ≥10% = 20, >0% = 10
- **Budget Adherence** (30 pts): % of budgets not over-limit
- **Emergency Fund** (30 pts): ≥6 months = 30, ≥3 = 20, ≥1 = 10
- Ratings: 80+ = Excellent, 60+ = Good, 40+ = Fair, <40 = Needs Attention

### Budget Alerts
- Notification at 75%, 90%, and 100% of budget

### Savings Goal Milestones
- Celebration notifications at 25%, 50%, 75%, 100%

### Ad Logic (Non-Premium Users)
- Every 3rd action → Video Interstitial
- Other actions → Regular Interstitial

### Premium Expiry Popup
- Shown twice daily (morning slot: 6–12, evening slot: 17–22)
- Only within 30 days of expiry
- Stored in `SharedPreferences` to avoid double-showing

### SMS Transaction Detection
- Reads Android SMS via `telephony`
- Detects Indian bank patterns (e.g., "debited ₹500 from HDFC")
- Shows `DetectedTransactionsWidget` on home screen for review
- Categorized using Gemini AI

### Family Account System
- Admin user (`user_type: admin`) creates family member users (`user_type: client`)
- Family members linked via `family_id` and `parent_user_id`
- Each member has their own expenses/health records scoped by `user_id`

---

## 14. Feature Flags (from `config.json`)

| Flag | Default | Description |
|---|---|---|
| `maintenance_mode` | false | Full-screen maintenance block |
| `login_enabled` | true | Enable/disable login |
| `registration_enabled` | true | Enable/disable new registrations |
| `ads_enabled` | true | Master ads switch |
| `sms_tracking_enabled` | true | Enable SMS parsing |
| `habit_tracker_enabled` | true | Enable habit tracking feature |
| `mood_tracker_enabled` | true | Enable mood tracking feature |
| `ai_insights_enabled` | true | Enable AI features |
| `startio_enabled` | true | Enable Start.io ads |

---

## 15. Expense Categories

- Food & Dining
- Travel
- Shopping
- Bills & Utilities
- Entertainment
- Health
- Investment
- Insurance
- Salary
- Education
- Other

---

## 16. Reminder Types

- EMI
- Loan
- Recharge
- Bill
- Subscription
- General

---

## 17. Current Roadmap (`update.md` + `uineeds.md`)

### Implemented ✅
- Glassmorphic Premium UI
- Habit Tracker (streaks, daily logs)
- Mood Tracker (emoji logging, trends)
- SMS Auto-Detection of bank transactions
- AI Categorization (Gemini)
- Circular Balance Dials (Ultra)
- Financial Health Score
- Premium/Ultra tier system with Razorpay
- Appwrite cloud sync for all data
- Biometric/App Lock security
- Budget alerting (75%, 90%, 100%)
- Savings goal milestones

### Planned / Future 🔮
- Receipt OCR scanner (camera → auto-fill expense)
- Voice expense entry ("Hey LifeSync, I spent ₹45 on coffee")
- Predictive over-budget alerts (AI velocity tracking)
- Debt payoff planner (Snowball / Avalanche)
- Investment tracker (stocks/crypto manual)
- Subscription audit ("vampire" subscriptions)
- Custom app themes (Midnight Gold, Emerald Forest, Retro Synthwave)
- Export Center (PDF/CSV/Excel with branding)
- Lottie animations (goal completion, AI thinking state)
- Floating Island navigation bar (glassmorphic)
- Parallax onboarding backgrounds
- Hero transitions between screens

---

## 18. Platforms Supported

| Platform | Status |
|---|---|
| Android | ✅ Primary (minSdk 21) |
| iOS | ✅ Configured |
| Web | ✅ Configured (PWA) |
| Windows | ✅ Configured |
| macOS | ✅ Configured |
| Linux | ✅ Configured |

---

## 19. Environment & Config Files

| File | Purpose |
|---|---|
| `frontend/.env` | Environment variables (Appwrite endpoint, project ID) |
| `frontend/.env.example` | Template for `.env` |
| `config.json` | Remote feature config (hosted on Appwrite storage) |
| `appwrite_schema.json` | Full DB schema for Appwrite setup |
| `frontend/key.properties.template` | Android signing key template |
| `frontend/build.ps1` | Windows PowerShell build script |
| `frontend/build.sh` | Linux/macOS build script |

---

## 20. AI Advisor Screen

A dedicated chat screen (`ai_advisor_screen.dart`) powered by Gemini:
- Users can ask financial questions like "Can I afford a new laptop this month?"
- Chat history maintained per session
- Context includes user's budget, income, and expenses
- Uses `GeminiService.getChatResponse(message, history)`

---

*Last updated: March 2026 | Version: 4.6.4*
