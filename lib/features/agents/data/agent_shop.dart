import 'package:aslan_pixel/core/enums/agent_type.dart';

/// Catalog of agents available for purchase in the shop.
class AgentShopItem {
  const AgentShopItem({
    required this.type,
    required this.nameTh,
    required this.nameEn,
    required this.descriptionTh,
    required this.price,
    required this.unlockLevel,
    required this.emoji,
  });
  final AgentType type;
  final String nameTh;
  final String nameEn;
  final String descriptionTh;
  final int price; // in coins
  final int unlockLevel; // minimum player level to buy
  final String emoji;
}

const List<AgentShopItem> kAgentShop = [
  AgentShopItem(
    type: AgentType.analyst,
    nameTh: '\u0e19\u0e31\u0e01\u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c',
    nameEn: 'Analyst',
    descriptionTh: '\u0e27\u0e34\u0e08\u0e31\u0e22\u0e15\u0e25\u0e32\u0e14 \u0e27\u0e34\u0e40\u0e04\u0e23\u0e32\u0e30\u0e2b\u0e4c\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25 \u0e2a\u0e23\u0e49\u0e32\u0e07 AI Insight',
    price: 0, // starter agent — free
    unlockLevel: 1,
    emoji: '\u{1f4ca}',
  ),
  AgentShopItem(
    type: AgentType.scout,
    nameTh: '\u0e19\u0e31\u0e01\u0e2a\u0e33\u0e23\u0e27\u0e08',
    nameEn: 'Scout',
    descriptionTh: '\u0e2a\u0e33\u0e23\u0e27\u0e08\u0e42\u0e2d\u0e01\u0e32\u0e2a\u0e25\u0e07\u0e17\u0e38\u0e19 \u0e40\u0e01\u0e47\u0e1a\u0e40\u0e2b\u0e23\u0e35\u0e22\u0e0d \u0e1b\u0e25\u0e14\u0e25\u0e47\u0e2d\u0e04\u0e44\u0e2d\u0e40\u0e17\u0e21',
    price: 200,
    unlockLevel: 2,
    emoji: '\u{1f52d}',
  ),
  AgentShopItem(
    type: AgentType.risk,
    nameTh: '\u0e1c\u0e39\u0e49\u0e1e\u0e34\u0e17\u0e31\u0e01\u0e29\u0e4c\u0e04\u0e27\u0e32\u0e21\u0e40\u0e2a\u0e35\u0e48\u0e22\u0e07',
    nameEn: 'Risk Guardian',
    descriptionTh: '\u0e40\u0e15\u0e37\u0e2d\u0e19\u0e04\u0e27\u0e32\u0e21\u0e40\u0e2a\u0e35\u0e48\u0e22\u0e07 \u0e08\u0e31\u0e14\u0e01\u0e32\u0e23\u0e1e\u0e2d\u0e23\u0e4c\u0e15\u0e43\u0e2b\u0e49\u0e1b\u0e25\u0e2d\u0e14\u0e20\u0e31\u0e22',
    price: 500,
    unlockLevel: 3,
    emoji: '\u{1f6e1}\ufe0f',
  ),
  AgentShopItem(
    type: AgentType.social,
    nameTh: '\u0e19\u0e31\u0e01\u0e2a\u0e31\u0e07\u0e04\u0e21',
    nameEn: 'Social Agent',
    descriptionTh: '\u0e2a\u0e41\u0e01\u0e19\u0e40\u0e17\u0e23\u0e19\u0e14\u0e4c\u0e42\u0e0b\u0e40\u0e0a\u0e35\u0e22\u0e25 \u0e41\u0e19\u0e30\u0e19\u0e33\u0e04\u0e19\u0e19\u0e48\u0e32\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21',
    price: 800,
    unlockLevel: 5,
    emoji: '\u{1f4ac}',
  ),
];
