import 'package:flutter/material.dart';
import 'dart:async';

/// A button that shows a countdown timer until the next meal generation is allowed
/// 
/// Displays "⏱️ X mins remaining" and is disabled during the countdown.
/// When the countdown reaches zero, calls [onReady] callback.
class CountdownButton extends StatefulWidget {
  final int waitingMinutes;  // Number of minutes to wait
  final VoidCallback onReady;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const CountdownButton({
    super.key,
    required this.waitingMinutes,
    required this.onReady,
    this.width,
    this.height,
    this.textStyle,
  });

  @override
  State<CountdownButton> createState() => _CountdownButtonState();
}

class _CountdownButtonState extends State<CountdownButton> {
  late Timer _timer;
  late int _remainingMinutes;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _remainingMinutes = widget.waitingMinutes;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _remainingMinutes--;
        
        if (_remainingMinutes <= 0) {
          _isExpired = true;
          _timer.cancel();
          // Call the callback to notify parent
          widget.onReady();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatMinutes(int minutes) {
    if (minutes == 1) {
      return "1 min remaining";
    }
    return "$minutes mins remaining";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isExpired) {
      // When expired, show the normal "Find a Meal" button
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 56,
        child: ElevatedButton(
          onPressed: widget.onReady,
          child: Text(
            '✨ Find a Meal',
            style: widget.textStyle ?? const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 56,
      child: ElevatedButton.icon(
        onPressed: null, // Disabled
        icon: const Icon(Icons.schedule),
        label: Text(
          '⏱️ ${_formatMinutes(_remainingMinutes)}',
          style: widget.textStyle ?? const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
