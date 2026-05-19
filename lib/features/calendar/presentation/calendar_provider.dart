import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/calendar_model.dart';
import '../data/calendar_repository.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider(this._repository);

  final CalendarRepository _repository;

  CalendarModel? data;
  bool loading = false;
  String? error;
  DateTime selectedDate = _dateOnly(DateTime.now());
  DateTime focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    if (!refresh && data != null) return;
    loading = data == null || refresh;
    error = null;
    notifyListeners();
    try {
      data = await _repository.fetchCalendar();
      _selectInitialEventDate();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load calendar.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<CalendarCourseEvent> get events => data?.events ?? const [];

  List<CalendarCourseEvent> eventsFor(DateTime date) {
    return events.where((event) => event.occursOn(date)).toList();
  }

  List<CalendarCourseEvent> get selectedDateEvents => eventsFor(selectedDate);

  bool hasEventsOn(DateTime date) =>
      events.any((event) => event.occursOn(date));

  void selectDate(DateTime date) {
    selectedDate = _dateOnly(date);
    focusedMonth = DateTime(selectedDate.year, selectedDate.month);
    notifyListeners();
  }

  void previousMonth() {
    focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1);
    notifyListeners();
  }

  void goToToday() {
    final today = _dateOnly(DateTime.now());
    selectedDate = today;
    focusedMonth = DateTime(today.year, today.month);
    notifyListeners();
  }

  void _selectInitialEventDate() {
    if (hasEventsOn(selectedDate)) return;
    final firstDate =
        events
            .map((event) => event.startDate)
            .whereType<DateTime>()
            .map(_dateOnly)
            .toList()
          ..sort();
    if (firstDate.isEmpty) return;
    selectedDate = firstDate.first;
    focusedMonth = DateTime(selectedDate.year, selectedDate.month);
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
