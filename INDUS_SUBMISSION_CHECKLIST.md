# Indus App Store Submission - Quick Checklist

## ✅ PRE-SUBMISSION REQUIREMENTS

### 1. Developer Account
- [ ] Create account at https://developer.indusappstore.com
- [ ] Verify email and identity
- [ ] Complete developer profile
- [ ] Add payment information (if applicable)

### 2. App Preparation
- [ ] Fix the null safety error in FamilyProvider (DONE ✓)
- [ ] Test app on multiple Android devices
- [ ] Test all features thoroughly
- [ ] Ensure no crashes or bugs
- [ ] Test backup and restore functionality
- [ ] Verify all notifications work correctly
- [ ] Test in both light and dark modes

### 3. Build APK/AAB
```bash
# For APK
flutter build apk --release

# For AAB (recommended)
flutter build appbundle --release
```
- [ ] Build release APK or AAB
- [ ] Sign the app with release keystore
- [ ] Test the release build
- [ ] Verify app size (should be under 100MB)

### 4. App Icon
- [ ] Create 512x512 PNG icon
- [ ] Ensure it's clear and recognizable
- [ ] No transparency
- [ ] Square format
- [ ] Max 2MB file size
- [ ] Location: `assets/logo.png` (already exists)

### 5. Screenshots (Minimum 4, Maximum 8)
Required screenshots:
- [ ] 1. Home Screen with financial overview
- [ ] 2. Expense tracking screen
- [ ] 3. Task management screen
- [ ] 4. Budget overview screen
- [ ] 5. Savings goals (optional)
- [ ] 6. Family members (optional)
- [ ] 7. Shopping list (optional)
- [ ] 8. Analytics dashboard (optional)

**Specifications:**
- Format: PNG or JPEG
- Resolution: 1080 x 1920 pixels (minimum)
- Max size: 8MB per screenshot
- Show actual app features

### 6. Descriptions
- [x] Short description (80 chars) - CREATED ✓
- [x] Long description (4000 chars) - CREATED ✓
- [ ] Copy from `app_store_short_description.txt`
- [ ] Copy from `app_store_long_description.txt`

### 7. App Metadata
- [ ] App Name: **LifeSync**
- [ ] Package Name: **com.familytips.family_tips**
- [ ] Category: **Productivity** or **Lifestyle**
- [ ] Age Rating: **Everyone (3+)**
- [ ] Version: **2.05.43**
- [ ] Version Name: **2.5.43**

### 8. Developer Information
- [ ] Developer Name: [Your Name]
- [ ] Support Email: [Your Email]
- [ ] Developer Website: [Your Website]
- [ ] Privacy Policy URL: [Create and host]
- [ ] Terms of Service URL: [Create and host]

**IMPORTANT:** Support email must:
- Match registered email ID
- Be present in privacy policy URL

### 9. Privacy Policy & Terms
- [ ] Create privacy policy document
- [ ] Host privacy policy online
- [ ] Create terms of service
- [ ] Host terms of service online
- [ ] Include support email in privacy policy

### 10. Content Rating
Answer these questions:
- [ ] Violence: None
- [ ] Sexual Content: None
- [ ] Profanity: None
- [ ] Drugs/Alcohol: None
- [ ] Gambling: None
- [ ] User Interaction: No
- [ ] Location Sharing: No
- [ ] Personal Information: Stored locally only
- [ ] In-App Purchases: None

**Result:** Everyone (3+)

---

## 📱 SUBMISSION PROCESS

### Step 1: Login to Developer Portal
1. Go to https://developer.indusappstore.com
2. Login with your credentials
3. Navigate to "List New App"

### Step 2: Basic Information
- [ ] App Name: LifeSync
- [ ] App Type: Application (not Game)
- [ ] Category: Productivity
- [ ] Target Age Group: Everyone (3+)
- [ ] Upload App Icon (512x512 PNG)

### Step 3: App File Upload
- [ ] Upload APK or AAB file
- [ ] Supported formats: APK, AAB, APKS
- [ ] File location: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Or: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Descriptions
- [ ] Paste short description (80 chars)
- [ ] Paste full description (4000 chars)
- [ ] Add keywords for search optimization

### Step 5: Screenshots & Media
- [ ] Upload minimum 4 screenshots
- [ ] Upload promotional video (optional)
- [ ] Ensure all images are high quality

### Step 6: Localization (Optional)
- [ ] Select languages (English by default)
- [ ] Add Hindi translation (optional)
- [ ] Use free translation service if needed
- [ ] Upload localized screenshots

### Step 7: Developer Details
- [ ] Developer name
- [ ] Support email
- [ ] Support phone (optional)
- [ ] Developer website
- [ ] Privacy policy URL
- [ ] Terms of service URL

### Step 8: Data Safety
- [ ] Data collection: None (or specify)
- [ ] Data sharing: None
- [ ] Data security: Encrypted locally
- [ ] Data deletion: User can delete anytime

### Step 9: Permissions
Declare required permissions:
- [ ] Storage - For backup/restore
- [ ] Notifications - For reminders
- [ ] Vibration - For alerts
- [ ] Internet - Not required (works offline)

### Step 10: Review & Submit
- [ ] Review all information
- [ ] Use "Save as Draft" if needed
- [ ] Check for errors
- [ ] Click "Submit App" for review

---

## 🔍 POST-SUBMISSION

### Review Process
- [ ] Wait for review (typically 1 day)
- [ ] Check email for updates
- [ ] Respond to any queries promptly
- [ ] Fix issues if app is rejected

### After Approval
- [ ] App goes live on Indus App Store
- [ ] Share download link
- [ ] Monitor user reviews
- [ ] Respond to user feedback
- [ ] Plan updates and improvements

---

## 📋 IMPORTANT NOTES

### File Locations
```
App Icon: assets/logo.png
Release APK: build/app/outputs/flutter-apk/app-release.apk
Release AAB: build/app/outputs/bundle/release/app-release.aab
Short Description: app_store_short_description.txt
Long Description: app_store_long_description.txt
Full Guide: INDUS_APP_STORE_LISTING.md
```

### Key Points
✓ **Free listing** for first year
✓ **0% commission** on in-app purchases
✓ **24/7 support** for Indian developers
✓ **12 Indian languages** supported
✓ **Same APK** can be used for other stores
✓ **Review time:** ~1 business day

### Common Rejection Reasons
❌ Unclear or inappropriate metadata
❌ App crashes or doesn't work
❌ Missing privacy policy
❌ Support email doesn't match
❌ Low-quality screenshots
❌ Incomplete information

### Tips for Approval
✓ Test thoroughly before submission
✓ Use clear, accurate descriptions
✓ Provide high-quality screenshots
✓ Ensure privacy policy is accessible
✓ Use professional app icon
✓ Fill all required fields completely

---

## 🚀 NEXT STEPS

1. **Immediate:**
   - [ ] Fix app error (FamilyProvider - DONE ✓)
   - [ ] Test app thoroughly
   - [ ] Build release APK/AAB

2. **Before Submission:**
   - [ ] Create privacy policy
   - [ ] Take screenshots
   - [ ] Create developer account

3. **Submission:**
   - [ ] Follow submission checklist
   - [ ] Submit for review
   - [ ] Wait for approval

4. **After Launch:**
   - [ ] Monitor reviews
   - [ ] Gather user feedback
   - [ ] Plan updates

---

## 📞 SUPPORT

**Indus App Store Developer Support:**
- Website: https://developer.indusappstore.com
- Email: developer@indusappstore.com
- Available: 24/7 for Indian developers

**Documentation:**
- Developer Guide: https://developer.indusappstore.com/docs
- FAQs: https://developer.indusappstore.com/faq
- Video Tutorials: Available on YouTube

---

**Last Updated:** December 6, 2025  
**Status:** Ready for submission after completing checklist  
**Estimated Time to Complete:** 2-3 hours
