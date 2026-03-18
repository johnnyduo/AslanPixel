import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for a single pixel art canvas stored in Firestore.
///
/// Pixels are stored as a 2-D grid of ARGB integers.
/// Collection path: pixelCanvases/{canvasId}
class PixelCanvasModel {
  final String canvasId;
  final String ownerUid;
  final int width;
  final int height;

  /// 2-D grid [row][col] — each value is a 32-bit ARGB int.
  final List<List<int>> pixels;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Firebase Storage download URL, set after exportAndUpload.
  final String? storagePath;

  const PixelCanvasModel({
    required this.canvasId,
    required this.ownerUid,
    required this.width,
    required this.height,
    required this.pixels,
    required this.createdAt,
    required this.updatedAt,
    this.storagePath,
  });

  // ── Factory ────────────────────────────────────────────────────────────────

  factory PixelCanvasModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawPixels = data['pixels'] as List<dynamic>? ?? [];
    final pixels = rawPixels
        .map((row) => (row as List<dynamic>).map((v) => (v as int)).toList())
        .toList();

    return PixelCanvasModel(
      canvasId: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      width: data['width'] as int? ?? 32,
      height: data['height'] as int? ?? 32,
      pixels: pixels,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      storagePath: data['storagePath'] as String?,
    );
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'width': width,
        'height': height,
        'pixels': pixels,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'storagePath': storagePath,
      };

  // ── copyWith ───────────────────────────────────────────────────────────────

  PixelCanvasModel copyWith({
    String? canvasId,
    String? ownerUid,
    int? width,
    int? height,
    List<List<int>>? pixels,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? storagePath,
  }) =>
      PixelCanvasModel(
        canvasId: canvasId ?? this.canvasId,
        ownerUid: ownerUid ?? this.ownerUid,
        width: width ?? this.width,
        height: height ?? this.height,
        pixels: pixels ?? this.pixels,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        storagePath: storagePath ?? this.storagePath,
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Creates a new blank canvas where every pixel is navy (0xFF0A1628).
  static PixelCanvasModel blank(String ownerUid, int width, int height) {
    final now = DateTime.now();
    const navy = 0xFF0A1628;
    final pixels = List.generate(
      height,
      (_) => List.filled(width, navy),
    );
    return PixelCanvasModel(
      canvasId: _generateId(),
      ownerUid: ownerUid,
      width: width,
      height: height,
      pixels: pixels,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
