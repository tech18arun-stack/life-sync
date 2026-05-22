#!/usr/bin/env python3
"""
Add premium attributes to user_profiles collection
"""

import os
import sys
from appwrite.client import Client
from appwrite.services.databases import Databases

# ================================
# LOAD .ENV (if exists)
# ================================

def load_env():
    env_path = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()
        print("✅ Loaded environment from .env")

load_env()

ENDPOINT = os.getenv("APPWRITE_ENDPOINT", "https://api.websitescorp.com/v1")
PROJECT_ID = os.getenv("APPWRITE_PROJECT_ID", "69e45bf20039aebb88ac")
API_KEY = os.getenv("APPWRITE_API_KEY")
DATABASE_ID = os.getenv("APPWRITE_DATABASE_ID", "69e45c7d001156126993")

if not API_KEY:
    print("ERROR: APPWRITE_API_KEY environment variable is required!")
    sys.exit(1)

client = Client()
client.set_endpoint(ENDPOINT)
client.set_project(PROJECT_ID)
client.set_key(API_KEY)

databases = Databases(client)

print("Adding premium attributes to user_profiles collection...")

# 1. Add is_premium
try:
    databases.create_boolean_attribute(
        database_id=DATABASE_ID,
        collection_id="user_profiles",
        key="is_premium",
        required=False,
        default=False,
    )
    print("SUCCESS: is_premium attribute added!")
except Exception as e:
    if "already exists" in str(e).lower():
        print("INFO: is_premium attribute already exists")
    else:
        print(f"ERROR: {e}")

# 2. Add premium_expiry_date
try:
    databases.create_datetime_attribute(
        database_id=DATABASE_ID,
        collection_id="user_profiles",
        key="premium_expiry_date",
        required=False,
    )
    print("SUCCESS: premium_expiry_date attribute added!")
except Exception as e:
    if "already exists" in str(e).lower():
        print("INFO: premium_expiry_date attribute already exists")
    else:
        print(f"ERROR: {e}")

# 3. Add plan_type
try:
    databases.create_string_attribute(
        database_id=DATABASE_ID,
        collection_id="user_profiles",
        key="plan_type",
        size=50,
        required=False,
        default="basic",
    )
    print("SUCCESS: plan_type attribute added!")
except Exception as e:
    if "already exists" in str(e).lower():
        print("INFO: plan_type attribute already exists")
    else:
        print(f"ERROR: {e}")

print("\nDone!")
