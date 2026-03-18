import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/feed/view/feed_page.dart';
import 'package:aslan_pixel/features/finance/view/finance_page.dart';
import 'package:aslan_pixel/features/home/view/leaderboard_page.dart';
import 'package:aslan_pixel/features/inventory/view/inventory_page.dart';
import 'package:aslan_pixel/features/quests/view/quest_page.dart';
import 'package:aslan_pixel/features/world/bloc/plaza_bloc.dart';
import 'package:aslan_pixel/features/world/data/datasources/firestore_plaza_datasource.dart';
import 'package:aslan_pixel/features/world/data/models/plaza_presence_model.dart';

// ── Colour constants ──────────────────────────────────────────────────────────
const Color _navy = Color(0xFF0A1628);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _purple = Color(0xFF7B2FFF);
const Color _cyan = Color(0xFF00D9FF);
const Color _gold = Color(0xFFF5C518);
const Color _textWhite = Color(0xFFE8F4F8);

// ── Building model ────────────────────────────────────────────────────────────

/// Describes a clickable building on the Plaza map.
class _PlazaBuilding {
  const _PlazaBuilding({
    required this.name,
    required this.nameTh,
    required this.description,
    required this.rect,
    required this.routeName,
    required this.color,
    required this.icon,
  });

  /// Display name (English) shown in bottom sheet title.
  final String name;

  /// Thai name used as label on the map.
  final String nameTh;

  /// Short Thai description for the bottom sheet.
  final String description;

  /// Normalised rect in [0, 1] space — converted to pixels at paint time.
  final Rect rect;

  final String routeName;
  final Color color;
  final IconData icon;

  /// Convert this building's normalised rect to canvas pixels.
  Rect pixelRect(double w, double h) => Rect.fromLTWH(
        rect.left * w,
        rect.top * h,
        rect.width * w,
        rect.height * h,
      );

  /// True when [local] (canvas-space tap position) hits this building.
  bool contains(Offset local, double w, double h) =>
      pixelRect(w, h).contains(local);
}

// ── Building registry ─────────────────────────────────────────────────────────

const List<_PlazaBuilding> _buildings = [
  _PlazaBuilding(
    name: 'Market',
    nameTh: 'ตลาด',
    description: 'ดูข้อมูลการเงิน การทำนายตลาด และ AI Insights',
    rect: Rect.fromLTWH(0.08, 0.12, 0.22, 0.18),
    routeName: FinancePage.routeName,
    color: _purple,
    icon: Icons.candlestick_chart_outlined,
  ),
  _PlazaBuilding(
    name: 'Arena',
    nameTh: 'อารีนา',
    description: 'ดูอันดับนักลงทุนและแชมป์เปี้ยนของสัปดาห์',
    rect: Rect.fromLTWH(0.65, 0.10, 0.25, 0.20),
    routeName: LeaderboardPage.routeName,
    color: _cyan,
    icon: Icons.emoji_events_outlined,
  ),
  _PlazaBuilding(
    name: 'Bank',
    nameTh: 'ธนาคาร',
    description: 'จัดการเหรียญ คลัง และสินทรัพย์ดิจิทัลของคุณ',
    rect: Rect.fromLTWH(0.35, 0.68, 0.28, 0.16),
    routeName: InventoryPage.routeName,
    color: _gold,
    icon: Icons.account_balance_outlined,
  ),
  _PlazaBuilding(
    name: 'Social Hub',
    nameTh: 'โซเชียล',
    description: 'แชร์ความคิด ติดตามนักลงทุน และดูฟีดสังคม',
    rect: Rect.fromLTWH(0.05, 0.58, 0.24, 0.16),
    routeName: FeedPage.routeName,
    color: _neonGreen,
    icon: Icons.people_outline,
  ),
  _PlazaBuilding(
    name: 'Quest Board',
    nameTh: 'กระดานภารกิจ',
    description: 'รับภารกิจประจำวันและสะสม XP เพื่ออัพเลเวล',
    rect: Rect.fromLTWH(0.68, 0.62, 0.24, 0.18),
    routeName: QuestPage.routeName,
    color: Color(0xFFFF9F43),
    icon: Icons.assignment_outlined,
  ),
];

// ── Page ──────────────────────────────────────────────────────────────────────

/// Public Plaza page — a lightweight 2-D top-down view of online users.
///
/// Uses [CustomPaint] (no game engine) — suitable for the plaza's lighter
/// feature scope compared with the private pixel room.
class PlazaPage extends StatefulWidget {
  const PlazaPage({super.key});

  static const String routeName = '/plaza';

  @override
  State<PlazaPage> createState() => _PlazaPageState();
}

class _PlazaPageState extends State<PlazaPage> {
  // Simulated UID until auth is wired through to this page.
  static const String _demoUid = 'demo_user';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlazaBloc>(
      create: (_) => PlazaBloc(FirestorePlazaDatasource())
        ..add(const PlazaWatchStarted(uid: _demoUid, x: 0.5, y: 0.5)),
      child: const _PlazaView(),
    );
  }
}

// ── Internal stateful view ────────────────────────────────────────────────────

class _PlazaView extends StatefulWidget {
  const _PlazaView();

  @override
  State<_PlazaView> createState() => _PlazaViewState();
}

class _PlazaViewState extends State<_PlazaView> {
  /// The building that was most recently tapped (for highlight effect).
  _PlazaBuilding? _tappedBuilding;

  void _handleTapDown(TapDownDetails details, List<PlazaPresenceModel> presences) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = details.localPosition;
    final w = box.size.width;
    final h = box.size.height;

    // Update player position via BLoC.
    final nx = (local.dx / w).clamp(0.0, 1.0);
    final ny = (local.dy / h).clamp(0.0, 1.0);
    context.read<PlazaBloc>().add(PlazaPositionUpdated(x: nx, y: ny));

    // Check building hits.
    for (final building in _buildings) {
      if (building.contains(local, w, h)) {
        setState(() => _tappedBuilding = building);

        // Reset highlight after 500 ms.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _tappedBuilding = null);
        });

        _showBuildingSheet(building);
        return;
      }
    }
  }

  void _showBuildingSheet(_PlazaBuilding building) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F2040),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _BuildingSheet(
        building: building,
        onEnter: () {
          Navigator.of(sheetCtx).pop();
          // Leaderboard requires a uid argument — use the demo uid.
          final args = building.routeName == LeaderboardPage.routeName
              ? 'demo_user'
              : null;
          Navigator.of(context).pushNamed(building.routeName, arguments: args);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: BlocBuilder<PlazaBloc, PlazaState>(
        builder: (context, state) {
          final presences =
              state is PlazaLoaded ? state.presences : <PlazaPresenceModel>[];
          final onlineCount = presences.length;

          return Stack(
            children: [
              // ── Plaza map ────────────────────────────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) => _handleTapDown(details, presences),
                  child: CustomPaint(
                    painter: _PlazaMapPainter(
                      presences: presences,
                      tappedBuilding: _tappedBuilding,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // ── Top overlay: title + online count ────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    const Text(
                      'Plaza',
                      style: TextStyle(
                        color: _textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _OnlineChip(count: onlineCount),
                  ],
                ),
              ),

              // ── Loading indicator ─────────────────────────────────────────
              if (state is PlazaLoading)
                const Center(
                  child: CircularProgressIndicator(color: _neonGreen),
                ),

              // ── Error overlay ─────────────────────────────────────────────
              if (state is PlazaError)
                Center(
                  child: Text(
                    (state).msg,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Building bottom sheet ─────────────────────────────────────────────────────

class _BuildingSheet extends StatelessWidget {
  const _BuildingSheet({
    required this.building,
    required this.onEnter,
  });

  final _PlazaBuilding building;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textWhite.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Building icon + name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: building.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: building.color.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Icon(building.icon, color: building.color, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    building.nameTh,
                    style: TextStyle(
                      color: building.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    building.name,
                    style: TextStyle(
                      color: _textWhite.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            building.description,
            style: TextStyle(
              color: _textWhite.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: building.color,
                foregroundColor: _navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onEnter,
              child: const Text(
                'เข้าไป →',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Online chip ───────────────────────────────────────────────────────────────

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _neonGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _neonGreen, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: _neonGreen),
          const SizedBox(width: 6),
          Text(
            '$count online',
            style: const TextStyle(
              color: _neonGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CustomPainter ─────────────────────────────────────────────────────────────

/// [CustomPainter] that renders the top-down plaza map.
///
/// Draws:
///   • Navy background + subtle grid
///   • Building rectangles with coloured borders, fills, and white labels
///   • Gold highlight rect around the [tappedBuilding] (if set)
///   • One 8 px dot per online user, with their initial letter
class _PlazaMapPainter extends CustomPainter {
  const _PlazaMapPainter({
    required this.presences,
    this.tappedBuilding,
  });

  final List<PlazaPresenceModel> presences;
  final _PlazaBuilding? tappedBuilding;

  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0A1628);
  static const Color _grid = Color(0xFF1A2F50);
  static const Color _neonGreen = Color(0xFF00F5A0);
  static const Color _gold = Color(0xFFF5C518);
  static const Color _labelColor = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _bg,
    );

    // Grid lines
    _drawGrid(canvas, size);

    // Buildings (fill + border + label)
    for (final b in _buildings) {
      _drawBuilding(canvas, b, w, h, highlighted: b == tappedBuilding);
    }

    // Player dots (rendered on top)
    for (final p in presences) {
      _drawPlayer(canvas, p, w, h);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _grid
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawBuilding(
    Canvas canvas,
    _PlazaBuilding building,
    double w,
    double h, {
    required bool highlighted,
  }) {
    final rect = building.pixelRect(w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Fill
    canvas.drawRRect(
      rrect,
      Paint()..color = building.color.withValues(alpha: 0.18),
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = building.color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Gold highlight when tapped
    if (highlighted) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(3),
          const Radius.circular(9),
        ),
        Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // White centred label (8 px, bold)
    final tp = TextPainter(
      text: TextSpan(
        text: building.nameTh,
        style: const TextStyle(
          color: _labelColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
  }

  void _drawPlayer(
    Canvas canvas,
    PlazaPresenceModel presence,
    double w,
    double h,
  ) {
    final cx = presence.x * w;
    final cy = presence.y * h;
    const radius = 8.0;

    // Glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      radius + 3,
      Paint()..color = _neonGreen.withValues(alpha: 0.2),
    );

    // Filled dot
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()..color = _neonGreen,
    );

    // Initial letter
    final initial = _initialFor(presence);
    final tp = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          color: _bg,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );
  }

  String _initialFor(PlazaPresenceModel p) {
    if (p.displayName?.isNotEmpty == true) {
      return p.displayName![0].toUpperCase();
    }
    if (p.avatarId?.isNotEmpty == true) {
      return p.avatarId![0].toUpperCase();
    }
    return p.uid.isNotEmpty ? p.uid[0].toUpperCase() : '?';
  }

  @override
  bool shouldRepaint(_PlazaMapPainter oldDelegate) =>
      oldDelegate.presences != presences ||
      oldDelegate.tappedBuilding != tappedBuilding;
}
