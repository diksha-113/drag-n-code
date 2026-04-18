// field_date.dart
import 'package:flutter/material.dart';

/// A date input field similar to Blockly's FieldDate.
/// Opens a date picker dialog and returns ISO date string.
class FieldDate extends StatefulWidget {
  final String initialDate;
  final ValueChanged<String>? onDateChanged;

  const FieldDate({
    super.key,
    required this.initialDate,
    this.onDateChanged,
  });

  @override
  State<FieldDate> createState() => _FieldDateState();
}

class _FieldDateState extends State<FieldDate> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseIso(widget.initialDate);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black26),
        ),
        child: Text(
          _formatIso(_selectedDate),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  void _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });

      widget.onDateChanged?.call(_formatIso(_selectedDate));
    }
  }

  /// Convert ISO string (YYYY-MM-DD) to DateTime.
  DateTime _parseIso(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Convert DateTime to ISO string.
  String _formatIso(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
}
