part of 'pixel_art_bloc.dart';

/// Base class for all pixel art editor events.
abstract class PixelArtEvent extends Equatable {
  const PixelArtEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once the editor page loads — hydrates the BLoC from [canvas].
class PixelArtCanvasLoaded extends PixelArtEvent {
  const PixelArtCanvasLoaded(this.canvas);

  final PixelCanvasModel canvas;

  @override
  List<Object?> get props => [canvas.canvasId];
}

/// Fired when the user draws on cell [row], [col] using [color] (ARGB int).
class PixelArtPixelPainted extends PixelArtEvent {
  const PixelArtPixelPainted({
    required this.row,
    required this.col,
    required this.color,
  });

  final int row;
  final int col;
  final int color;

  @override
  List<Object?> get props => [row, col, color];
}

/// Updates the active drawing colour.
class PixelArtColorSelected extends PixelArtEvent {
  const PixelArtColorSelected(this.color);

  final int color;

  @override
  List<Object?> get props => [color];
}

/// Switches the active drawing tool.
class PixelArtToolChanged extends PixelArtEvent {
  const PixelArtToolChanged(this.tool);

  final PixelArtTool tool;

  @override
  List<Object?> get props => [tool];
}

/// Triggers persistence of the current canvas to Firestore.
class PixelArtCanvasSaved extends PixelArtEvent {
  const PixelArtCanvasSaved();
}

/// Triggers PNG export and upload to Firebase Storage.
class PixelArtCanvasExported extends PixelArtEvent {
  const PixelArtCanvasExported();
}

/// Reverts the last paint operation.
class PixelArtUndoRequested extends PixelArtEvent {
  const PixelArtUndoRequested();
}

/// Resizes the canvas (creates a new blank canvas of the given dimensions).
class PixelArtCanvasSizeChanged extends PixelArtEvent {
  const PixelArtCanvasSizeChanged(this.width, this.height);

  final int width;
  final int height;

  @override
  List<Object?> get props => [width, height];
}
