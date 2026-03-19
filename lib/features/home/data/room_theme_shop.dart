/// Room themes available for purchase in the Room Theme Shop.
///
/// Each theme maps to a background PNG in `assets/sprites/room_backgrounds/`.
/// The starter theme is free; all others require coins and a minimum player level.
class RoomTheme {
  const RoomTheme({
    required this.themeId,
    required this.nameTh,
    required this.nameEn,
    required this.descriptionTh,
    required this.price,
    required this.unlockLevel,
    required this.previewAsset,
    required this.backgroundAsset,
    required this.emoji,
  });

  /// Unique identifier stored in Firestore.
  final String themeId;

  /// Thai display name.
  final String nameTh;

  /// English display name.
  final String nameEn;

  /// Thai description shown on the shop card.
  final String descriptionTh;

  /// Coin cost to purchase. 0 = free / included.
  final int price;

  /// Minimum player level required to purchase.
  final int unlockLevel;

  /// Full asset path for the shop card preview image.
  final String previewAsset;

  /// Filename only — used by the Flame room renderer.
  final String backgroundAsset;

  /// Decorative emoji for the shop card header.
  final String emoji;
}

/// All 12 room themes in ascending unlock order.
///
/// 3 base rooms + 9 Wall Street variants.
const List<RoomTheme> kRoomThemes = [
  // ── Base Rooms ──────────────────────────────────────────────────────────────
  RoomTheme(
    themeId: 'starter',
    nameTh: '\u0e2b\u0e49\u0e2d\u0e07\u0e40\u0e23\u0e34\u0e48\u0e21\u0e15\u0e49\u0e19',
    nameEn: 'Starter Room',
    descriptionTh: '\u0e2b\u0e49\u0e2d\u0e07\u0e41\u0e23\u0e01\u0e02\u0e2d\u0e07\u0e04\u0e38\u0e13\u0e43\u0e19\u0e42\u0e25\u0e01\u0e1e\u0e34\u0e01\u0e40\u0e0b\u0e25',
    price: 0,
    unlockLevel: 1,
    previewAsset: 'assets/sprites/room_backgrounds/room_starter.png',
    backgroundAsset: 'room_starter.png',
    emoji: '\ud83c\udfe0',
  ),
  RoomTheme(
    themeId: 'office',
    nameTh: '\u0e2a\u0e33\u0e19\u0e31\u0e01\u0e07\u0e32\u0e19',
    nameEn: 'Office',
    descriptionTh: '\u0e2a\u0e33\u0e19\u0e31\u0e01\u0e07\u0e32\u0e19\u0e0b\u0e37\u0e49\u0e2d\u0e02\u0e32\u0e22\u0e2b\u0e38\u0e49\u0e19\u0e41\u0e1a\u0e1a\u0e21\u0e37\u0e2d\u0e2d\u0e32\u0e0a\u0e35\u0e1e',
    price: 300,
    unlockLevel: 2,
    previewAsset: 'assets/sprites/room_backgrounds/room_office.png',
    backgroundAsset: 'room_office.png',
    emoji: '\ud83c\udfe2',
  ),
  RoomTheme(
    themeId: 'penthouse',
    nameTh: '\u0e40\u0e1e\u0e19\u0e17\u0e4c\u0e40\u0e2e\u0e32\u0e2a\u0e4c',
    nameEn: 'Penthouse',
    descriptionTh: '\u0e27\u0e34\u0e27\u0e08\u0e32\u0e01\u0e0a\u0e31\u0e49\u0e19\u0e1a\u0e19\u0e2a\u0e38\u0e14 \u0e2a\u0e33\u0e2b\u0e23\u0e31\u0e1a\u0e40\u0e17\u0e23\u0e14\u0e40\u0e14\u0e2d\u0e23\u0e4c\u0e23\u0e30\u0e14\u0e31\u0e1a\u0e17\u0e47\u0e2d\u0e1b',
    price: 1000,
    unlockLevel: 5,
    previewAsset: 'assets/sprites/room_backgrounds/room_penthouse.png',
    backgroundAsset: 'room_penthouse.png',
    emoji: '\ud83c\udf06',
  ),

  // ── Wall Street Collection ──────────────────────────────────────────────────
  RoomTheme(
    themeId: 'wallstreet_bull',
    nameTh: 'Wall Street \u2014 Bull',
    nameEn: 'Wall Street Bull',
    descriptionTh: '\u0e15\u0e25\u0e32\u0e14\u0e01\u0e23\u0e30\u0e17\u0e34\u0e07! \u0e17\u0e38\u0e01\u0e15\u0e31\u0e27\u0e40\u0e25\u0e02\u0e40\u0e1b\u0e47\u0e19\u0e2a\u0e35\u0e40\u0e02\u0e35\u0e22\u0e27',
    price: 1500,
    unlockLevel: 7,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_bull.png',
    backgroundAsset: 'room_wallstreet_bull.png',
    emoji: '\ud83d\udcc8',
  ),
  RoomTheme(
    themeId: 'wallstreet_bear',
    nameTh: 'Wall Street \u2014 Bear',
    nameEn: 'Wall Street Bear',
    descriptionTh: '\u0e15\u0e25\u0e32\u0e14\u0e2b\u0e21\u0e35! \u0e1d\u0e36\u0e01\u0e2d\u0e22\u0e39\u0e48\u0e01\u0e31\u0e1a\u0e04\u0e27\u0e32\u0e21\u0e1c\u0e31\u0e19\u0e1c\u0e27\u0e19',
    price: 1500,
    unlockLevel: 7,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_bear.png',
    backgroundAsset: 'room_wallstreet_bear.png',
    emoji: '\ud83d\udcc9',
  ),
  RoomTheme(
    themeId: 'wallstreet_crypto',
    nameTh: 'Wall Street \u2014 Crypto',
    nameEn: 'Wall Street Crypto',
    descriptionTh: '\u0e2b\u0e49\u0e2d\u0e07\u0e40\u0e17\u0e23\u0e14\u0e04\u0e23\u0e34\u0e1b\u0e42\u0e15 \u0e40\u0e15\u0e47\u0e21\u0e44\u0e1b\u0e14\u0e49\u0e27\u0e22\u0e08\u0e2d\u0e41\u0e25\u0e30\u0e01\u0e23\u0e32\u0e1f',
    price: 2000,
    unlockLevel: 8,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_crypto.png',
    backgroundAsset: 'room_wallstreet_crypto.png',
    emoji: '\u20bf',
  ),
  RoomTheme(
    themeId: 'wallstreet_floor',
    nameTh: 'Wall Street \u2014 Trading Floor',
    nameEn: 'Wall Street Floor',
    descriptionTh: '\u0e1e\u0e37\u0e49\u0e19\u0e0b\u0e37\u0e49\u0e2d\u0e02\u0e32\u0e22\u0e2a\u0e38\u0e14\u0e04\u0e36\u0e01 \u0e2b\u0e19\u0e49\u0e32\u0e08\u0e2d\u0e40\u0e15\u0e47\u0e21\u0e1d\u0e32',
    price: 2000,
    unlockLevel: 8,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_floor.png',
    backgroundAsset: 'room_wallstreet_floor.png',
    emoji: '\ud83d\udcca',
  ),
  RoomTheme(
    themeId: 'wallstreet_hedge_fund',
    nameTh: 'Wall Street \u2014 Hedge Fund',
    nameEn: 'Wall Street Hedge Fund',
    descriptionTh: '\u0e2b\u0e49\u0e2d\u0e07\u0e17\u0e33\u0e07\u0e32\u0e19\u0e40\u0e2e\u0e14\u0e08\u0e4c\u0e1f\u0e31\u0e19\u0e14\u0e4c \u0e2b\u0e23\u0e39\u0e2b\u0e23\u0e32\u0e41\u0e25\u0e30\u0e21\u0e35\u0e2a\u0e44\u0e15\u0e25\u0e4c',
    price: 2500,
    unlockLevel: 10,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_hedge_fund.png',
    backgroundAsset: 'room_wallstreet_hedge_fund.png',
    emoji: '\ud83e\uddd1\u200d\ud83d\udcbc',
  ),
  RoomTheme(
    themeId: 'wallstreet_news',
    nameTh: 'Wall Street \u2014 News Room',
    nameEn: 'Wall Street News',
    descriptionTh: '\u0e2b\u0e49\u0e2d\u0e07\u0e02\u0e48\u0e32\u0e27\u0e01\u0e32\u0e23\u0e40\u0e07\u0e34\u0e19 \u0e15\u0e34\u0e14\u0e15\u0e32\u0e21\u0e15\u0e25\u0e32\u0e14\u0e41\u0e1a\u0e1a\u0e40\u0e23\u0e35\u0e22\u0e25\u0e44\u0e17\u0e21\u0e4c',
    price: 2500,
    unlockLevel: 10,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_news.png',
    backgroundAsset: 'room_wallstreet_news.png',
    emoji: '\ud83d\udcf0',
  ),
  RoomTheme(
    themeId: 'wallstreet_penthouse_nyc',
    nameTh: 'Wall Street \u2014 NYC Penthouse',
    nameEn: 'Wall Street NYC Penthouse',
    descriptionTh: '\u0e40\u0e1e\u0e19\u0e17\u0e4c\u0e40\u0e2e\u0e32\u0e2a\u0e4c\u0e19\u0e34\u0e27\u0e22\u0e2d\u0e23\u0e4c\u0e04 \u0e27\u0e34\u0e27\u0e41\u0e21\u0e19\u0e2e\u0e31\u0e15\u0e15\u0e31\u0e19\u0e22\u0e32\u0e21\u0e04\u0e48\u0e33\u0e04\u0e37\u0e19',
    price: 3000,
    unlockLevel: 12,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_penthouse_nyc.png',
    backgroundAsset: 'room_wallstreet_penthouse_nyc.png',
    emoji: '\ud83c\uddfa\ud83c\uddf8',
  ),
  RoomTheme(
    themeId: 'wallstreet_rooftop',
    nameTh: 'Wall Street \u2014 Rooftop',
    nameEn: 'Wall Street Rooftop',
    descriptionTh: '\u0e14\u0e32\u0e14\u0e1f\u0e49\u0e32\u0e40\u0e2b\u0e19\u0e37\u0e2d\u0e15\u0e36\u0e01\u0e23\u0e30\u0e1f\u0e49\u0e32\u0e01\u0e23\u0e32\u0e14\u0e04\u0e23\u0e36\u0e01\u0e44\u0e25\u0e19\u0e4c\u0e19\u0e34\u0e27\u0e22\u0e2d\u0e23\u0e4c\u0e04',
    price: 3000,
    unlockLevel: 12,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_rooftop.png',
    backgroundAsset: 'room_wallstreet_rooftop.png',
    emoji: '\ud83c\udf03',
  ),
  RoomTheme(
    themeId: 'wallstreet_vault',
    nameTh: 'Wall Street \u2014 Vault',
    nameEn: 'Wall Street Vault',
    descriptionTh: '\u0e2b\u0e49\u0e2d\u0e07\u0e19\u0e34\u0e23\u0e20\u0e31\u0e22\u0e2a\u0e39\u0e07\u0e2a\u0e38\u0e14 \u0e40\u0e01\u0e47\u0e1a\u0e17\u0e23\u0e31\u0e1e\u0e22\u0e4c\u0e2a\u0e34\u0e19\u0e44\u0e27\u0e49\u0e43\u0e19\u0e15\u0e39\u0e49\u0e40\u0e0b\u0e1f',
    price: 5000,
    unlockLevel: 15,
    previewAsset: 'assets/sprites/room_backgrounds/room_wallstreet_vault.png',
    backgroundAsset: 'room_wallstreet_vault.png',
    emoji: '\ud83c\udfe6',
  ),
];
