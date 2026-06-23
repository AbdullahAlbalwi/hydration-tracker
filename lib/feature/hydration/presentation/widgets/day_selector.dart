import 'package:flutter/material.dart';
import 'package:hydration_tracker/core/date_key.dart';
import 'package:hydration_tracker/core/theme/app_colors.dart';

/// Horizontal strip of recent days. Tapping a day changes the active date,
/// which reloads everything below it. Future days are not selectable.
class DaySelector extends StatefulWidget {
  const DaySelector({
    required this.selectedDate,
    required this.onSelect,
    this.daysBack = 21,
    super.key,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  final int daysBack;

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  static const _itemWidth = 60.0;

  late final ScrollController _controller;
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    // Oldest -> today, so today sits at the right edge.
    _days = List.generate(
      widget.daysBack + 1,
      (i) => today.subtract(Duration(days: widget.daysBack - i)),
    );
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedKey = dateKeyOf(widget.selectedDate);
    return SizedBox(
      height: 76,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = dateKeyOf(day) == selectedKey;
          return _DayChip(
            width: _itemWidth,
            weekday: _weekdays[day.weekday - 1],
            dayNumber: day.day,
            month: _months[day.month - 1],
            isSelected: isSelected,
            onTap: () => widget.onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.width,
    required this.weekday,
    required this.dayNumber,
    required this.month,
    required this.isSelected,
    required this.onTap,
  });

  final double width;
  final String weekday;
  final int dayNumber;
  final String month;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              month,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
