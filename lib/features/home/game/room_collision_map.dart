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
  // Default room layout for "starter" room
  //
  // 10 columns × 20 rows (400×800 px)
  //
  // Legend:
  //   . = walkable floor
  //   # = blocked (wall/furniture/decoration)
  //
  // Row 0-5:   Top wall + furniture (desk, monitors, bookshelf, lamp)
  // Row 6-7:   Desk edge / transition zone
  // Row 8-17:  Open floor (main NPC walking area)
  // Row 18-19: Bottom wall / edge
  // ---------------------------------------------------------------------------

  static List<List<bool>> _buildDefaultGrid() {
    // Start with everything walkable
    final grid = List.generate(
      kGridRows,
      (_) => List.filled(kGridCols, true),
    );

    // Helper to block cells
    void block(int row, int col) {
      if (row >= 0 && row < kGridRows && col >= 0 && col < kGridCols) {
        grid[row][col] = false;
      }
    }

    // --- Top wall (row 0): entirely blocked ---
    for (int c = 0; c < kGridCols; c++) {
      block(0, c);
    }

    // --- Row 1-2: Upper furniture zone ---
    // Left bookshelf (col 0-1, row 1-3)
    block(1, 0); block(1, 1);
    block(2, 0); block(2, 1);
    block(3, 0); block(3, 1);

    // Center desk with monitors (col 3-6, row 1-3)
    block(1, 3); block(1, 4); block(1, 5); block(1, 6);
    block(2, 3); block(2, 4); block(2, 5); block(2, 6);
    block(3, 3); block(3, 4); block(3, 5); block(3, 6);

    // Right bookshelf + plant (col 8-9, row 1-3)
    block(1, 8); block(1, 9);
    block(2, 8); block(2, 9);
    block(3, 8); block(3, 9);

    // --- Row 4-5: Lamp + chair area ---
    // Lamp (col 7, row 2)
    block(2, 7);

    // Chair positions (col 4-5, row 4)
    block(4, 4); block(4, 5);

    // --- Row 5-6: Transition - mostly walkable except edges ---
    block(5, 0); block(5, 9);
    block(6, 0); block(6, 9);

    // --- Row 7-8: Left and right decorations ---
    // Left candle rack (col 0, row 7-8)
    block(7, 0);
    block(8, 0);

    // Right candle rack (col 9, row 7-8)
    block(7, 9);
    block(8, 9);

    // --- Row 9-10: Center rug area (walkable but with rug item) ---
    // Rug is walkable (NPCs can walk on it)

    // --- Row 11-15: Open floor - fully walkable (main NPC area) ---
    // Just block the edges
    for (int r = 9; r < 18; r++) {
      block(r, 0); // left wall
      block(r, 9); // right wall
    }

    // --- Row 16-17: Lower furniture ---
    // Left shelf (col 0-1, row 16-17)
    block(16, 0); block(16, 1);
    block(17, 0); block(17, 1);

    // Right shelf (col 8-9, row 16-17)
    block(16, 8); block(16, 9);
    block(17, 8); block(17, 9);

    // --- Row 18-19: Bottom wall ---
    for (int c = 0; c < kGridCols; c++) {
      block(18, c);
      block(19, c);
    }

    return grid;
  }
}
