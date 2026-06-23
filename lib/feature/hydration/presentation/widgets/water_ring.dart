import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hydration_tracker/core/theme/app_colors.dart';
import 'package:hydration_tracker/feature/hydration/domain/entities/daily_summary.dart';

/// Circular progress ring showing consumed / goal for the selected day.
///
/// Reads everything from the server-computed [DailySummary]; it never sums logs.
class WaterRing extends StatelessWidget {
  const WaterRing({required this.summary, this.size = 220, super.key});

  final DailySummary summary;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percent = (summary.progress * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: summary.progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${summary.totalMl}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of ${summary.goalMl} ml',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: summary.goalMet
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.goalMet ? 'Goal met · $percent%' : '$percent%',
                  style: TextStyle(
                    color: summary.goalMet
                        ? AppColors.success
                        : AppColors.accentSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  static const _stroke = 18.0;
  static const _startAngle = -math.pi / 2; // top

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    final arc = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accent, AppColors.accentSoft],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
