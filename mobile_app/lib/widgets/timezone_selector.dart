import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timezone_provider.dart';

class TimeZoneSelector extends StatelessWidget {
  const TimeZoneSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeZoneProvider>(context);
    return DropdownButton<TimeZoneInfo>(
      value: provider.selectedTimeZone,
      underline: const SizedBox(),
      items: TimeZoneProvider.timeZones.map((tz) {
        return DropdownMenuItem(
          value: tz,
          child: Text(tz.name),
        );
      }).toList(),
      onChanged: (tz) {
        if (tz != null) provider.setTimeZone(tz);
      },
    );
  }
}
