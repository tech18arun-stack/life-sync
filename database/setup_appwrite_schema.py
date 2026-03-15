#!/usr/bin/env python3
"""
Appwrite Schema Setup Script

Configuration via environment variables:
- APPWRITE_ENDPOINT: API endpoint URL (default: https://api.edizo.in/v1)
- APPWRITE_PROJECT_ID: Project ID (default: 69aa6e89000b08e67a76)
- APPWRITE_API_KEY: API Key (server-side only, required)
- APPWRITE_DATABASE_ID: Database ID (default: Life_db)
- APPWRITE_DATABASE_NAME: Database Name (default: Life_db)

Usage:
  1. Copy .env.example to .env in the frontend folder
  2. Fill in your APPWRITE_API_KEY
  3. Run: python setup_appwrite_schema.py

Or set environment variables directly:
  export APPWRITE_API_KEY="your_api_key_here"
  python setup_appwrite_schema.py
"""

import os
import sys
from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.services.storage import Storage
from appwrite.services.users import Users
from appwrite.role import Role
from appwrite.permission import Permission

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

# ================================
# SERVER CONFIG (from environment variables)
# ================================

ENDPOINT = os.getenv("APPWRITE_ENDPOINT", "https://api.edizo.in/v1")
PROJECT_ID = os.getenv("APPWRITE_PROJECT_ID", "69aa6e89000b08e67a76")
API_KEY = os.getenv("APPWRITE_API_KEY")
DATABASE_ID = os.getenv("APPWRITE_DATABASE_ID", "Life_db")
DATABASE_NAME = os.getenv("APPWRITE_DATABASE_NAME", "Life_db")

# Admin Configuration
ADMIN_EMAIL = "admin@lifesync.com"
ADMIN_PASSWORD = "Admin@2026"
ADMIN_NAME = "LifeSync Admin"

# Validate required environment variables
if not API_KEY:
    print("❌ Error: APPWRITE_API_KEY environment variable is required!")
    print("\nSet it using one of these methods:")
    print("  1. Export: export APPWRITE_API_KEY='your_key_here'")
    print("  2. Create .env file in frontend folder with APPWRITE_API_KEY=your_key_here")
    print("  3. Run: python setup_appwrite_schema.py with APPWRITE_API_KEY set")
    sys.exit(1)

# ================================
# COLLECTIONS
# ================================

collections = [

    {
        "id": "user_profiles",
        "attributes": [
            ("name","string",255,True),
            ("email","string",255,True),
            ("phone","string",50,False),
            ("avatar","string",500,False),
            ("user_type","string",50,True),
            ("role","string",50,True),
            ("parent_user_id","string",100,False),
            ("family_id","string",100,False),
            ("relation","string",100,False),
            ("is_active","boolean",None,True),
            ("last_login","datetime",None,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"expenses",
        "attributes":[
            ("user_id","string",100,True),
            ("description","string",500,True),
            ("amount","float",None,True),
            ("category","string",100,True),
            ("date","datetime",None,True),
            ("payment_method","string",100,False),
            ("notes","string",1000,False),
            ("family_member_id","string",100,False),
            ("contact_name","string",255,False),
            ("phone_number","string",50,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"incomes",
        "attributes":[
            ("user_id","string",100,True),
            ("description","string",500,True),
            ("amount","float",None,True),
            ("source","string",100,True),
            ("date","datetime",None,True),
            ("is_recurring","boolean",None,True),
            ("recurring_frequency","string",50,False),
            ("notes","string",1000,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"budgets",
        "attributes":[
            ("user_id","string",100,True),
            ("category","string",100,True),
            ("allocated_amount","float",None,True),
            ("spent_amount","float",None,True),
            ("month","integer",None,True),
            ("year","integer",None,True),
            ("is_active","boolean",None,True),
            ("alert_threshold","float",None,True),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"family_members",
        "attributes":[
            ("user_id","string",100,True),
            ("name","string",255,True),
            ("relationship","string",100,True),
            ("birth_date","date",None,False),
            ("phone_number","string",50,False),
            ("email","string",255,False),
            ("notes","string",1000,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"family_numbers",
        "attributes":[
            ("user_id","string",100,True),
            ("name","string",255,True),
            ("phone_number","string",50,True),
            ("category","string",100,True),
            ("is_emergency","boolean",None,True),
            ("is_primary","boolean",None,True),
            ("notes","string",1000,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"tasks",
        "attributes":[
            ("user_id","string",100,True),
            ("title","string",500,True),
            ("description","string",1000,False),
            ("category","string",100,True),
            ("priority","string",50,True),
            ("status","string",50,True),
            ("due_date","datetime",None,False),
            ("is_completed","boolean",None,True),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"savings_goals",
        "attributes":[
            ("user_id","string",100,True),
            ("title","string",500,True),
            ("description","string",1000,False),
            ("target_amount","float",None,True),
            ("current_amount","float",None,True),
            ("target_date","date",None,False),
            ("category","string",100,True),
            ("is_completed","boolean",None,True),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"reminders",
        "attributes":[
            ("user_id","string",100,True),
            ("title","string",500,True),
            ("description","string",1000,False),
            ("type","string",100,True),
            ("amount","float",None,False),
            ("due_date","datetime",None,True),
            ("is_paid","boolean",None,True),
            ("repeat_interval","string",50,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },

    {
        "id":"health_records",
        "attributes":[
            ("user_id","string",100,True),
            ("member_name","string",255,True),
            ("record_type","string",100,True),
            ("date","date",None,True),
            ("description","string",1000,False),
            ("diagnosis","string",1000,False),
            ("treatment","string",1000,False),
            ("doctor_name","string",255,False),
            ("hospital_name","string",255,False),
            ("notes","string",1000,False),
            ("metadata","string",50000,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },
    {
        "id":"subscriptions",
        "attributes":[
            ("user_id","string",100,True),
            ("name","string",255,True),
            ("amount","float",None,True),
            ("next_billing_date","datetime",None,True),
            ("category","string",100,True),
            ("billing_cycle","string",50,True),
            ("icon","string",100,False),
            ("created_at","datetime",None,True),
            ("updated_at","datetime",None,True),
        ]
    },
    {
        "id":"user_activity",
        "attributes":[
            ("user_id","string",100,True),
            ("activity_type","string",100,True),
            ("service_name","string",100,False),
            ("duration_seconds","integer",None,False),
            ("timestamp","datetime",None,True),
        ]
    }

]

# ================================
# CONNECT
# ================================

client = Client()
client.set_endpoint(ENDPOINT)
client.set_project(PROJECT_ID)
client.set_key(API_KEY)

databases = Databases(client)
storage = Storage(client)
users = Users(client)

print("Connected to Appwrite")

# ================================
# CREATE DATABASE
# ================================

try:
    databases.get(DATABASE_ID)
    print("Database already exists")
except:
    databases.create(
        database_id=DATABASE_ID,
        name=DATABASE_NAME
    )
    print("Database created")

# ================================
# CREATE COLLECTIONS
# ================================

for col in collections:

    cid = col["id"]

    try:
        databases.get_collection(DATABASE_ID,cid)
        print(f"{cid} exists")
        continue
    except:
        pass

    print("Creating",cid)

    databases.create_collection(
        database_id=DATABASE_ID,
        collection_id=cid,
        name=cid,
        permissions=[
            Permission.read(Role.users()),
            Permission.create(Role.users()),
            Permission.update(Role.users()),
            Permission.delete(Role.users())
        ]
    )

    for attr in col["attributes"]:

        key,atype,size,required = attr

        try:

            if atype=="string":
                databases.create_string_attribute(DATABASE_ID,cid,key,size,required)

            elif atype=="integer":
                databases.create_integer_attribute(DATABASE_ID,cid,key,required)

            elif atype=="float":
                databases.create_float_attribute(DATABASE_ID,cid,key,required)

            elif atype=="boolean":
                databases.create_boolean_attribute(DATABASE_ID,cid,key,required)

            elif atype=="datetime":
                databases.create_datetime_attribute(DATABASE_ID,cid,key,required)

            elif atype=="date":
                databases.create_date_attribute(DATABASE_ID,cid,key,required)

            print(" attribute",key)

        except:
            pass


# ================================
# CREATE STORAGE BUCKET
# ================================

try:

    storage.get_bucket("health-images")

    print("Bucket exists")

except:

    storage.create_bucket(
        bucket_id="health-images",
        name="health-images",
        permissions=[
            Permission.read(Role.users()),
            Permission.create(Role.users()),
            Permission.update(Role.users()),
            Permission.delete(Role.users())
        ],
        file_security=True,
        maximum_file_size=5242880,
        allowed_file_extensions=["png","jpg","jpeg","gif","webp"]
    )

    print("Bucket created")
# ================================
# SYNC ALL USERS TO DATABASE
# ================================

print("\nSyncing Users to Database...")

import datetime
now = datetime.datetime.now().isoformat()

# 1. Ensure Admin User exists
try:
    user_list = users.list(search=ADMIN_EMAIL)
    if user_list['total'] > 0:
        admin_user = user_list['users'][0]
        admin_uid = admin_user['$id']
        print(f"Admin user already exists (ID: {admin_uid})")
    else:
        admin_user = users.create(
            user_id="admin_user",
            email=ADMIN_EMAIL,
            password=ADMIN_PASSWORD,
            name=ADMIN_NAME
        )
        admin_uid = admin_user['$id']
        print(f"Admin user created (ID: {admin_uid})")
except Exception as e:
    print(f"Note: Admin user setup: {str(e)}")

# 2. Get all users from Auth and create profiles
try:
    all_auth_users = users.list()
    print(f"Found {all_auth_users['total']} users in Auth")
    
    for auth_user in all_auth_users['users']:
        uid = auth_user['$id']
        uemail = auth_user['email']
        uname = auth_user['name']
        uphone = auth_user.get('phone', '')
        
        # Check if profile exists
        try:
            databases.get_document(DATABASE_ID, "user_profiles", uid)
            # Optional: update existing profile if needed
            # print(f" Profile for {uemail} already exists")
        except:
            # Create profile
            is_admin = uemail == ADMIN_EMAIL
            databases.create_document(
                database_id=DATABASE_ID,
                collection_id="user_profiles",
                document_id=uid,
                data={
                    "name": uname or uemail.split('@')[0],
                    "email": uemail,
                    "phone": uphone,
                    "user_type": "admin" if is_admin else "user",
                    "role": "owner" if is_admin else "member",
                    "is_active": True,
                    "created_at": now,
                    "updated_at": now
                }
            )
            print(f" Created profile for {uemail}")
            
except Exception as e:
    print(f"Error syncing users: {str(e)}")

print("\nSetup Complete")