enum BlurPhotoStyle {
  soft,
  frost,
  motion,
  crystal,
  spotlight,
}

extension BlurPhotoStyleLabel on BlurPhotoStyle {
  String get label => switch (this) {
        BlurPhotoStyle.soft => 'Soft',
        BlurPhotoStyle.frost => 'Frost',
        BlurPhotoStyle.motion => 'Motion',
        BlurPhotoStyle.crystal => 'Crystal',
        BlurPhotoStyle.spotlight => 'Spotlight',
      };

  String get description => switch (this) {
        BlurPhotoStyle.soft => 'Natural background blur',
        BlurPhotoStyle.frost => 'Bright glassy blur',
        BlurPhotoStyle.motion => 'Directional speed feel',
        BlurPhotoStyle.crystal => 'Sharper edge transition',
        BlurPhotoStyle.spotlight => 'Soft center emphasis',
      };
}
