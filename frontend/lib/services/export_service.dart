import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/budget.dart';
import '../models/task.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Export expenses to CSV
  Future<String?> exportExpensesToCSV(List<Expense> expenses) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add([
        'Date',
        'Title',
        'Category',
        'Amount',
        'Payment Method',
        'Description',
      ]);

      for (var expense in expenses) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(expense.date),
          expense.title,
          expense.category,
          expense.amount.toStringAsFixed(2),
          expense.paymentMethod ?? 'Not specified',
          expense.notes ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/expenses_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      return path;
    } catch (e) {
      debugPrint('Error exporting expenses to CSV: $e');
      return null;
    }
  }

  // Export income to CSV
  Future<String?> exportIncomeToCSV(List<Income> incomes) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add([
        'Date',
        'Title',
        'Source',
        'Amount',
        'Payment Method',
        'Recurring',
        'Description',
      ]);

      for (var income in incomes) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(income.date),
          income.title,
          income.source,
          income.amount.toStringAsFixed(2),
          income.paymentMethod ?? 'Not specified',
          income.isRecurring ? 'Yes' : 'No',
          income.notes ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/income_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      return path;
    } catch (e) {
      debugPrint('Error exporting income to CSV: $e');
      return null;
    }
  }

  // Export budgets to CSV
  Future<String?> exportBudgetsToCSV(List<Budget> budgets) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add([
        'Category',
        'Allocated Amount',
        'Spent Amount',
        'Remaining',
        'Percentage Used',
        'Status',
      ]);

      for (var budget in budgets) {
        final percentage = (budget.spentAmount / budget.allocatedAmount * 100);
        rows.add([
          budget.category,
          budget.allocatedAmount.toStringAsFixed(2),
          budget.spentAmount.toStringAsFixed(2),
          (budget.allocatedAmount - budget.spentAmount).toStringAsFixed(2),
          '${percentage.toStringAsFixed(1)}%',
          budget.isOverBudget ? 'Over Budget' : 'On Track',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/budgets_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      return path;
    } catch (e) {
      debugPrint('Error exporting budgets to CSV: $e');
      return null;
    }
  }

  // Export tasks to CSV
  Future<String?> exportTasksToCSV(List<Task> tasks) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add([
        'Title',
        'Category',
        'Priority',
        'Due Date',
        'Status',
        'Assigned To',
        'Description',
      ]);

      for (var task in tasks) {
        rows.add([
          task.title,
          task.category,
          task.priority,
          task.dueDate != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)
              : 'No due date',
          task.isCompleted ? 'Completed' : 'Pending',
          task.assignedTo ?? '',
          task.description ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/tasks_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      return path;
    } catch (e) {
      debugPrint('Error exporting tasks to CSV: $e');
      return null;
    }
  }

  // Generate financial summary report
  Future<String?> generateFinancialSummary({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryExpenses,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final buffer = StringBuffer();
      final dateFormat = DateFormat('MMM d, yyyy');

      buffer.writeln('FINANCIAL SUMMARY REPORT');
      buffer.writeln('========================');
      buffer.writeln();
      buffer.writeln(
        'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
      );
      buffer.writeln();
      buffer.writeln('OVERVIEW');
      buffer.writeln('--------');
      buffer.writeln('Total Income:    ₹${totalIncome.toStringAsFixed(2)}');
      buffer.writeln('Total Expenses:  ₹${totalExpenses.toStringAsFixed(2)}');
      buffer.writeln(
        'Net Savings:     ₹${(totalIncome - totalExpenses).toStringAsFixed(2)}',
      );
      buffer.writeln();
      buffer.writeln('CATEGORY BREAKDOWN');
      buffer.writeln('------------------');

      final sortedCategories = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedCategories) {
        final percentage = (entry.value / totalExpenses * 100);
        buffer.writeln(
          '${entry.key.padRight(20)} ₹${entry.value.toStringAsFixed(2).padLeft(12)} (${percentage.toStringAsFixed(1)}%)',
        );
      }

      buffer.writeln();
      buffer.writeln(
        'Generated on: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}',
      );
      buffer.writeln('Generated by: LifeSync App v2.0');

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/financial_summary_$timestamp.txt';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      return path;
    } catch (e) {
      debugPrint('Error generating financial summary: $e');
      return null;
    }
  }

  // Share file
  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles([
        file,
      ], subject: subject ?? 'Financial Report from LifeSync');
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  // Share text
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject ?? 'Report from LifeSync');
    } catch (e) {
      debugPrint('Error sharing text: $e');
      rethrow;
    }
  }

  // Delete temporary file
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
