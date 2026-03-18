import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:aslan_pixel/features/pixel_art/data/datasources/firestore_pixel_art_datasource.dart';
import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_art_editor_page.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_canvas_widget.dart';

/// Gallery that lists all pixel art canvases owned by the current user.
///
/// Uses [StreamBuilder] directly against [FirestorePixelArtDatasource].
class PixelArtGalleryPage extends StatelessWidget {
  const PixelArtGalleryPage({super.key});

  static const routeName = '/pixel-art-gallery';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final datasource = FirestorePixelArtDatasource();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: const Color(0xFFE8F4F8),
        title: const Text(
          'Pixel Art Gallery',
          style: TextStyle(color: Color(0xFFE8F4F8)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E3050)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00F5A0),
        foregroundColor: const Color(0xFF0A1628),
        tooltip: 'New 32×32 canvas',
        onPressed: () => _createAndOpen(context, datasource, uid),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<PixelCanvasModel>>(
        stream: datasource.watchMyCanvases(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFFFF4D4F)),
              ),
            );
          }

          final canvases = snapshot.data ?? [];
          if (canvases.isEmpty) {
            return const Center(
              child: Text(
                'No canvases yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B8AAB), fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: canvases.length,
            itemBuilder: (context, index) {
              final canvas = canvases[index];
              return _CanvasThumbnailCard(canvas: canvas);
            },
          );
        },
      ),
    );
  }

  Future<void> _createAndOpen(
    BuildContext context,
    FirestorePixelArtDatasource datasource,
    String uid,
  ) async {
    if (uid.isEmpty) return;
    final canvas = await datasource.createCanvas(uid, 32, 32);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PixelArtEditorPage(canvas: canvas),
      ),
    );
  }
}

class _CanvasThumbnailCard extends StatelessWidget {
  const _CanvasThumbnailCard({required this.canvas});

  final PixelCanvasModel canvas;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PixelArtEditorPage(canvas: canvas),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F2040),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E3050)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: PixelCanvasWidget(
                  pixels: canvas.pixels,
                  cellSize: 2,
                  onPixelTap: (_, __) {},
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                '${canvas.width}×${canvas.height}',
                style: const TextStyle(
                  color: Color(0xFF6B8AAB),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
