import 'package:flutter/material.dart';

class LetterAvatar extends StatelessWidget {
  const LetterAvatar({
    super.key,
    required this.name,
    this.radius = 24,
  });

  final String? name;
  final double radius;

  String get _initial {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Color get _color {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFFEAB308),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
    ];
    final code = _initial.codeUnitAt(0);
    return colors[code % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color.withValues(alpha: 0.18),
      child: Text(
        _initial,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
