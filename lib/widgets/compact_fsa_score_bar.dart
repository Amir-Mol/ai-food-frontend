import 'package:flutter/material.dart';

/// A StatelessWidget that displays a compact healthiness score bar.
///
/// It accepts a health score from 1 (least healthy) to 10 (healthiest)
/// and maps it to a visual gradient bar.
class CompactFsaScoreBar extends StatelessWidget {
  /// The health score, where 1 is least healthy and 10 is healthiest.
  final double healthScore;

  const CompactFsaScoreBar({super.key, required this.healthScore});


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // --- LOGIC: Map the 1-10 score to a 0.0-1.0 percentage ---
    // Score 1 (least healthy) = 0.0 (left/red), Score 10 (healthiest) = 1.0 (right/green).
    final clampedScore = healthScore.clamp(1.0, 10.0);
    final double percentage = (clampedScore - 1) / 9.0;

    const double barHeight = 12.0;
    const double indicatorWidth = 8.0;
    const double indicatorHeight = 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Healthiness Score:",
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4.0),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double barWidth = constraints.maxWidth;
            final double indicatorPosition = percentage * barWidth;
            // Adjust to center the indicator on its calculated position
            final double adjustedIndicatorLeft = indicatorPosition - (indicatorWidth / 2);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.green,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: adjustedIndicatorLeft.clamp(0, barWidth - indicatorWidth),
                  top: (barHeight - indicatorHeight) / 2,
                  child: Container(
                    width: indicatorWidth,
                    height: indicatorHeight,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.white, width: 1.0),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Less Healthy", style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            Text("Healthier", style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}