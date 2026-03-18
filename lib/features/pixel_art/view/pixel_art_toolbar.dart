import 'package:flutter/material.dart';

import 'package:aslan_pixel/features/pixel_art/bloc/pixel_art_bloc.dart';

/// Preset colour palette for the pixel art editor.
const List<int> kPixelPalette = [
  0xFF000000, // Black
  0xFFFFFFFF, // White
  0xFFFF4757, // Red
  0xFFFF6B35, // Orange
  0xFFF5C518, // Gold
  0xFF00F5A0, // Neon Green
  0xFF00D9FF, // Cyan
  0xFF7B2FFF, // Cyber Purple
  0xFF0A1628, // Navy
  0xFF0F2040, // Surface
  0xFF1A2F50, // Dark Blue
  0xFF2D5016, // Dark Green
  0xFF8B4513, // Brown
  0xFFFF69B4, // Pink
  0xFF808080, // Grey
  0xFFC0C0C0, // Silver
];

/// Toolbar widget for the pixel art editor.
///
/// Displays colour palette, tool selectors, and action buttons.
/// Stateless — all state lives in [PixelArtBloc].
class PixelArtToolbar extends StatelessWidget {
  const PixelArtToolbar({
    super.key,
    required this.state,
    required this.bloc,
  });

  final PixelArtState state;
  final PixelArtBloc bloc;

  @override
  Widget build(BuildContext context) {
    final editing = state is PixelArtEditing ? state as PixelArtEditing : null;

    return Container(
      color: const Color(0xFF0F2040),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Colour palette ──────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kPixelPalette.map((color) {
              final isSelected =
                  editing != null && editing.selectedColor == color;
              return GestureDetector(
                onTap: () => bloc.add(PixelArtColorSelected(color)),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(color),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF5C518)
                          : const Color(0xFF1A2F50),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // ── Tool buttons + action buttons ───────────────────────────────
          Row(
            children: [
              // Tool: pencil
              _ToolButton(
                icon: Icons.edit,
                tooltip: 'Pencil',
                active: editing?.tool == PixelArtTool.pencil,
                onTap: () => bloc.add(
                  const PixelArtToolChanged(PixelArtTool.pencil),
                ),
              ),

              // Tool: eraser
              _ToolButton(
                icon: Icons.auto_fix_high,
                tooltip: 'Eraser',
                active: editing?.tool == PixelArtTool.eraser,
                onTap: () => bloc.add(
                  const PixelArtToolChanged(PixelArtTool.eraser),
                ),
              ),

              // Tool: fill
              _ToolButton(
                icon: Icons.format_color_fill,
                tooltip: 'Fill',
                active: editing?.tool == PixelArtTool.fill,
                onTap: () => bloc.add(
                  const PixelArtToolChanged(PixelArtTool.fill),
                ),
              ),

              const SizedBox(width: 8),
              const _Divider(),
              const SizedBox(width: 8),

              // Undo
              _ActionButton(
                icon: Icons.undo,
                tooltip: 'Undo',
                enabled: editing != null && editing.undoStack.isNotEmpty,
                onTap: () => bloc.add(const PixelArtUndoRequested()),
              ),

              // Save
              _ActionButton(
                icon: Icons.save,
                tooltip: 'Save',
                enabled: editing != null && !editing.isSaving,
                onTap: () => bloc.add(const PixelArtCanvasSaved()),
                loading: editing?.isSaving ?? false,
              ),

              // Export
              _ActionButton(
                icon: Icons.share,
                tooltip: 'Export PNG',
                enabled: editing != null && !editing.isExporting,
                onTap: () => bloc.add(const PixelArtCanvasExported()),
                loading: editing?.isExporting ?? false,
              ),

              const Spacer(),

              // Canvas size label
              Text(
                editing != null
                    ? '${editing.canvas.width}×${editing.canvas.height}'
                    : '—',
                style: const TextStyle(
                  color: Color(0xFF6B8AAB),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF00F5A0)
                : const Color(0xFF1A2F50),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? const Color(0xFF0A1628)
                : const Color(0xFFE8F4F8),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2F50),
            borderRadius: BorderRadius.circular(6),
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00F5A0),
                    ),
                  ),
                )
              : Icon(
                  icon,
                  size: 18,
                  color: enabled
                      ? const Color(0xFFE8F4F8)
                      : const Color(0xFF3D5A78),
                ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFF1A2F50),
    );
  }
}
