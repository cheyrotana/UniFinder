import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show Brightness;

/// The one colour `tool/illustrations.py` leaves as the scene's accent.
const illustrationAccent = '#ff725e';

/// Recolours a scene for the theme.
///
/// The coral accent becomes [accent]. On a dark theme the greys turn round,
/// white paper to [paper] and dark ink part way towards [ink], so the scene
/// sits on a dark surface the way it sits on a light one; skin and other
/// colours stay.
/// Translucent shapes (highlights and shadows laid over other shapes) keep
/// their colour so they still lighten or darken what is under them.
String themeIllustration(
  String svg, {
  required Color accent,
  required Brightness brightness,
  required Color paper,
  required Color ink,
}) {
  final accentHex = _hex(accent);
  final dark = brightness == Brightness.dark;
  return svg.replaceAllMapped(_tag, (tag) {
    final text = tag.group(0)!;
    final keepNeutrals = !dark || _translucent.hasMatch(text);
    return text.replaceAllMapped(_colour, (m) {
      final hex = m.group(0)!;
      if (hex == illustrationAccent) return accentHex;
      if (keepNeutrals) return hex;
      final rgb = int.parse(hex.substring(1), radix: 16);
      final r = rgb >> 16 & 0xFF, g = rgb >> 8 & 0xFF, b = rgb & 0xFF;
      final spread = [r, g, b].reduce(_max) - [r, g, b].reduce(_min);
      if (spread > 20) return hex;
      final lightness = (r + g + b) / (3 * 255);
      // Light greys (paper, walls, floors) turn just above the dark
      // paper; dark ink (outlines, hair, clothes) only lifts to a mid grey,
      // so outlines read without everyone's hair turning white.
      final t = lightness >= 0.5 ? 1 - lightness : 0.3 + lightness * 0.6;
      return _hex(Color.lerp(paper, ink, t)!);
    });
  });
}

final _tag = RegExp(r'<[a-zA-Z][^>]*>');
final _colour = RegExp(r'#[0-9a-f]{6}\b');
final _translucent = RegExp(r'opacity[:=]\s*"?0?\.\d');

int _max(int a, int b) => a > b ? a : b;
int _min(int a, int b) => a < b ? a : b;

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
