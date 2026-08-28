// Generates the Nirbhor launcher and notification icons.
//
// The mark is the app's own brand glyph — the capsule already used on the onboarding screen —
// drawn in paper white on the calm green, tilted so it reads as an object rather than a bar, and
// split by a seam the way a real two-part capsule is. The seam is transparent rather than painted,
// so on the adaptive icon the background shows through it.
//
// Run with:  dart run tool/make_icons.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

// Palette, straight from lib/theme/colors.dart.
final calm = ColorRgba8(0x2F, 0x6B, 0x5B, 255);
final calmD = ColorRgba8(0x1F, 0x4F, 0x42, 255);
final paper = ColorRgba8(0xF4, 0xF2, 0xEC, 255);
final clear = ColorRgba8(0, 0, 0, 0);

/// Everything is laid out in the adaptive icon's 108x108dp space and scaled from there, so the
/// launcher icon and the notification icon are the same drawing at different sizes.
const box = 108.0;

/// The mark is tilted this far off horizontal. Enough to read as deliberate, not so far that it
/// looks like it is falling over.
const tiltDegrees = -30.0;

/// Supersampling factor. The capsule is all curves; drawing at 4x and averaging down is what keeps
/// the ends from stair-stepping at 48px.
const ss = 4;

void fillCapsule(Image img, double cx, double cy, double len, double h, Color color) {
  final r = h / 2;
  fillRect(img,
      x1: (cx - len / 2 + r).round(), y1: (cy - r).round(),
      x2: (cx + len / 2 - r).round(), y2: (cy + r).round(),
      color: color, alphaBlend: false);
  fillCircle(img, x: (cx - len / 2 + r).round(), y: cy.round(), radius: r.round(), color: color);
  fillCircle(img, x: (cx + len / 2 - r).round(), y: cy.round(), radius: r.round(), color: color);
}

/// Punches the capsule's seam out to full transparency. fillRect would blend rather than erase, so
/// the pixels are cleared directly.
void clearBand(Image img, double cx, double cy, double w, double h) {
  final x0 = (cx - w / 2).round(), x1 = (cx + w / 2).round();
  final y0 = (cy - h / 2).round(), y1 = (cy + h / 2).round();
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      if (x >= 0 && y >= 0 && x < img.width && y < img.height) {
        img.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
}

/// The tilted capsule on transparent ground, at [size] px square.
Image markLayer(int size, Color color, {double lengthRatio = 0.62, double heightRatio = 0.285}) {
  final s = size * ss;
  final scale = s / box;
  final layer = Image(width: s, height: s, numChannels: 4);
  fill(layer, color: clear);

  final cx = s / 2, cy = s / 2;
  final len = box * lengthRatio * scale;
  final h = box * heightRatio * scale;

  fillCapsule(layer, cx, cy, len, h, color);
  // Real capsules join a little off centre; matching that keeps it from reading as a plain bar.
  clearBand(layer, cx + len * 0.06, cy, 3.2 * scale, h + 2);

  final rotated = copyRotate(layer, angle: tiltDegrees, interpolation: Interpolation.cubic);
  // copyRotate grows the canvas to fit the corners; crop back to square about the centre.
  final ox = ((rotated.width - s) / 2).round(), oy = ((rotated.height - s) / 2).round();
  final cropped = copyCrop(rotated, x: ox, y: oy, width: s, height: s);
  return copyResize(cropped, width: size, height: size, interpolation: Interpolation.average);
}

/// The calm ground, with a slight lift from calm at the top to calmD at the foot.
Image ground(int size) {
  final img = Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final c = ColorRgba8(
      (calm.r + (calmD.r - calm.r) * t).round(),
      (calm.g + (calmD.g - calm.g) * t).round(),
      (calm.b + (calmD.b - calm.b) * t).round(),
      255,
    );
    fillRect(img, x1: 0, y1: y, x2: size - 1, y2: y, color: c, alphaBlend: false);
  }
  return img;
}

/// Rounds the corners of a full-bleed square by clearing everything outside the rounded rect.
void roundCorners(Image img, double radiusRatio) {
  final s = img.width;
  final r = s * radiusRatio;
  for (var y = 0; y < s; y++) {
    for (var x = 0; x < s; x++) {
      final dx = x < r ? r - x : (x > s - r ? x - (s - r) : 0.0);
      final dy = y < r ? r - y : (y > s - r ? y - (s - r) : 0.0);
      if (dx > 0 && dy > 0 && math.sqrt(dx * dx + dy * dy) > r) {
        img.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
}

void clipCircle(Image img) {
  final s = img.width;
  final c = (s - 1) / 2, r = s / 2;
  for (var y = 0; y < s; y++) {
    for (var x = 0; x < s; x++) {
      final dx = x - c, dy = y - c;
      if (math.sqrt(dx * dx + dy * dy) > r) img.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
}

void write(String path, Image img) {
  final f = File(path)..parent.createSync(recursive: true);
  f.writeAsBytesSync(encodePng(img));
  stdout.writeln('  ${path.split('/res/').last}  ${img.width}x${img.height}');
}

void main() {
  const res = 'android/app/src/main/res';

  // Launcher densities: mdpi .. xxxhdpi at 48/72/96/144/192.
  const densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  stdout.writeln('launcher (legacy, used where adaptive icons are not):');
  densities.forEach((dir, size) {
    final square = ground(size);
    compositeImage(square, markLayer(size, paper));
    roundCorners(square, 0.22);
    write('$res/$dir/ic_launcher.png', square);

    final round = ground(size);
    compositeImage(round, markLayer(size, paper));
    clipCircle(round);
    write('$res/$dir/ic_launcher_round.png', round);
  });

  // Notification small icon: Android keeps only the alpha channel and paints it white, so this is
  // a silhouette on transparent. Drawn a touch chunkier — a 24dp seam at 1dp would disappear.
  stdout.writeln('notification (alpha-only silhouette):');
  const notif = {
    'drawable-mdpi': 24,
    'drawable-hdpi': 36,
    'drawable-xhdpi': 48,
    'drawable-xxhdpi': 72,
    'drawable-xxxhdpi': 96,
  };
  notif.forEach((dir, size) {
    write('$res/$dir/ic_stat_nirbhor.png',
        markLayer(size, paper, lengthRatio: 0.74, heightRatio: 0.34));
  });

  // Play Store listing asset — 512x512, no transparency, no rounded corners.
  stdout.writeln('store:');
  final store = ground(512);
  compositeImage(store, markLayer(512, paper));
  write('$res/../../../../play-store-icon.png', store);
}
