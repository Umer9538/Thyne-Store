import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool showLabels;
  final VoidCallback? onTimerEnd;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.textStyle,
    this.backgroundColor,
    this.padding,
    this.showLabels = true,
    this.onTimerEnd,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = widget.endTime.difference(DateTime.now());
      if (_timeRemaining.isNegative) {
        _timeRemaining = Duration.zero;
        _timer.cancel();
        widget.onTimerEnd?.call();
      }
    });
  }

  String _formatNumber(int number) {
    return number.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    final textStyle = widget.textStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            );

    final labelStyle = widget.textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            );

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.red.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (days > 0) ...[
            _buildTimeUnit(days, 'Days', textStyle, labelStyle),
            _buildSeparator(textStyle),
          ],
          _buildTimeUnit(hours, 'Hrs', textStyle, labelStyle),
          _buildSeparator(textStyle),
          _buildTimeUnit(minutes, 'Min', textStyle, labelStyle),
          _buildSeparator(textStyle),
          _buildTimeUnit(seconds, 'Sec', textStyle, labelStyle),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, TextStyle? valueStyle, TextStyle? labelStyle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatNumber(value),
          style: valueStyle,
        ),
        if (widget.showLabels)
          Text(
            label,
            style: labelStyle,
          ),
      ],
    );
  }

  Widget _buildSeparator(TextStyle? textStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: textStyle,
      ),
    );
  }
}

class CompactCountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final VoidCallback? onTimerEnd;

  const CompactCountdownTimer({
    super.key,
    required this.endTime,
    this.textStyle,
    this.onTimerEnd,
  });

  @override
  State<CompactCountdownTimer> createState() => _CompactCountdownTimerState();
}

class _CompactCountdownTimerState extends State<CompactCountdownTimer> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = widget.endTime.difference(DateTime.now());
      if (_timeRemaining.isNegative) {
        _timeRemaining = Duration.zero;
        _timer.cancel();
        widget.onTimerEnd?.call();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer, size: 16, color: Colors.red),
        const SizedBox(width: 4),
        Text(
          _formatDuration(_timeRemaining),
          style: textStyle,
        ),
      ],
    );
  }
}
