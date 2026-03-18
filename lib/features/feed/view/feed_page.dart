import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/feed/bloc/feed_bloc.dart';
import 'package:aslan_pixel/features/feed/data/datasources/firestore_feed_datasource.dart';
import 'package:aslan_pixel/features/feed/view/feed_post_card.dart';

// ── Colour constants ──────────────────────────────────────────────────────────
const Color _navy = Color(0xFF0A1628);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _surface = Color(0xFF0F2040);

/// Social feed page — Phase 3.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  static const String routeName = '/feed';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeedBloc>(
      create: (ctx) =>
          FeedBloc(FirestoreFeedDatasource())..add(const FeedWatchStarted()),
      child: const _FeedView(),
    );
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Text(
          'Social Feed',
          style: TextStyle(
            color: _textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading || state is FeedInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _neonGreen),
            );
          }
          if (state is FeedError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (state is FeedLoaded) {
            if (state.posts.isEmpty) {
              return const Center(
                child: Text(
                  'ยังไม่มีโพสต์ เป็นคนแรกที่โพสต์!',
                  style: TextStyle(color: _textWhite, fontSize: 14),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: state.posts.length,
              itemBuilder: (ctx, index) =>
                  FeedPostCard(post: state.posts[index]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _neonGreen,
        foregroundColor: _navy,
        onPressed: () => _showPostComposer(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPostComposer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _PostComposerSheet(
        onPost: (content, contentTh) {
          context.read<FeedBloc>().add(
                FeedPostCreated(
                  authorUid: 'anonymous',
                  content: content,
                  contentTh: contentTh.isEmpty ? null : contentTh,
                ),
              );
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }
}

class _PostComposerSheet extends StatefulWidget {
  const _PostComposerSheet({required this.onPost});

  final void Function(String content, String contentTh) onPost;

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  final _contentController = TextEditingController();
  final _contentThController = TextEditingController();
  @override
  void dispose() {
    _contentController.dispose();
    _contentThController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สร้างโพสต์ใหม่',
            style: TextStyle(
              color: _textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _darkTextField(
            controller: _contentController,
            hint: 'เนื้อหา (English)',
          ),
          const SizedBox(height: 12),
          _darkTextField(
            controller: _contentThController,
            hint: 'เนื้อหา (ภาษาไทย) — ไม่บังคับ',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonGreen,
                foregroundColor: _navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final content = _contentController.text.trim();
                if (content.isEmpty) return;
                widget.onPost(content, _contentThController.text.trim());
              },
              child: const Text(
                'โพสต์',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(color: _textWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textWhite.withValues(alpha: 0.4)),
        filled: true,
        fillColor: const Color(0xFF0A1628),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A2F50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A2F50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _neonGreen, width: 1.5),
        ),
      ),
    );
  }
}
