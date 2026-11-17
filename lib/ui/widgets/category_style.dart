import 'package:flutter/material.dart';

/// Each study category's colour and icon (categories.json ids), used on
/// chips, quiz options and as image fallbacks.
class CategoryStyle {
  const CategoryStyle(this.color, this.icon, this.short);

  final Color color;
  final IconData icon;

  /// A one-word label for chips.
  final String short;

  static const _styles = {
    '1': CategoryStyle(Color(0xFF2563EB), Icons.memory_rounded, 'Tech'),
    '2': CategoryStyle(Color(0xFF0E9F6E), Icons.trending_up_rounded, 'Business'),
    '3': CategoryStyle(Color(0xFFDB2777), Icons.palette_outlined, 'Arts'),
    '4': CategoryStyle(Color(0xFF7C3AED), Icons.science_outlined, 'Science'),
    '5': CategoryStyle(Color(0xFFE11D48), Icons.favorite_outline_rounded, 'Health'),
  };

  static CategoryStyle of(String? categoryId) =>
      _styles[categoryId] ??
      const CategoryStyle(Color(0xFF64748B), Icons.school_outlined, 'Other');
}
