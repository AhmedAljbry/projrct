/// Blur modes available in the Blur Photo editor.
enum BlurPhotoMode {
  /// Blur the entire image.
  full,

  /// Blur only detected text regions.
  text,

  /// AI-assisted background blur preserving the detected subject.
  smart,

  /// Circular focus region — draggable center + adjustable radius.
  circle,

  /// Linear / tilt-shift band — draggable, rotatable, adjustable width.
  line,
}

/// Rendering quality tiers used across the preview + export pipeline.
enum BpRenderQuality {
  /// Ultra-fast low-res frame rendered while the user's finger is moving.
  track,

  /// Mid-quality JPEG frame rendered after a brief interaction pause.
  previewIdle,

  /// Full-resolution PNG rendered only on explicit export.
  export,
}

extension BlurPhotoModeLabel on BlurPhotoMode {
  String get label => switch (this) {
        BlurPhotoMode.full => 'Full',
        BlurPhotoMode.text => 'Text',
        BlurPhotoMode.smart => 'Smart',
        BlurPhotoMode.circle => 'Circle',
        BlurPhotoMode.line => 'Line',
      };
}
