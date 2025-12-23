import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';

/// Backup Service for exporting and importing data via API
class BackupService {
  final ApiService _api = ApiService();

  /// Create a backup of all data from the API
  Future<Map<String, dynamic>> createBackup() async {
    try {
      // Fetch all data from API
      final expenses = await _api.getExpenses();
      final incomes = await _api.getIncomes();
      final budgets = await _api.getBudgets();
      final tasks = await _api.getTasks();
      final familyMembers = await _api.getFamilyMembers();
      final savingsGoals = await _api.getSavingsGoals();
      final familyNumbers = await _api.getFamilyNumbers();

      // Note: These are stored locally, not in API
      // We'll include empty arrays for backward compatibility
      final backup = {
        'version': '2.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'dataSource': 'mongodb',
        'expenses': expenses,
        'incomes': incomes,
        'budgets': budgets,
        'tasks': tasks,
        'familyMembers': familyMembers,
        'savingsGoals': savingsGoals,
        'familyNumbers': familyNumbers,
        'reminders': [], // Stored locally
        'healthRecords': [], // Stored locally
        'shoppingItems': [], // Stored locally
        'familyEvents': [], // Stored locally
      };

      return backup;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// Export backup to a file
  Future<String?> exportToFile() async {
    try {
      final backup = await createBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      if (kIsWeb) {
        // For web, we'll use share functionality
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'lifesync_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);
      debugPrint('Backup saved to: ${file.path}');

      return file.path;
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      rethrow;
    }
  }

  /// Share backup file
  Future<void> shareBackup() async {
    try {
      final filePath = await exportToFile();
      if (filePath != null) {
        await Share.shareXFiles([XFile(filePath)], text: 'LifeSync Backup');
      }
    } catch (e) {
      debugPrint('Error sharing backup: $e');
      rethrow;
    }
  }

  /// Import backup from file picker
  Future<bool> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final backup = jsonDecode(jsonString) as Map<String, dynamic>;

        return await restoreBackup(backup);
      }
      return false;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      rethrow;
    }
  }

  /// Restore data from backup
  Future<bool> restoreBackup(Map<String, dynamic> backup) async {
    try {
      // Restore expenses
      if (backup['expenses'] != null) {
        for (var expenseJson in backup['expenses']) {
          try {
            // Remove _id to create new entries
            final data = Map<String, dynamic>.from(expenseJson);
            data.remove('_id');
            data.remove('id');
            await _api.createExpense(data);
          } catch (e) {
            debugPrint('Error restoring expense: $e');
          }
        }
      }

      // Restore incomes
      if (backup['incomes'] != null) {
        for (var incomeJson in backup['incomes']) {
          try {
            final data = Map<String, dynamic>.from(incomeJson);
            data.remove('_id');
            data.remove('id');
            await _api.createIncome(data);
          } catch (e) {
            debugPrint('Error restoring income: $e');
          }
        }
      }

      // Restore budgets
      if (backup['budgets'] != null) {
        for (var budgetJson in backup['budgets']) {
          try {
            final data = Map<String, dynamic>.from(budgetJson);
            data.remove('_id');
            data.remove('id');
            await _api.createBudget(data);
          } catch (e) {
            debugPrint('Error restoring budget: $e');
          }
        }
      }

      // Restore tasks
      if (backup['tasks'] != null) {
        for (var taskJson in backup['tasks']) {
          try {
            final data = Map<String, dynamic>.from(taskJson);
            data.remove('_id');
            data.remove('id');
            await _api.createTask(data);
          } catch (e) {
            debugPrint('Error restoring task: $e');
          }
        }
      }

      // Restore family members
      if (backup['familyMembers'] != null) {
        for (var memberJson in backup['familyMembers']) {
          try {
            final data = Map<String, dynamic>.from(memberJson);
            data.remove('_id');
            data.remove('id');
            await _api.createFamilyMember(data);
          } catch (e) {
            debugPrint('Error restoring family member: $e');
          }
        }
      }

      // Restore savings goals
      if (backup['savingsGoals'] != null) {
        for (var goalJson in backup['savingsGoals']) {
          try {
            final data = Map<String, dynamic>.from(goalJson);
            data.remove('_id');
            data.remove('id');
            await _api.createSavingsGoal(data);
          } catch (e) {
            debugPrint('Error restoring savings goal: $e');
          }
        }
      }

      // Restore family numbers
      if (backup['familyNumbers'] != null) {
        for (var numberJson in backup['familyNumbers']) {
          try {
            final data = Map<String, dynamic>.from(numberJson);
            data.remove('_id');
            data.remove('id');
            await _api.createFamilyNumber(data);
          } catch (e) {
            debugPrint('Error restoring family number: $e');
          }
        }
      }

      debugPrint('Backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    try {
      // We can't easily clear all data from MongoDB without specific endpoints
      // This would require backend support for bulk delete operations
      debugPrint(
        'Clear all data: Not implemented for MongoDB. Use MongoDB commands directly.',
      );
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  /// Get backup file size estimate
  Future<String> getBackupSizeEstimate() async {
    try {
      final backup = await createBackup();
      final jsonString = jsonEncode(backup);
      final bytes = utf8.encode(jsonString).length;

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Request storage permission (for backward compatibility)
  Future<bool> requestStoragePermission() async {
    // On modern Android/iOS, file picker handles its own permissions
    return true;
  }

  /// Save backup to custom location via file picker
  Future<String?> saveBackupToCustomLocation() async {
    try {
      final backup = await createBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      // Create a temporary file first
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'lifesync_backup_$timestamp.json';
      final tempPath = '${directory.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsString(jsonString);

      // Share the file (user can save it where they want)
      await Share.shareXFiles([XFile(tempPath)], text: 'LifeSync Backup');

      return tempPath;
    } catch (e) {
      debugPrint('Error saving backup to custom location: $e');
      return null;
    }
  }

  /// Restore from file with result details
  Future<Map<String, dynamic>> restoreFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final backup = jsonDecode(jsonString) as Map<String, dynamic>;

        // Count items before restore
        Map<String, int> itemsRestored = {
          'expenses': (backup['expenses'] as List?)?.length ?? 0,
          'incomes': (backup['incomes'] as List?)?.length ?? 0,
          'budgets': (backup['budgets'] as List?)?.length ?? 0,
          'tasks': (backup['tasks'] as List?)?.length ?? 0,
          'familyMembers': (backup['familyMembers'] as List?)?.length ?? 0,
          'savingsGoals': (backup['savingsGoals'] as List?)?.length ?? 0,
          'familyNumbers': (backup['familyNumbers'] as List?)?.length ?? 0,
        };

        final success = await restoreBackup(backup);

        return {'success': success, 'itemsRestored': itemsRestored};
      }

      return {'success': false, 'itemsRestored': {}};
    } catch (e) {
      debugPrint('Error restoring from file: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Open system settings (placeholder - not all platforms support this)
  Future<void> openSystemSettings() async {
    // This would require a platform-specific implementation
    debugPrint('Open system settings: Use platform-specific settings app');
  }
}
