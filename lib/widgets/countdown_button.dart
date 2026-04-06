import 'package:flutter/material.dart';
import 'dart:async';

/// A button that shows a countdown timer until the next meal generation is allowed
/// 
/// Displays "⏱️ Next meal in MM:SS" and is disabled during the countdown.
/// When the countdown reaches zero, calls [onReady] callback.
class CountdownButton extends StatefulWidget {
  final DateTime nextAvailableAt;
  final VoidCallback onReady;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const CountdownButton({
    super.key,
    required this.nextAvailableAt,
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
  late Duration _remainingTime;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  void _updateRemainingTime() {
    _remainingTime = widget.nextAvailableAt.difference(DateTime.now());
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();

      setState(() {
        if (_remainingTime.inSeconds <= 0) {
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
          '⏱️ Next meal in ${_formatDuration(_remainingTime)}',
          style: widget.textStyle ?? const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
