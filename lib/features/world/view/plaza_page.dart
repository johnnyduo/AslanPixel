import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/world/bloc/plaza_bloc.dart';
import 'package:aslan_pixel/features/world/data/datasources/firestore_plaza_datasource.dart';
import 'package:aslan_pixel/features/world/data/models/plaza_presence_model.dart';

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

class _PlazaView extends StatelessWidget {
  const _PlazaView();

  static const Color _navy = Color(0xFF0A1628);
  static const Color _neonGreen = Color(0xFF00F5A0);
  static const Color _textWhite = Color(0xFFE8F4F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: BlocBuilder<PlazaBloc, PlazaState>(
        builder: (context, state) {
          final presences = state is PlazaLoaded ? state.presences : <PlazaPresenceModel>[];
          final onlineCount = presences.length;

          return Stack(
            children: [
              // ── Plaza map ────────────────────────────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final local = details.localPosition;
                    final nx = (local.dx / box.size.width).clamp(0.0, 1.0);
                    final ny = (local.dy / box.size.height).clamp(0.0, 1.0);
                    context
                        .read<PlazaBloc>()
                        .add(PlazaPositionUpdated(x: nx, y: ny));
                  },
                  child: CustomPaint(
                    painter: PlazaMapPainter(presences: presences),
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

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00F5A0), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF00F5A0)),
          const SizedBox(width: 6),
          Text(
            '$count online',
            style: const TextStyle(
              color: Color(0xFF00F5A0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// [CustomPainter] that renders the top-down plaza map.
///
/// Draws:
///   • Navy background
///   • Subtle grid lines
///   • 3 building rectangles (purple / teal / gold)
///   • One 8 px dot per online user, with their initial letter
class PlazaMapPainter extends CustomPainter {
  const PlazaMapPainter({required this.presences});

  final List<PlazaPresenceModel> presences;

  // ── Colours ──────────────────────────────────────────────────────────────
  static const Color _navy = Color(0xFF0A1628);
  static const Color _grid = Color(0xFF1A2F50);
  static const Color _neonGreen = Color(0xFF00F5A0);
  static const Color _purple = Color(0xFF7B2FFF);
  static const Color _cyan = Color(0xFF00D9FF);
  static const Color _gold = Color(0xFFF5C518);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _navy,
    );

    // Grid lines
    _drawGrid(canvas, size);

    // Buildings
    _drawBuildings(canvas, w, h);

    // Player dots
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

  void _drawBuildings(Canvas canvas, double w, double h) {
    // Building 1 — purple (top-left quadrant)
    _drawBuilding(
      canvas,
      rect: Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.22, h * 0.18),
      color: _purple,
      label: 'Market',
    );

    // Building 2 — teal/cyan (top-right quadrant)
    _drawBuilding(
      canvas,
      rect: Rect.fromLTWH(w * 0.65, h * 0.10, w * 0.25, h * 0.20),
      color: _cyan,
      label: 'Arena',
    );

    // Building 3 — gold (bottom-centre)
    _drawBuilding(
      canvas,
      rect: Rect.fromLTWH(w * 0.35, h * 0.68, w * 0.28, h * 0.16),
      color: _gold,
      label: 'Bank',
    );
  }

  void _drawBuilding(
    Canvas canvas, {
    required Rect rect,
    required Color color,
    required String label,
  }) {
    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = color.withValues(alpha: 0.18),
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
          color: _navy,
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
  bool shouldRepaint(PlazaMapPainter oldDelegate) =>
      oldDelegate.presences != presences;
}
