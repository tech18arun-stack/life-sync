import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPickerUtil {
  static Future<Contact?> pickContact() async {
    if (await Permission.contacts.request().isGranted) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        // Need to fetch full contact details because openExternalPick returns minimal data
        return await FlutterContacts.getContact(contact.id);
      }
    }
    return null;
  }

  static String? getPhoneNumber(Contact contact) {
    if (contact.phones.isNotEmpty) {
      // Return the first mobile number or just the first number
      final mobile = contact.phones.firstWhere(
        (phone) => phone.label == PhoneLabel.mobile,
        orElse: () => contact.phones.first,
      );
      return mobile.number;
    }
    return null;
  }
}
