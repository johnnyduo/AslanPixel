import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/pixel_art/data/repositories/pixel_art_repository.dart';

part 'pixel_art_event.dart';
part 'pixel_art_state.dart';

/// Maximum number of undo steps retained in memory.
const _kMaxUndoDepth = 20;

/// Default drawing colour — neon green.
const _kDefaultColor = 0xFF00F5A0;

/// Navy background — used as the "eraser" colour.
const _kNavy = 0xFF0A1628;

/// BLoC for the pixel art editor.
///
/// Handles painting, tool switching, undo, save, and export.
class PixelArtBloc extends Bloc<PixelArtEvent, PixelArtState> {
  PixelArtBloc({required PixelArtRepository repository})
      : _repository = repository,
        super(const PixelArtInitial()) {
    on<PixelArtCanvasLoaded>(_onCanvasLoaded);
    on<PixelArtPixelPainted>(_onPixelPainted);
    on<PixelArtColorSelected>(_onColorSelected);
    on<PixelArtToolChanged>(_onToolChanged);
    on<PixelArtCanvasSaved>(_onCanvasSaved);
    on<PixelArtCanvasExported>(_onCanvasExported);
    on<PixelArtUndoRequested>(_onUndoRequested);
    on<PixelArtCanvasSizeChanged>(_onCanvasSizeChanged);
  }

  final PixelArtRepository _repository;

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _onCanvasLoaded(
    PixelArtCanvasLoaded event,
    Emitter<PixelArtState> emit,
  ) {
    emit(PixelArtEditing(
      canvas: event.canvas,
      selectedColor: _kDefaultColor,
      tool: PixelArtTool.pencil,
      undoStack: const [],
    ));
  }

  void _onPixelPainted(
    PixelArtPixelPainted event,
    Emitter<PixelArtState> emit,
  ) {
    final editing = state as PixelArtEditing;
    final canvas = editing.canvas;

    // Bounds check.
    if (event.row < 0 ||
        event.row >= canvas.height ||
        event.col < 0 ||
        event.col >= canvas.width) {
      return;
    }

    // Deep-copy current grid for undo before mutating.
    final prevGrid = _deepCopyGrid(canvas.pixels);

    // Apply tool.
    final newGrid = _deepCopyGrid(canvas.pixels);
    switch (editing.tool) {
      case PixelArtTool.pencil:
        newGrid[event.row][event.col] = editing.selectedColor;
      case PixelArtTool.eraser:
        newGrid[event.row][event.col] = _kNavy;
      case PixelArtTool.fill:
        _floodFill(
          newGrid,
          event.row,
          event.col,
          canvas.pixels[event.row][event.col],
          editing.selectedColor,
          canvas.width,
          canvas.height,
        );
    }

    // Append to undo stack (cap at max depth).
    final newStack = [...editing.undoStack, prevGrid];
    if (newStack.length > _kMaxUndoDepth) {
      newStack.removeAt(0);
    }

    emit(editing.copyWith(
      canvas: canvas.copyWith(
        pixels: newGrid,
        updatedAt: DateTime.now(),
      ),
      undoStack: newStack,
    ));
  }

  void _onColorSelected(
    PixelArtColorSelected event,
    Emitter<PixelArtState> emit,
  ) {
    if (state is PixelArtEditing) {
      emit((state as PixelArtEditing).copyWith(selectedColor: event.color));
    }
  }

  void _onToolChanged(
    PixelArtToolChanged event,
    Emitter<PixelArtState> emit,
  ) {
    if (state is PixelArtEditing) {
      emit((state as PixelArtEditing).copyWith(tool: event.tool));
    }
  }

  Future<void> _onCanvasSaved(
    PixelArtCanvasSaved event,
    Emitter<PixelArtState> emit,
  ) async {
    if (state is! PixelArtEditing) return;
    final editing = state as PixelArtEditing;
    emit(editing.copyWith(isSaving: true));
    try {
      await _repository.saveCanvas(editing.canvas);
      emit(const PixelArtSaved());
      emit(editing.copyWith(isSaving: false));
    } catch (e) {
      emit(PixelArtError(e.toString()));
      emit(editing.copyWith(isSaving: false));
    }
  }

  Future<void> _onCanvasExported(
    PixelArtCanvasExported event,
    Emitter<PixelArtState> emit,
  ) async {
    if (state is! PixelArtEditing) return;
    final editing = state as PixelArtEditing;
    emit(editing.copyWith(isExporting: true));
    try {
      final url = await _repository.exportAndUpload(editing.canvas);
      if (url != null) {
        emit(PixelArtExported(url));
        emit(editing.copyWith(isExporting: false, exportUrl: url));
      } else {
        emit(const PixelArtError('Export failed'));
        emit(editing.copyWith(isExporting: false));
      }
    } catch (e) {
      emit(PixelArtError(e.toString()));
      emit(editing.copyWith(isExporting: false));
    }
  }

  void _onUndoRequested(
    PixelArtUndoRequested event,
    Emitter<PixelArtState> emit,
  ) {
    if (state is! PixelArtEditing) return;
    final editing = state as PixelArtEditing;
    if (editing.undoStack.isEmpty) return;

    final newStack = List<List<List<int>>>.from(editing.undoStack);
    final prevGrid = newStack.removeLast();

    emit(editing.copyWith(
      canvas: editing.canvas.copyWith(
        pixels: prevGrid,
        updatedAt: DateTime.now(),
      ),
      undoStack: newStack,
    ));
  }

  Future<void> _onCanvasSizeChanged(
    PixelArtCanvasSizeChanged event,
    Emitter<PixelArtState> emit,
  ) async {
    if (state is! PixelArtEditing) return;
    final editing = state as PixelArtEditing;
    final newCanvas = PixelCanvasModel.blank(
      editing.canvas.ownerUid,
      event.width,
      event.height,
    ).copyWith(canvasId: editing.canvas.canvasId);
    emit(editing.copyWith(canvas: newCanvas, undoStack: []));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns an independent deep copy of [grid].
  static List<List<int>> _deepCopyGrid(List<List<int>> grid) =>
      grid.map((row) => List<int>.from(row)).toList();

  /// BFS flood-fill replacing [targetColor] with [fillColor] from ([row],[col]).
  static void _floodFill(
    List<List<int>> grid,
    int startRow,
    int startCol,
    int targetColor,
    int fillColor,
    int width,
    int height,
  ) {
    if (targetColor == fillColor) return;
    if (grid[startRow][startCol] != targetColor) return;

    final queue = <(int, int)>[(startRow, startCol)];
    grid[startRow][startCol] = fillColor;

    while (queue.isNotEmpty) {
      final (r, c) = queue.removeAt(0);
      for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 &&
            nr < height &&
            nc >= 0 &&
            nc < width &&
            grid[nr][nc] == targetColor) {
          grid[nr][nc] = fillColor;
          queue.add((nr, nc));
        }
      }
    }
  }
}
