import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/pixel_art/data/repositories/pixel_art_repository.dart';

/// Firestore + Firebase Storage implementation of [PixelArtRepository].
///
/// Collection: pixelCanvases/{canvasId}
/// Storage:    pixel_art/{ownerUid}/{canvasId}.png
class FirestorePixelArtDatasource implements PixelArtRepository {
  FirestorePixelArtDatasource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pixelCanvases');

  // ── PixelArtRepository ─────────────────────────────────────────────────────

  @override
  Future<PixelCanvasModel> createCanvas(
    String ownerUid,
    int width,
    int height,
  ) async {
    final canvas = PixelCanvasModel.blank(ownerUid, width, height);
    await _col.doc(canvas.canvasId).set(canvas.toMap());
    return canvas;
  }

  @override
  Future<void> saveCanvas(PixelCanvasModel canvas) async {
    await _col.doc(canvas.canvasId).update({
      'pixels': canvas.pixels,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<List<PixelCanvasModel>> watchMyCanvases(String ownerUid) {
    return _col
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(PixelCanvasModel.fromFirestore).toList());
  }

  @override
  Future<String?> exportAndUpload(PixelCanvasModel canvas) async {
    try {
      final pngBytes = _encodePng(canvas);

      final ref = _storage
          .ref()
          .child('pixel_art/${canvas.ownerUid}/${canvas.canvasId}.png');

      final task = await ref.putData(
        pngBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final url = await task.ref.getDownloadURL();

      // Persist storage path back to Firestore.
      await _col.doc(canvas.canvasId).update({'storagePath': url});

      return url;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteCanvas(String ownerUid, String canvasId) async {
    // Delete the Firestore document.
    await _col.doc(canvasId).delete();

    // Attempt to delete the Storage file (ignore if it doesn't exist).
    try {
      final ref = _storage
          .ref()
          .child('pixel_art/$ownerUid/$canvasId.png');
      await ref.delete();
    } catch (_) {
      // Storage file may not exist if the canvas was never exported.
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Uint8List _encodePng(PixelCanvasModel canvas) {
    final image = img.Image(width: canvas.width, height: canvas.height);

    for (int row = 0; row < canvas.height; row++) {
      for (int col = 0; col < canvas.width; col++) {
        final argb = canvas.pixels[row][col];
        final a = (argb >> 24) & 0xFF;
        final r = (argb >> 16) & 0xFF;
        final g = (argb >> 8) & 0xFF;
        final b = argb & 0xFF;
        image.setPixel(col, row, img.ColorRgba8(r, g, b, a));
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }
}
