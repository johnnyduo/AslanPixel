import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:aslan_pixel/features/pixel_art/data/datasources/firestore_pixel_art_datasource.dart';
import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_art_editor_page.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_canvas_widget.dart';

/// Gallery that lists all pixel art canvases owned by the current user.
///
/// Uses [StreamBuilder] directly against [FirestorePixelArtDatasource]
/// with lazy-loading pagination via [NotificationListener].
class PixelArtGalleryPage extends StatelessWidget {
  const PixelArtGalleryPage({super.key});

  static const routeName = '/pixel-art-gallery';

  @override
  Widget build(BuildContext context) {
    return const _GalleryView();
  }
}

class _GalleryView extends StatefulWidget {
  const _GalleryView();

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView> {
  static const _pageSize = 20;

  final _datasource = FirestorePixelArtDatasource();
  late final String _uid;

  final List<PixelCanvasModel> _canvases = [];
  bool _loading = true;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (_uid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final first = await _datasource
          .watchMyCanvases(_uid)
          .first;
      if (!mounted) return;
      setState(() {
        _canvases.addAll(first.take(_pageSize));
        _hasMore = first.length > _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        !_loadingMore &&
        _hasMore &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      _loadMore();
    }
    return false;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final all = await _datasource.watchMyCanvases(_uid).first;
      if (!mounted) return;
      final newItems = all.skip(_canvases.length).take(_pageSize).toList();
      setState(() {
        _canvases.addAll(newItems);
        _hasMore = newItems.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _createAndOpen() async {
    if (_uid.isEmpty) return;
    final canvas = await _datasource.createCanvas(_uid, 32, 32);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PixelArtEditorPage(canvas: canvas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        tooltip: 'New 32x32 canvas',
        onPressed: _createAndOpen,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F5A0)),
            )
          : _canvases.isEmpty
              ? const Center(
                  child: Text(
                    'No canvases yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B8AAB), fontSize: 16),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _canvases.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _canvases.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Color(0xFF00F5A0),
                            ),
                          ),
                        );
                      }
                      return _CanvasThumbnailCard(canvas: _canvases[index]);
                    },
                  ),
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
