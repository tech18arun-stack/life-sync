#!/usr/bin/env python3
"""
Add alert_threshold attribute to budgets collection
"""

import os
import sys
from appwrite.client import Client
from appwrite.services.databases import Databases

ENDPOINT = os.getenv("APPWRITE_ENDPOINT", "https://api.edizo.in/v1")
PROJECT_ID = os.getenv("APPWRITE_PROJECT_ID", "69aa6e89000b08e67a76")
API_KEY = os.getenv("APPWRITE_API_KEY")
DATABASE_ID = os.getenv("APPWRITE_DATABASE_ID", "Life_db")

if not API_KEY:
    print("ERROR: APPWRITE_API_KEY environment variable is required!")
    sys.exit(1)

client = Client()
client.set_endpoint(ENDPOINT)
client.set_project(PROJECT_ID)
client.set_key(API_KEY)

databases = Databases(client)

print("Adding alert_threshold attribute to budgets collection...")

try:
    databases.create_float_attribute(
        database_id=DATABASE_ID,
        collection_id="budgets",
        key="alert_threshold",
        required=False,
        default=80.0,
    )
    print("SUCCESS: alert_threshold attribute added!")
except Exception as e:
    if "already exists" in str(e).lower():
        print("INFO: alert_threshold attribute already exists")
    else:
        print(f"ERROR: {e}")
        sys.exit(1)

print("\nDone!")
