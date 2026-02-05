-- Disable RLS on all tables first (prevents dependency errors)
ALTER TABLE IF EXISTS expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS incomes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS budgets DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS family_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS family_numbers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS savings_goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS reminders DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS health_records DISABLE ROW LEVEL SECURITY;

-- Drop triggers
DROP TRIGGER IF EXISTS update_expenses_updated_at ON expenses;
DROP TRIGGER IF EXISTS update_incomes_updated_at ON incomes;
DROP TRIGGER IF EXISTS update_budgets_updated_at ON budgets;
DROP TRIGGER IF EXISTS update_family_members_updated_at ON family_members;
DROP TRIGGER IF EXISTS update_family_numbers_updated_at ON family_numbers;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
DROP TRIGGER IF EXISTS update_savings_goals_updated_at ON savings_goals;
DROP TRIGGER IF EXISTS update_reminders_updated_at ON reminders;
DROP TRIGGER IF EXISTS update_health_records_updated_at ON health_records;

-- Drop trigger function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop all tables
DROP TABLE IF EXISTS
  expenses,
  incomes,
  budgets,
  family_members,
  family_numbers,
  tasks,
  savings_goals,
  reminders,
  health_records
CASCADE;
