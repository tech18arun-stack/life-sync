# LifeSync - Family Management App

A comprehensive personal and family management application with a Flutter frontend and Node.js/Express backend using MongoDB.

## 📁 Project Structure

```
family management/
├── 📁 frontend/                 # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── models/             # Data models (JSON-based)
│   │   ├── providers/          # State management (MongoDB API)
│   │   ├── screens/            # UI screens
│   │   ├── services/           # API service, notifications
│   │   ├── utils/              # Theme, utilities
│   │   └── widgets/            # Reusable widgets
│   ├── android/                # Android platform
│   ├── ios/                    # iOS platform
│   ├── web/                    # Web platform
│   └── pubspec.yaml            # Flutter dependencies
│
├── 📁 backend/                  # Node.js + MongoDB API
│   ├── models/                 # MongoDB Schemas
│   │   ├── FamilyMember.js
│   │   ├── FamilyNumber.js     # 📱 Family Numbers
│   │   ├── Expense.js
│   │   ├── Income.js
│   │   ├── Task.js
│   │   ├── Budget.js
│   │   └── SavingsGoal.js
│   ├── routes/                 # API Endpoints
│   │   ├── familyMembers.js
│   │   ├── familyNumbers.js    # 📱 Family Numbers API
│   │   ├── expenses.js
│   │   ├── incomes.js
│   │   ├── tasks.js
│   │   ├── budgets.js
│   │   └── savings.js
│   ├── server.js               # Express server
│   ├── .env                    # MongoDB config
│   └── package.json
│
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- **Node.js** 18+
- **MongoDB** (running on port 27017)
- **Flutter SDK** 3.9+

### Backend Setup

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Make sure MongoDB is running:
   ```bash
   # MongoDB should be running on mongodb://localhost:27017/lifesync
   ```

4. Start the server:
   ```bash
   npm run dev    # Development (with auto-reload)
   # or
   npm start      # Production
   ```

   Server runs at `http://localhost:3001`

### Frontend Setup

1. Navigate to frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## 📱 API Endpoints

### Family Numbers (NEW)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/family-numbers` | Get all family numbers |
| GET | `/api/family-numbers/emergency` | Get emergency contacts |
| GET | `/api/family-numbers/category/:category` | Get by category |
| POST | `/api/family-numbers` | Add new family number |
| PUT | `/api/family-numbers/:id` | Update family number |
| DELETE | `/api/family-numbers/:id` | Delete family number |

### Family Members
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/family-members` | Get all members |
| POST | `/api/family-members` | Add new member |
| PUT | `/api/family-members/:id` | Update member |
| DELETE | `/api/family-members/:id` | Delete member |

### Expenses
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/expenses` | Get all expenses |
| GET | `/api/expenses/summary/monthly` | Get monthly summary |
| POST | `/api/expenses` | Add expense |
| PUT | `/api/expenses/:id` | Update expense |
| DELETE | `/api/expenses/:id` | Delete expense |

### Incomes
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/incomes` | Get all incomes |
| GET | `/api/incomes/summary/monthly` | Get monthly summary |
| POST | `/api/incomes` | Add income |
| PUT | `/api/incomes/:id` | Update income |
| DELETE | `/api/incomes/:id` | Delete income |

### Tasks
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tasks` | Get all tasks |
| GET | `/api/tasks/today` | Get today's tasks |
| GET | `/api/tasks/overdue` | Get overdue tasks |
| POST | `/api/tasks` | Create task |
| PATCH | `/api/tasks/:id/complete` | Mark task complete |
| DELETE | `/api/tasks/:id` | Delete task |

### Budgets
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/budgets` | Get all budgets |
| GET | `/api/budgets/current` | Get current month budgets |
| GET | `/api/budgets/over-budget` | Get over-budget categories |
| POST | `/api/budgets` | Create budget |
| PATCH | `/api/budgets/:id/spend` | Add spending to budget |
| DELETE | `/api/budgets/:id` | Delete budget |

### Savings Goals
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/savings` | Get all savings goals |
| GET | `/api/savings/summary` | Get savings summary |
| POST | `/api/savings` | Create savings goal |
| PATCH | `/api/savings/:id/contribute` | Add contribution |
| DELETE | `/api/savings/:id` | Delete savings goal |

## ✅ Features

### MongoDB-Integrated Features
- ✅ **Family Numbers** - Store and manage family phone contacts
- ✅ **Family Members** - Track family member details
- ✅ **Expense Tracking** - Log and categorize expenses
- ✅ **Income Tracking** - Track income sources
- ✅ **Budget Management** - Set and monitor budgets
- ✅ **Task Management** - Create and complete tasks
- ✅ **Savings Goals** - Track savings progress

### Local Features (In-Memory)
- 📋 Health Records
- 🔔 Reminders
- 🛒 Shopping List
- 📅 Family Events

### Other Features
- 🎨 Dark/Light Theme
- 📊 Analytics Dashboard
- 🤖 AI-Powered Insights
- 📱 Push Notifications
- 📤 Data Export (CSV)

## 🗄️ MongoDB Collections

The app uses MongoDB database `lifesync` with:
- `familymembers`
- `familynumbers`
- `expenses`
- `incomes`
- `tasks`
- `budgets`
- `savingsgoals`

## 🔧 Configuration

### Backend (.env)
```env
PORT=3001
MONGODB_URI=mongodb://localhost:27017/lifesync
```

### Frontend API URL
Edit `lib/services/api_service.dart`:
```dart
// For Android Emulator
static const String _baseUrl = 'http://10.0.2.2:3001/api';

// For iOS Simulator / Web
// static const String _baseUrl = 'http://localhost:3001/api';

// For Physical Device (use your computer's IP)
// static const String _baseUrl = 'http://192.168.1.X:3001/api';
```

## 📝 License

MIT License
