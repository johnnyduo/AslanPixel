import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';

// ── Color constants ──────────────────────────────────────────────────────────
const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _textSecondary = Color(0xFFA8C4E0);

// ── Item catalogue ───────────────────────────────────────────────────────────

class _CatalogueItem {
  const _CatalogueItem({
    required this.itemId,
    required this.type,
    required this.emoji,
    required this.nameTh,
  });

  final String itemId;
  final RoomItemType type;
  final String emoji;
  final String nameTh;
}

const List<_CatalogueItem> _catalogue = [
  _CatalogueItem(
    itemId: 'desk_01',
    type: RoomItemType.furniture,
    emoji: '🖥️',
    nameTh: 'โต๊ะ 01',
  ),
  _CatalogueItem(
    itemId: 'desk_02',
    type: RoomItemType.furniture,
    emoji: '💻',
    nameTh: 'โต๊ะ 02',
  ),
  _CatalogueItem(
    itemId: 'desk_03',
    type: RoomItemType.furniture,
    emoji: '🖱️',
    nameTh: 'โต๊ะ 03',
  ),
  _CatalogueItem(
    itemId: 'plant_01',
    type: RoomItemType.plant,
    emoji: '🌿',
    nameTh: 'ต้นไม้ 01',
  ),
  _CatalogueItem(
    itemId: 'plant_02',
    type: RoomItemType.plant,
    emoji: '🌱',
    nameTh: 'ต้นไม้ 02',
  ),
  _CatalogueItem(
    itemId: 'plant_03',
    type: RoomItemType.plant,
    emoji: '🪴',
    nameTh: 'ต้นไม้ 03',
  ),
  _CatalogueItem(
    itemId: 'chest_01',
    type: RoomItemType.chest,
    emoji: '📦',
    nameTh: 'หีบ 01',
  ),
  _CatalogueItem(
    itemId: 'rug_01',
    type: RoomItemType.floor,
    emoji: '🟫',
    nameTh: 'พรม',
  ),
  _CatalogueItem(
    itemId: 'bookshelf_01',
    type: RoomItemType.furniture,
    emoji: '📚',
    nameTh: 'ชั้นหนังสือ',
  ),
  _CatalogueItem(
    itemId: 'lamp_01',
    type: RoomItemType.decoration,
    emoji: '💡',
    nameTh: 'โคมไฟ',
  ),
];

// ── RoomItemPicker ────────────────────────────────────────────────────────────

/// Bottom sheet that lets the user pick an item to place in their pixel room.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => RoomItemPicker(uid: uid, bloc: roomBloc),
/// );
/// ```
class RoomItemPicker extends StatelessWidget {
  const RoomItemPicker({
    super.key,
    required this.uid,
    required this.bloc,
  });

  final String uid;
  final RoomBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: _RoomItemPickerSheet(uid: uid),
    );
  }
}

class _RoomItemPickerSheet extends StatelessWidget {
  const _RoomItemPickerSheet({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Text(
            'เลือกไอเทม',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: _catalogue.length,
            itemBuilder: (context, index) {
              final item = _catalogue[index];
              return _ItemCard(
                catalogueItem: item,
                onTap: () {
                  context.read<RoomBloc>().add(
                        RoomItemPlaced(
                          uid: uid,
                          item: RoomItem(
                            itemId: item.itemId,
                            type: item.type,
                            assetKey: item.itemId,
                            slotX: 0,
                            slotY: 0,
                            isUnlocked: true,
                          ),
                        ),
                      );
                  Navigator.of(context).pop();
                },
              );
            },
          ),
          const SizedBox(height: 16),
          // Close button
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _neonGreen,
              side: const BorderSide(color: _neonGreen, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'ปิด',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── _ItemCard ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.catalogueItem,
    required this.onTap,
  });

  final _CatalogueItem catalogueItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _neonGreen.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              catalogueItem.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 6),
            Text(
              catalogueItem.nameTh,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textWhite,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
