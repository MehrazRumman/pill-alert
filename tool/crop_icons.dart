// Crops the two Nirbhor launcher icons out of a device screenshot and puts them side by side,
// upscaled, so the old and new marks can actually be compared.
import 'dart:io';
import 'package:image/image.dart';

void main(List<String> args) {
  final shot = decodePng(File(args[0]).readAsBytesSync())!;
  // Centres measured off the app-drawer screenshot, in its native 1080x2400 space.
  const r = 92;
  final old = copyCrop(shot, x: 900 - r, y: 1478 - r, width: r * 2, height: r * 2);
  final now = copyCrop(shot, x: 176 - r, y: 1793 - r, width: r * 2, height: r * 2);

  const out = 300, gap = 40, pad = 28;
  final canvas = Image(width: out * 2 + gap + pad * 2, height: out + pad * 2, numChannels: 4);
  fill(canvas, color: ColorRgba8(0xF4, 0xF2, 0xEC, 255));
  compositeImage(canvas, copyResize(old, width: out, height: out, interpolation: Interpolation.cubic),
      dstX: pad, dstY: pad);
  compositeImage(canvas, copyResize(now, width: out, height: out, interpolation: Interpolation.cubic),
      dstX: pad + out + gap, dstY: pad);
  File(args[1]).writeAsBytesSync(encodePng(canvas));
  stdout.writeln('wrote ${args[1]}');
}
