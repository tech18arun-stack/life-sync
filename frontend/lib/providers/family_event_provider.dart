import 'package:flutter/foundation.dart';
import '../models/family_event.dart';

class FamilyEventProvider with ChangeNotifier {
  final List<FamilyEvent> _events = [];
  bool _isLoading = false;

  List<FamilyEvent> get events => _events;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    // Note: Family events are stored locally for now
    // Can be extended to use MongoDB API if needed
    _isLoading = false;
    notifyListeners();
  }

  void addEvent(FamilyEvent event) {
    _events.add(event);
    notifyListeners();
  }

  void updateEvent(FamilyEvent event) {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
    }
  }

  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<FamilyEvent> getEventsForDate(DateTime date) {
    return _events.where((e) {
      if (e.isAllDay) {
        return e.startDate.year == date.year &&
            e.startDate.month == date.month &&
            e.startDate.day == date.day;
      }
      return e.startDate.year == date.year &&
          e.startDate.month == date.month &&
          e.startDate.day == date.day;
    }).toList();
  }

  List<FamilyEvent> getEventsForMonth(int year, int month) {
    return _events.where((e) {
      return e.startDate.year == year && e.startDate.month == month;
    }).toList();
  }

  List<FamilyEvent> getUpcomingEvents({int days = 7}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    return _events.where((e) {
      return e.startDate.isAfter(now) && e.startDate.isBefore(futureDate);
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  List<FamilyEvent> getTodayEvents() {
    final now = DateTime.now();
    return getEventsForDate(now);
  }

  List<FamilyEvent> getEventsByCategory(String category) {
    return _events.where((e) => e.category == category).toList();
  }

  bool hasEventsOnDate(DateTime date) {
    return getEventsForDate(date).isNotEmpty;
  }
}
