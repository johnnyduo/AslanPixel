import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';

/// Abstract contract for pixel art persistence and export.
abstract class PixelArtRepository {
  /// Creates a new blank canvas in Firestore and returns the saved model.
  Future<PixelCanvasModel> createCanvas(
    String ownerUid,
    int width,
    int height,
  );

  /// Persists updated pixel data and timestamps to Firestore.
  Future<void> saveCanvas(PixelCanvasModel canvas);

  /// Emits the live list of canvases owned by [ownerUid].
  Stream<List<PixelCanvasModel>> watchMyCanvases(String ownerUid);

  /// Renders the canvas as a PNG, uploads to Firebase Storage,
  /// and returns the public download URL (or null on failure).
  Future<String?> exportAndUpload(PixelCanvasModel canvas);

  /// Deletes the canvas document from Firestore and its PNG from Storage.
  Future<void> deleteCanvas(String ownerUid, String canvasId);
}
