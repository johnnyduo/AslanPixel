part of 'pixel_art_bloc.dart';

/// Available drawing tools in the pixel art editor.
enum PixelArtTool { pencil, eraser, fill }

/// Base class for all pixel art editor states.
abstract class PixelArtState extends Equatable {
  const PixelArtState();

  @override
  List<Object?> get props => [];
}

/// No canvas loaded yet.
class PixelArtInitial extends PixelArtState {
  const PixelArtInitial();
}

/// Canvas is open and being edited.
class PixelArtEditing extends PixelArtState {
  const PixelArtEditing({
    required this.canvas,
    required this.selectedColor,
    required this.tool,
    required this.undoStack,
    this.isSaving = false,
    this.isExporting = false,
    this.exportUrl,
  });

  final PixelCanvasModel canvas;

  /// Currently active ARGB colour int.
  final int selectedColor;

  final PixelArtTool tool;

  /// Stack of pixel grids (each entry is a full copy before a paint op).
  /// Maximum depth: 20.
  final List<List<List<int>>> undoStack;

  final bool isSaving;
  final bool isExporting;

  /// Set after a successful export.
  final String? exportUrl;

  @override
  List<Object?> get props => [
        canvas.canvasId,
        canvas.updatedAt,
        canvas.pixels,
        selectedColor,
        tool,
        undoStack.length,
        isSaving,
        isExporting,
        exportUrl,
      ];

  PixelArtEditing copyWith({
    PixelCanvasModel? canvas,
    int? selectedColor,
    PixelArtTool? tool,
    List<List<List<int>>>? undoStack,
    bool? isSaving,
    bool? isExporting,
    String? exportUrl,
  }) =>
      PixelArtEditing(
        canvas: canvas ?? this.canvas,
        selectedColor: selectedColor ?? this.selectedColor,
        tool: tool ?? this.tool,
        undoStack: undoStack ?? this.undoStack,
        isSaving: isSaving ?? this.isSaving,
        isExporting: isExporting ?? this.isExporting,
        exportUrl: exportUrl ?? this.exportUrl,
      );
}

/// Canvas was saved successfully.
class PixelArtSaved extends PixelArtState {
  const PixelArtSaved();
}

/// Canvas was exported and uploaded successfully.
class PixelArtExported extends PixelArtState {
  const PixelArtExported(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}

/// An error occurred during a repository operation.
class PixelArtError extends PixelArtState {
  const PixelArtError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
