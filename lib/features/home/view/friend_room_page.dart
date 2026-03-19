import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/home/bloc/room_state.dart';
import 'package:aslan_pixel/features/home/data/datasources/firestore_room_datasource.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------
const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _textDim = Color(0x80E8F4F8);

// ---------------------------------------------------------------------------
// FriendRoomPage
// ---------------------------------------------------------------------------

/// Read-only view of a friend's pixel room.
class FriendRoomPage extends StatelessWidget {
  const FriendRoomPage({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  static const String routeName = '/friend-room';

  final String friendUid;
  final String friendName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoomBloc(repository: FirestoreRoomDatasource())
        ..add(FriendRoomVisitRequested(friendUid)),
      child: _FriendRoomView(friendName: friendName),
    );
  }
}

class _FriendRoomView extends StatelessWidget {
  const _FriendRoomView({required this.friendName});

  final String friendName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textWhite,
        title: Text(
          'ห้องของ $friendName',
          style: const TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          if (state is RoomLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _neonGreen),
            );
          }

          if (state is RoomError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  style: const TextStyle(color: _textDim),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is FriendRoomLoaded) {
            if (state.items.isEmpty) {
              return const Center(
                child: Text(
                  'ห้องยังว่างอยู่',
                  style: TextStyle(color: _textDim, fontSize: 16),
                ),
              );
            }
            return _RoomGrid(items: state.items);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RoomGrid — read-only 8x8 grid showing room items
// ---------------------------------------------------------------------------

class _RoomGrid extends StatelessWidget {
  const _RoomGrid({required this.items});

  final List<RoomItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _neonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: CustomPaint(
            painter: _RoomGridPainter(items: items),
          ),
        ),
      ),
    );
  }
}

class _RoomGridPainter extends CustomPainter {
  _RoomGridPainter({required this.items});

  final List<RoomItem> items;

  static const int _gridSize = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / _gridSize;
    final cellH = size.height / _gridSize;

    // Draw grid lines.
    final gridPaint = Paint()
      ..color = _neonGreen.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var i = 0; i <= _gridSize; i++) {
      final dx = i * cellW;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      final dy = i * cellH;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // Draw items.
    for (final item in items) {
      if (!item.isUnlocked) continue;

      final rect = Rect.fromLTWH(
        item.slotX * cellW + 4,
        item.slotY * cellH + 4,
        cellW - 8,
        cellH - 8,
      );

      final itemPaint = Paint()..color = _colorForType(item.type);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        itemPaint,
      );

      // Draw item label.
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.assetKey.split('_').first,
          style: const TextStyle(color: _textWhite, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cellW - 8);

      textPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - textPainter.width) / 2,
          rect.top + (rect.height - textPainter.height) / 2,
        ),
      );
    }
  }

  Color _colorForType(RoomItemType type) {
    switch (type) {
      case RoomItemType.furniture:
        return const Color(0xFF1A3A5C);
      case RoomItemType.plant:
        return const Color(0xFF0D4030);
      case RoomItemType.chest:
        return const Color(0xFF4A3000);
      case RoomItemType.decoration:
        return const Color(0xFF2A1050);
      case RoomItemType.floor:
        return const Color(0xFF1A1A2E);
    }
  }

  @override
  bool shouldRepaint(covariant _RoomGridPainter oldDelegate) =>
      oldDelegate.items != items;
}
