import { Client, Account, Databases, Storage } from 'appwrite';

const client = new Client()
    .setEndpoint('https://api.edizo.in/v1')
    .setProject('69aa6e89000b08e67a76');

export const account = new Account(client);
export const databases = new Databases(client);
export const storage = new Storage(client);

export const DATABASE_ID = 'Life_db';

export const COLLECTIONS = {
    USER_PROFILES: 'user_profiles',
    EXPENSES: 'expenses',
    INCOMES: 'incomes',
    BUDGETS: 'budgets',
    FAMILY_MEMBERS: 'family_members',
    FAMILY_NUMBERS: 'family_numbers',
    TASKS: 'tasks',
    SAVINGS_GOALS: 'savings_goals',
    REMINDERS: 'reminders',
    HEALTH_RECORDS: 'health_records',
    SUBSCRIPTIONS: 'subscriptions',
    USER_ACTIVITY: 'user_activity',
};

export default client;
