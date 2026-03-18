import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/pixel_art/bloc/pixel_art_bloc.dart';
import 'package:aslan_pixel/features/pixel_art/data/datasources/firestore_pixel_art_datasource.dart';
import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_art_toolbar.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_canvas_widget.dart';

/// Full-screen pixel art editor.
///
/// Provide a [PixelCanvasModel] to open an existing canvas.
/// Use [PixelCanvasModel.blank] for a new canvas.
class PixelArtEditorPage extends StatefulWidget {
  const PixelArtEditorPage({super.key, required this.canvas});

  static const routeName = '/pixel-art-editor';

  final PixelCanvasModel canvas;

  @override
  State<PixelArtEditorPage> createState() => _PixelArtEditorPageState();
}

class _PixelArtEditorPageState extends State<PixelArtEditorPage> {
  late final PixelArtBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = PixelArtBloc(repository: FirestorePixelArtDatasource());
    _bloc.add(PixelArtCanvasLoaded(widget.canvas));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PixelArtBloc>.value(
      value: _bloc,
      child: const _PixelArtEditorView(),
    );
  }
}

class _PixelArtEditorView extends StatelessWidget {
  const _PixelArtEditorView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PixelArtBloc, PixelArtState>(
      listener: _onStateChange,
      builder: (context, state) {
        final bloc = context.read<PixelArtBloc>();
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1628),
            foregroundColor: const Color(0xFFE8F4F8),
            title: Text(
              state is PixelArtEditing
                  ? 'Canvas ${state.canvas.canvasId.substring(0, 8)}…'
                  : 'Pixel Editor',
              style: const TextStyle(
                color: Color(0xFFE8F4F8),
                fontSize: 16,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFF1E3050)),
            ),
          ),
          body: Column(
            children: [
              // ── Toolbar ──────────────────────────────────────────────────
              PixelArtToolbar(state: state, bloc: bloc),

              // ── Canvas ───────────────────────────────────────────────────
              Expanded(
                child: state is PixelArtEditing
                    ? _buildCanvas(context, state, bloc)
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00F5A0),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanvas(
    BuildContext context,
    PixelArtEditing state,
    PixelArtBloc bloc,
  ) {
    return Center(
      child: PixelCanvasWidget(
        pixels: state.canvas.pixels,
        cellSize: 12,
        onPixelTap: (row, col) {
          bloc.add(PixelArtPixelPainted(
            row: row,
            col: col,
            color: state.selectedColor,
          ));
        },
      ),
    );
  }

  void _onStateChange(BuildContext context, PixelArtState state) {
    if (state is PixelArtSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved!'),
          backgroundColor: Color(0xFF00F5A0),
        ),
      );
    } else if (state is PixelArtExported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported: ${state.url}'),
          backgroundColor: Color(0xFF7B2FFF),
        ),
      );
    } else if (state is PixelArtError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFFFF4D4F),
        ),
      );
    }
  }
}
