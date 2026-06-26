/// Preset girl avatars bundled in the app. Server stores only the filename (e.g. avatar_05.svg).
class GirlsAvatarAssets {
  GirlsAvatarAssets._();

  static const legacyPrefix = 'girls_avatar:';
  static const assetDir = 'assets/avatar_svg_girls_files';

  static const presets = [
    'avatar_02.svg',
    'avatar_03.svg',
    'avatar_04.svg',
    'avatar_05.svg',
    'avatar_06.svg',
    'avatar_07.svg',
    'avatar_08.svg',
    'avatar_09.svg',
    'avatar_10.svg',
    'avatar_11.svg',
    'avatar_12.svg',
  ];

  static String assetPath(String fileName) => '$assetDir/$fileName';

  static String get defaultFileName => presets.first;

  static String? presetFileName(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;

    var file = avatarUrl.trim();
    if (file.startsWith(legacyPrefix)) {
      file = file.substring(legacyPrefix.length);
    }

    return presets.contains(file) ? file : null;
  }
}
