/// Blur mode for the standalone AI Blur Focus feature.
enum AfBlurMode { smart, circle, line }

/// Rendering quality tiers — controls pixel resolution and encode format.
enum AfRenderQuality {
  /// Ultra-fast, tiny frame — rendered while finger is moving.
  track,

  /// Mid-quality JPEG — rendered after brief drag pause.
  previewIdle,

  /// Full-resolution PNG — only on explicit Apply/Export.
  export,
}
