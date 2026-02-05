# Supabase Integration Guide for LifeSync App

This guide explains how to configure Supabase settings for the LifeSync app, particularly focusing on deep link configuration for email verification.

## Supabase Authentication Configuration

### 1. Redirect URLs Configuration

To enable email verification links to open directly in your mobile app, you need to configure the following redirect URLs in your Supabase dashboard:

1. **Go to your Supabase Dashboard**
   - Navigate to your project
   - Click on "Authentication" in the sidebar
   - Select "URL Configuration"

2. **Configure Redirect URLs**
   Add the following URLs to the "Redirect URLs" section:
   ```
   lifesync://login-callback
   ```
   
   This custom URL scheme will allow email verification links to open directly in your app instead of a web browser.

### 2. Site URL Configuration

In the same "URL Configuration" section, ensure your "Site URL" is set correctly:
```
https://yourdomain.com
```

### 3. Additional Settings

Make sure the following settings are enabled in your Supabase authentication settings:
- Enable "Email confirmations"
- Configure your email templates to use the correct redirect URL

## Deep Link Implementation Details

### Android Configuration

The app is configured to handle deep links with the following intent filter in `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="lifesync" android:host="login-callback" />
</intent-filter>
```

### iOS Configuration

The app is configured to handle deep links with the following URL scheme in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.familytips.family-tips</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>lifesync</string>
        </array>
    </dict>
</array>
```

## Code Implementation

### AuthService Configuration

The redirect URL is configured programmatically in the `AuthService` when calling `signUp`:

```dart
final response = await client.auth.signUp(
  email: email,
  password: password,
  data: {
    'name': name,
    'phone': phone,
  },
  emailRedirectTo: 'lifesync://login-callback', // This sets the redirect URL to the app
);
```

### Deep Link Handling

The `DeepLinkService` handles incoming deep links and processes authentication tokens:

```dart
static Future<void> _handleSupabaseAuthRedirect(
  String redirectType,
  String tokenHash,
  Uri uri,
) async {
  try {
    final client = Supabase.instance.client;
    
    switch (redirectType) {
      case 'signup':
      case 'recovery':
      case 'invite':
        final response = await client.auth.verifyOTP(
          type: OtpType.email,
          token: tokenHash,
          email: uri.queryParameters['email'],
        );
        
        if (response.session != null) {
          // User successfully authenticated
        }
        break;
      // ... other cases
    }
  } catch (e) {
    debugPrint('Error handling Supabase auth redirect: $e');
  }
}
```

## Testing Email Verification

1. Register a new user in your app
2. Check the verification email sent to the user
3. The link in the email should use the `lifesync://login-callback` scheme
4. When clicked on a mobile device with the app installed, it should open directly in the app
5. The app should process the authentication token and log the user in automatically

## Troubleshooting

### Common Issues:

1. **Email links still open in browser:**
   - Verify that the redirect URL in Supabase matches exactly what's configured in your app
   - Check that the AndroidManifest.xml and Info.plist files are properly configured

2. **Deep links not working on Android:**
   - Ensure you've added the `android:autoVerify="true"` attribute for automatic verification
   - You may need to host an assetlinks.json file for Android App Links

3. **Deep links not working on iOS:**
   - Verify that your associated domains are properly configured
   - Check that universal links are properly set up if using them

### Debugging:

Enable logging in your deep link service to troubleshoot issues:

```dart
static Future<void> _handleDeepLink(String link) async {
  try {
    final uri = Uri.parse(link);
    debugPrint('Handling deep link: $uri');
    // ... processing code
  } catch (e) {
    debugPrint('Error handling deep link: $e');
  }
}
```

## Security Considerations

- Always validate the authentication tokens received through deep links
- Ensure that the redirect URLs are properly configured and secured
- Follow Supabase best practices for authentication security

## Handling Media Files (Images, Documents) in Health Records

When storing media files like WhatsApp images in health records, follow these steps:

### 1. Image Selection and Processing

In the health screen, when users select images like '@WhatsApp Image 2026-02-01 at 3.45.48 PM.jpeg', ensure proper handling:

```dart
// Example implementation for handling image selection in health records
Future<void> _selectImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    // Process the image file
    final fileName = image.name; // This will be the actual filename like 'WhatsApp Image 2026-02-01 at 3.45.48 PM.jpeg'

    // Upload to Supabase storage
    await _uploadToSupabaseStorage(image, fileName);
  }
}
```

### 2. Supabase Storage Configuration

To store images in Supabase:

1. Go to your Supabase Dashboard
2. Navigate to "Storage" in the sidebar
3. Create a bucket for health records (e.g., 'health-images')
4. Configure bucket policies to allow uploads from your app

### 3. Uploading Images to Supabase

```dart
Future<String> _uploadToSupabaseStorage(XFile imageFile, String fileName) async {
  final fileBytes = await imageFile.readAsBytes();
  final fileNameWithTimestamp = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

  // Get current user ID
  final userId = Supabase.instance.client.auth.currentUser?.id;

  final response = await Supabase.instance.client.storage
    .from('health-images') // Your bucket name
    .upload('$userId/$fileNameWithTimestamp', fileBytes);

  // Return the public URL
  return Supabase.instance.client.storage.from('health-images').getPublicUrl('$userId/$fileNameWithTimestamp');
}
```

### 4. Security Policies for Health Images

Add appropriate Row Level Security (RLS) policies in Supabase:

```sql
-- Allow users to only access their own health images
CREATE POLICY "Allow individual access" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow individual uploads" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow individual updates" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow individual deletes" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);
```

### 5. Displaying Images in Health Records

When displaying WhatsApp images or other health record images:

```dart
// In your health record display widget
Widget _buildHealthImage(String imageUrl) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => CircularProgressIndicator(),
      errorWidget: (context, url, error) => Icon(Icons.error),
      fit: BoxFit.cover,
    ),
  );
}
```

### 6. Best Practices for Media Handling

- Always sanitize filenames to prevent security issues
- Limit file sizes to prevent excessive storage usage (default is 5MB)
- Use appropriate compression for images
- Store metadata about the original filename if needed
- Implement proper error handling for upload/download operations
- The app supports common image formats: PNG, JPEG, JPG, GIF, and WebP
- WhatsApp images are stored in the 'health-images' bucket with user-specific folder structure
- File paths are automatically generated as 'user_id/filename_timestamp' to prevent conflicts

## Verifying Health and Task Data Integration with Supabase

Both health records and task data are properly integrated with Supabase:

### Health Records Integration
- HealthProvider uses SupabaseService to perform CRUD operations on health_records table
- Methods like `getHealthRecords()`, `createHealthRecord()`, `updateHealthRecord()`, and `deleteHealthRecord()` connect to Supabase
- All health records are properly associated with the authenticated user via user_id

### Task Data Integration
- TaskProvider uses SupabaseService to perform CRUD operations on tasks table
- Methods like `getTasks()`, `createTask()`, `updateTask()`, and `deleteTask()` connect to Supabase
- All tasks are properly associated with the authenticated user via user_id

### Verification Steps
To verify that health and task data are properly syncing with Supabase:

1. Add a new health record or task in the app
2. Check your Supabase dashboard in the respective tables (health_records or tasks)
3. Verify that the record appears with the correct user_id
4. Update or delete records to confirm bidirectional sync

The architecture ensures that all health and task data is properly persisted in Supabase and synchronized across devices.

## Supabase Database Schema

The app uses the following database schema in Supabase:

### Tables
- **expenses**: Stores expense records with user association, amounts, categories, dates, etc.
- **incomes**: Stores income records with user association, amounts, sources, dates, etc.
- **budgets**: Stores budget information with allocated amounts, categories, months/years, etc.
- **family_members**: Stores family member information with relationships, contact details, etc.
- **family_numbers**: Stores contact numbers with categories, emergency flags, etc.
- **tasks**: Stores task information with priorities, statuses, due dates, etc.
- **savings_goals**: Stores savings goals with targets, current amounts, due dates, etc.
- **reminders**: Stores reminders with types, amounts, due dates, payment status, etc.
- **health_records**: Stores health records with member names, record types, dates, diagnoses, etc.

### Security Features
- Row Level Security (RLS) is enabled on all tables to ensure users can only access their own data
- Foreign key constraints link all records to the user who created them
- Indexes are created on commonly queried fields for better performance
- Automatic timestamp triggers update the `updated_at` field when records are modified

### Setup Instructions
1. Copy the schema from `frontend/schema.sql` file
2. Execute it in the Supabase SQL Editor
3. The schema includes all necessary tables, indexes, RLS policies, and triggers
4. All tables are properly linked to the authenticated user via the `user_id` field

### Migration Instructions (for existing databases)
If you already have some tables in your database, use the `frontend/schema_migrations.sql` file instead:
1. Copy the schema from `frontend/schema_migrations.sql` file
2. Execute it in the Supabase SQL Editor
3. This file includes conditional statements (IF NOT EXISTS) to avoid conflicts with existing elements
4. It adds indexes, RLS policies, and triggers only if they don't already exist

### Corrected Migration Instructions (if you encounter policy errors)
If you encounter errors about policies already existing, use the `frontend/schema_migrations_corrected.sql` file instead:
1. Copy the schema from `frontend/schema_migrations_corrected.sql` file
2. Execute it in the Supabase SQL Editor
3. This file includes additional checks to avoid creating duplicate policies
4. It handles cases where some elements may already exist in your database

This ensures secure, scalable, and performant data storage for the LifeSync app.