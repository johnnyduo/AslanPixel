// ---------------------------------------------------------------------------
// room_collision_map.dart
//
// A grid-based collision map for the pixel room.
// Divides the 400×800 canvas into cells and marks each as walkable or blocked.
// NPC walk controllers use this to pick valid targets and avoid obstacles.
// ---------------------------------------------------------------------------

import 'dart:math' show Random;

import 'package:flame/components.dart';

/// Cell size in pixels. 400/cellSize must be an integer.
const double kCellSize = 40.0;

/// Number of columns (400 / 40 = 10).
const int kGridCols = 10;

/// Number of rows (800 / 40 = 20).
const int kGridRows = 20;

/// A grid-based collision map for NPC pathfinding.
///
/// Each cell is either `true` (walkable) or `false` (blocked).
/// Blocked cells represent furniture, walls, decorations, etc.
class RoomCollisionMap {
  RoomCollisionMap() : _grid = _buildDefaultGrid();

  final List<List<bool>> _grid;

  /// Whether the cell at grid coordinates (col, row) is walkable.
  bool isWalkable(int col, int row) {
    if (col < 0 || col >= kGridCols || row < 0 || row >= kGridRows) {
      return false;
    }
    return _grid[row][col];
  }

  /// Whether a world position (px) is in a walkable cell.
  bool isPositionWalkable(Vector2 position) {
    final col = (position.x / kCellSize).floor();
    final row = (position.y / kCellSize).floor();
    return isWalkable(col, row);
  }

  /// Pick a random walkable position on the map.
  Vector2 randomWalkablePosition(Random rng) {
    final walkable = <Vector2>[];
    for (int r = 0; r < kGridRows; r++) {
      for (int c = 0; c < kGridCols; c++) {
        if (_grid[r][c]) {
          // Return center of the cell
          walkable.add(Vector2(
            c * kCellSize + kCellSize / 2,
            r * kCellSize + kCellSize / 2,
          ));
        }
      }
    }
    if (walkable.isEmpty) return Vector2(200, 600); // fallback
    return walkable[rng.nextInt(walkable.length)];
  }

  /// All walkable cell centers — used for waypoint selection.
  List<Vector2> get walkablePositions {
    final result = <Vector2>[];
    for (int r = 0; r < kGridRows; r++) {
      for (int c = 0; c < kGridCols; c++) {
        if (_grid[r][c]) {
          result.add(Vector2(
            c * kCellSize + kCellSize / 2,
            r * kCellSize + kCellSize / 2,
          ));
        }
      }
    }
    return result;
  }

  /// Block a cell (e.g., when a room item is placed).
  void blockCell(int col, int row) {
    if (col >= 0 && col < kGridCols && row >= 0 && row < kGridRows) {
      _grid[row][col] = false;
    }
  }

  /// Block cells covered by a room item at world position.
  void blockWorldRect(double x, double y, double w, double h) {
    final startCol = (x / kCellSize).floor();
    final endCol = ((x + w) / kCellSize).ceil();
    final startRow = (y / kCellSize).floor();
    final endRow = ((y + h) / kCellSize).ceil();
    for (int r = startRow; r < endRow; r++) {
      for (int c = startCol; c < endCol; c++) {
        blockCell(c, r);
      }
    }
  }

  /// Check if a straight-line path between two positions is clear.
  /// Uses simple ray-march in cell increments.
  bool isPathClear(Vector2 from, Vector2 to) {
    final steps = ((to - from).length / (kCellSize * 0.5)).ceil();
    if (steps == 0) return true;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final pos = from + (to - from) * t;
      if (!isPositionWalkable(pos)) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Default room layout for "starter" room (Stardew Valley–style pixel art)
  //
  // 10 columns × 20 rows (400×800 px)
  //
  // Legend:
  //   . = walkable floor
  //   # = blocked (wall/furniture/decoration)
  //
  // Row 0-9:   Wall + desk + furniture + bookshelves — ALL BLOCKED
  // Row 10-17: Open walkable floor (main NPC walking area), edges blocked
  // Row 18-19: Bottom wall / border — ALL BLOCKED
  // ---------------------------------------------------------------------------

  static List<List<bool>> _buildDefaultGrid() {
    // Start with everything blocked
    final grid = List.generate(
      kGridRows,
      (_) => List.filled(kGridCols, false),
    );

    // Only rows 10-17, columns 1-8 are walkable (open floor area)
    for (int r = 10; r <= 17; r++) {
      for (int c = 1; c <= 8; c++) {
        grid[r][c] = true;
      }
    }

    return grid;
  }
}
