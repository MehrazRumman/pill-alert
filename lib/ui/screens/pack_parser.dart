import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// What the scanner managed to read off a pack.
class ParsedPack {
  const ParsedPack({required this.name, required this.strength, required this.form});

  final String name;
  final String strength;

  /// Canonical English form word — callers localise it before storing.
  final String form;
}

/// One recognised line of pack text plus where it sat in the frame.
///
/// [relativeHeight] is the line's cap height as a fraction of the tallest line in the same photo,
/// and it is what actually identifies a medicine: on a pack the brand name is printed larger than
/// anything else, whereas its position in the reading order is not dependable at all.
/// [centreOffset] is the distance from the middle of the frame (0 = dead centre, 1 = edge), used to
/// prefer whatever the patient framed inside the reticle over text that merely wandered into shot.
class PackLine {
  const PackLine(this.text, {this.relativeHeight = 0, this.centreOffset = 0});

  final String text;
  final double relativeHeight;
  final double centreOffset;
}

final RegExp _strengthPattern = RegExp(
  r'\b\d+(?:[.,]\d+)?\s*(?:mg|mcg|µg|g|ml|iu|units?)\b',
  caseSensitive: false,
);
final RegExp _formPattern = RegExp(
  r'\b(tablets?|capsules?|syrup|suspension|injection|injectable)\b',
  caseSensitive: false,
);
final RegExp _metadataPattern = RegExp(
  r'\b(batch|lot|mfg|manufactured|exp|expiry|expires|price|mrp|marketed|distributed|license|'
  r'reg(?:istration)?|pharma(?:ceuticals?)?|laborator(?:y|ies)|ltd|limited|inc|store|storage|'
  r'keep out of reach|children|prescription|dosage|directions|www\.|\.com)\b',
  caseSensitive: false,
);
final RegExp _pharmacopoeia = RegExp(r'\b(usp|bp|ip)\b', caseSensitive: false);
final RegExp _runsOfSpace = RegExp(r'\s{2,}');

String _medicineNameFrom(String line) {
  var out = line
      .replaceAll(_strengthPattern, '')
      .replaceAll(_formPattern, '')
      .replaceAll(_pharmacopoeia, '')
      .replaceAll(_runsOfSpace, ' ');
  const trimmable = ' -·:,.';
  var start = 0;
  var end = out.length;
  while (start < end && trimmable.contains(out[start])) {
    start++;
  }
  while (end > start && trimmable.contains(out[end - 1])) {
    end--;
  }
  out = out.substring(start, end);
  return out.length > 80 ? out.substring(0, 80) : out;
}

bool _isLetter(String c) => RegExp(r'\p{L}', unicode: true).hasMatch(c);

int _countLetters(String s) {
  var n = 0;
  for (final c in s.split('')) {
    if (_isLetter(c)) n++;
  }
  return n;
}

/// Plain-text entry point: no geometry available, so fall back to reading order.
ParsedPack? parsePackText(String text) =>
    parsePackLines(text.split('\n').map(PackLine.new).toList());

ParsedPack? parsePackLines(List<PackLine> rawLines) {
  final lines = rawLines
      .map((l) => PackLine(
            l.text.trim(),
            relativeHeight: l.relativeHeight,
            centreOffset: l.centreOffset,
          ))
      .where((l) => l.text.length >= 2)
      .toList();
  if (lines.isEmpty) return null;
  final hasGeometry = lines.any((l) => l.relativeHeight > 0);

  String? bestName;
  PackLine? bestLine;
  var bestScore = double.negativeInfinity;

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (_metadataPattern.hasMatch(line.text)) continue;
    final name = _medicineNameFrom(line.text);
    final letters = _countLetters(name);
    if (name.length < 2 || letters == 0) continue;
    // A line that is mostly digits and punctuation is a batch code or a price, not a name.
    if (letters * 2 < name.length) continue;

    var score = 0.0;
    if (hasGeometry) {
      // Dominant signal: the biggest words on a pack are its name.
      score += line.relativeHeight * 8;
      score += (1 - line.centreOffset.clamp(0.0, 1.0)) * 2;
    } else if (index < 3) {
      score += 3;
    }
    if (_strengthPattern.hasMatch(line.text)) score += 2;
    if (_formPattern.hasMatch(line.text)) score += 1;
    if (name.length >= 3 && name.length <= 40) score += 2;

    if (score > bestScore) {
      bestScore = score;
      bestName = name;
      bestLine = line;
    }
  }

  if (bestName == null || bestLine == null) return null;

  // Prefer the strength printed on the name's own line; packs often list several numbers.
  var strength = _strengthPattern.firstMatch(bestLine.text)?.group(0);
  if (strength == null) {
    final byHeight = List.of(lines)
      ..sort((a, b) => b.relativeHeight.compareTo(a.relativeHeight));
    for (final l in byHeight) {
      final match = _strengthPattern.firstMatch(l.text);
      if (match != null) {
        strength = match.group(0);
        break;
      }
    }
  }

  final all = lines.map((l) => l.text).join(' ').toLowerCase();
  final form = all.contains('capsule') || all.contains('cap.')
      ? 'capsule'
      : all.contains('syrup') || all.contains('suspension')
          ? 'syrup'
          : all.contains('injection') || all.contains('injectable')
              ? 'injection'
              : 'tablet';

  return ParsedPack(name: bestName, strength: (strength ?? '').trim(), form: form);
}

/// Turns ML Kit's block/line tree into [PackLine]s, normalised against the frame.
List<PackLine> packLinesFrom(RecognizedText result) {
  final lines = [for (final block in result.blocks) ...block.lines];
  if (lines.isEmpty) return const [];
  final boxes = lines.map((l) => l.boundingBox).toList();

  var tallest = 1.0;
  var minY = double.infinity;
  var maxY = double.negativeInfinity;
  for (final b in boxes) {
    tallest = math.max(tallest, b.height);
    minY = math.min(minY, b.top);
    maxY = math.max(maxY, b.bottom);
  }
  // The frame's own extent, derived from the text found in it — ML Kit may have rotated the image,
  // so deriving the bounds from the boxes avoids depending on which way round the photo was.
  final span = math.max(1.0, maxY - minY);
  final midY = (minY + maxY) / 2;

  return [
    for (final line in lines)
      PackLine(
        line.text,
        relativeHeight: line.boundingBox.height / tallest,
        centreOffset: (line.boundingBox.center.dy - midY).abs() / (span / 2),
      ),
  ];
}
