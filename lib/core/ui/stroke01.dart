import 'dart:collection';
import 'dart:typed_data';
import 'package:image/image.dart' as im;

/// ══════════════════════════════════════════════════════════════
///  prepareMaskForLama
///
///  Takes the raw binary mask PNG from renderMaskPng() and applies
///  morphological post-processing to improve LaMa results:
///
///   1) Binary clean   — threshold to strict 0/255
///   2) Closing        — dilate(r=6) then erode(r=6) closes small gaps
///   3) Fill holes     — enclosed black islands inside white become white
///   4) Expand (r=2)   — slight over-mask so LaMa covers object edges
///   5) Re-encode      — RGBA PNG with alpha=255 (fully opaque)
///
///  Output: PNG bytes, same dimensions as input, ready to upload.
/// ══════════════════════════════════════════════════════════════
Future<Uint8List> prepareMaskForLama(Uint8List rawPng) async {
  final src = im.decodePng(rawPng);
  if (src == null) throw Exception('prepareMaskForLama: cannot decode PNG');

  final w = src.width;
  final h = src.height;

  // ── Step 1: threshold to strict binary ──────────────────────
  final bin = im.Image(width: w, height: h, numChannels: 1);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      // Average of R+G+B to handle both grayscale and RGBA inputs
      final avg = (p.r.toInt() + p.g.toInt() + p.b.toInt()) ~/ 3;
      bin.setPixelR(x, y, avg >= 127 ? 255 : 0);
    }
  }

  // ── Step 2: morphological closing (close small gaps) ────────
  var work = _dilate(bin, radius: 6);
  work = _erode(work, radius: 6);

  // ── Step 3: fill enclosed black holes ───────────────────────
  work = _fillHoles(work);

  // ── Step 4: slight expansion so edges are fully covered ─────
  work = _dilate(work, radius: 2);

  // ── Step 5: re-encode as RGBA PNG (alpha = 255) ─────────────
  final out = im.Image(width: w, height: h, numChannels: 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final v = work.getPixel(x, y).r.toInt() >= 127 ? 255 : 0;
      out.setPixelRgba(x, y, v, v, v, 255);
    }
  }

  return Uint8List.fromList(im.encodePng(out));
}

// ── Morphological dilation ────────────────────────────────────
im.Image _dilate(im.Image src, {required int radius}) {
  final w = src.width, h = src.height;
  final dst = im.Image(width: w, height: h, numChannels: 1);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      // If any neighbour in [radius] is white → this pixel is white
      bool found = false;
      outer:
      for (int ky = -radius; ky <= radius; ky++) {
        final ny = y + ky;
        if (ny < 0 || ny >= h) continue;
        for (int kx = -radius; kx <= radius; kx++) {
          final nx = x + kx;
          if (nx < 0 || nx >= w) continue;
          if (src.getPixel(nx, ny).r.toInt() >= 127) {
            found = true;
            break outer;
          }
        }
      }
      dst.setPixelR(x, y, found ? 255 : 0);
    }
  }
  return dst;
}

// ── Morphological erosion ─────────────────────────────────────
im.Image _erode(im.Image src, {required int radius}) {
  final w = src.width, h = src.height;
  final dst = im.Image(width: w, height: h, numChannels: 1);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      // If any neighbour in [radius] is black → this pixel is black
      bool allWhite = true;
      outer:
      for (int ky = -radius; ky <= radius; ky++) {
        final ny = y + ky;
        if (ny < 0 || ny >= h) {
          allWhite = false;
          break;
        }
        for (int kx = -radius; kx <= radius; kx++) {
          final nx = x + kx;
          if (nx < 0 || nx >= w) {
            allWhite = false;
            break outer;
          }
          if (src.getPixel(nx, ny).r.toInt() < 127) {
            allWhite = false;
            break outer;
          }
        }
      }
      dst.setPixelR(x, y, allWhite ? 255 : 0);
    }
  }
  return dst;
}

/// Fill enclosed black islands with white using flood-fill from edges.
im.Image _fillHoles(im.Image src) {
  final w = src.width, h = src.height;
  final dst = im.Image.from(src);

  // visited[i] = 1 means "reachable from border" (background black)
  final visited = Uint8List(w * h);
  final queue = Queue<int>(); // store flat index

  void enqueue(int x, int y) {
    if (x < 0 || x >= w || y < 0 || y >= h) return;
    final i = y * w + x;
    if (visited[i] == 1) return;
    if (dst.getPixel(x, y).r.toInt() >= 127) return; // white pixel = skip
    visited[i] = 1;
    queue.add(i);
  }

  // Seed from all border pixels that are black
  for (int x = 0; x < w; x++) {
    enqueue(x, 0);
    enqueue(x, h - 1);
  }
  for (int y = 1; y < h - 1; y++) {
    enqueue(0, y);
    enqueue(w - 1, y);
  }

  // BFS
  while (queue.isNotEmpty) {
    final i = queue.removeFirst();
    final x = i % w;
    final y = i ~/ w;
    enqueue(x + 1, y);
    enqueue(x - 1, y);
    enqueue(x, y + 1);
    enqueue(x, y - 1);
  }

  // Any black pixel NOT reachable from border = enclosed hole → fill white
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = y * w + x;
      if (visited[i] == 0 && dst.getPixel(x, y).r.toInt() < 127) {
        dst.setPixelR(x, y, 255);
      }
    }
  }

  return dst;
}
