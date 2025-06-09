import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeZoneInfo {
  final String name;
  final String label;
  final Duration offset;
  TimeZoneInfo({required this.name, required this.label, required this.offset});
}

class TimeZoneProvider with ChangeNotifier {
  static final List<TimeZoneInfo> timeZones = [
    TimeZoneInfo(name: 'WIB', label: 'WIB (GMT+7)', offset: Duration(hours: 7)),
    TimeZoneInfo(
        name: 'WITA', label: 'WITA (GMT+8)', offset: Duration(hours: 8)),
    TimeZoneInfo(name: 'WIT', label: 'WIT (GMT+9)', offset: Duration(hours: 9)),
    TimeZoneInfo(
        name: 'London', label: 'London (GMT+0)', offset: Duration(hours: 0)),
    TimeZoneInfo(
        name: 'New York',
        label: 'New York (GMT-4)',
        offset: Duration(hours: -4)),
    TimeZoneInfo(
        name: 'Tokyo', label: 'Tokyo (GMT+9)', offset: Duration(hours: 9)),
    TimeZoneInfo(
        name: 'Sydney', label: 'Sydney (GMT+10)', offset: Duration(hours: 10)),
    // Tambahkan zona lain jika perlu
  ];

  TimeZoneInfo _selectedTimeZone = timeZones[0];
  TimeZoneInfo get selectedTimeZone => _selectedTimeZone;

  void setTimeZone(TimeZoneInfo tz) {
    _selectedTimeZone = tz;
    notifyListeners();
  }

  DateTime convert(DateTime local) {
    final now = DateTime.now();
    final localOffset = now.timeZoneOffset;
    if (_selectedTimeZone.offset == localOffset) {
      // Tidak perlu konversi
      return local;
    }
    final diff = _selectedTimeZone.offset - localOffset;
    return local.add(diff);
  }

  String format(DateTime utc, {String pattern = 'dd/MM/yy HH:mm'}) {
    final local = convert(utc);
    return DateFormat(pattern).format(local);
  }
}
