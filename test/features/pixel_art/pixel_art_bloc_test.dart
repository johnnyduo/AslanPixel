import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/pixel_art/bloc/pixel_art_bloc.dart';
import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/pixel_art/data/repositories/pixel_art_repository.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockPixelArtRepository extends Mock implements PixelArtRepository {}

// ── Fallback fakes ────────────────────────────────────────────────────────────

class FakePixelCanvasModel extends Fake implements PixelCanvasModel {}

// ── Helpers ──────────────────────────────────────────────────────────────────

PixelCanvasModel _blankCanvas({int size = 4}) =>
    PixelCanvasModel.blank('uid_01', size, size);

void main() {
  setUpAll(() {
    registerFallbackValue(FakePixelCanvasModel());
  });

  late MockPixelArtRepository repo;

  setUp(() {
    repo = MockPixelArtRepository();
  });

  PixelArtBloc build() => PixelArtBloc(repository: repo);

  // ── Initial state ─────────────────────────────────────────────────────────

  group('PixelArtBloc initial state', () {
    test('starts as PixelArtInitial', () {
      expect(build().state, isA<PixelArtInitial>());
    });
  });

  // ── PixelArtCanvasLoaded ──────────────────────────────────────────────────

  group('PixelArtCanvasLoaded', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'emits PixelArtEditing with pencil tool and neon-green default colour',
      build: build,
      act: (bloc) => bloc.add(PixelArtCanvasLoaded(_blankCanvas())),
      expect: () => [
        isA<PixelArtEditing>()
            .having((s) => s.tool, 'tool', PixelArtTool.pencil)
            .having(
              (s) => s.selectedColor,
              'defaultColor',
              0xFF00F5A0,
            )
            .having((s) => s.undoStack, 'undoStack', isEmpty),
      ],
    );
  });

  // ── PixelArtPixelPainted ──────────────────────────────────────────────────

  group('PixelArtPixelPainted', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'pencil sets the target pixel to selectedColor',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtPixelPainted(row: 0, col: 0, color: 0));
      },
      expect: () => [
        isA<PixelArtEditing>(), // after canvas loaded
        isA<PixelArtEditing>().having(
          (s) => s.canvas.pixels[0][0],
          'pixel [0][0]',
          0xFF00F5A0, // selected color painted via pencil
        ),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'eraser sets the target pixel to navy',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        // Switch to eraser first
        bloc.add(const PixelArtToolChanged(PixelArtTool.eraser));
        // Paint
        bloc.add(const PixelArtPixelPainted(row: 1, col: 1, color: 0));
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>().having(
          (s) => s.canvas.pixels[1][1],
          'pixel [1][1] erased to navy',
          0xFF0A1628,
        ),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'painting appends to undo stack',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtPixelPainted(row: 0, col: 0, color: 0));
      },
      expect: () => [
        isA<PixelArtEditing>().having(
          (s) => s.undoStack.length,
          'undo stack before paint',
          0,
        ),
        isA<PixelArtEditing>().having(
          (s) => s.undoStack.length,
          'undo stack after paint',
          1,
        ),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'out-of-bounds paint event is ignored',
      build: build,
      act: (bloc) async {
        final canvas = _blankCanvas(size: 4);
        bloc.add(PixelArtCanvasLoaded(canvas));
        bloc.add(const PixelArtPixelPainted(row: 99, col: 99, color: 0));
      },
      expect: () => [
        isA<PixelArtEditing>(),
        // second state same as first — no change
      ],
    );
  });

  // ── PixelArtColorSelected ─────────────────────────────────────────────────

  group('PixelArtColorSelected', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'updates selectedColor when editing',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtColorSelected(0xFFF5C518)); // gold
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>().having(
          (s) => s.selectedColor,
          'selectedColor',
          0xFFF5C518,
        ),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'ignored when not in editing state',
      build: build,
      act: (bloc) =>
          bloc.add(const PixelArtColorSelected(0xFFF5C518)),
      expect: () => [],
    );
  });

  // ── PixelArtToolChanged ───────────────────────────────────────────────────

  group('PixelArtToolChanged', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'switches to fill tool',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtToolChanged(PixelArtTool.fill));
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>().having((s) => s.tool, 'tool', PixelArtTool.fill),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'ignored when not in editing state',
      build: build,
      act: (bloc) => bloc.add(const PixelArtToolChanged(PixelArtTool.eraser)),
      expect: () => [],
    );
  });

  // ── PixelArtUndoRequested ─────────────────────────────────────────────────

  group('PixelArtUndoRequested', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'reverts to previous pixel grid',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtPixelPainted(row: 0, col: 0, color: 0));
        bloc.add(const PixelArtUndoRequested());
      },
      expect: () => [
        isA<PixelArtEditing>(), // loaded
        isA<PixelArtEditing>(), // painted
        isA<PixelArtEditing>().having(
          (s) => s.undoStack,
          'undo stack empty again',
          isEmpty,
        ),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'does nothing when undo stack is empty',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtUndoRequested());
      },
      expect: () => [isA<PixelArtEditing>()],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'ignored when not in editing state',
      build: build,
      act: (bloc) => bloc.add(const PixelArtUndoRequested()),
      expect: () => [],
    );
  });

  // ── PixelArtCanvasSaved ───────────────────────────────────────────────────

  group('PixelArtCanvasSaved', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'emits [PixelArtEditing(saving), PixelArtSaved, PixelArtEditing] on success',
      build: build,
      setUp: () {
        when(() => repo.saveCanvas(any())).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtCanvasSaved());
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>()
            .having((s) => s.isSaving, 'isSaving', isTrue),
        isA<PixelArtSaved>(),
        isA<PixelArtEditing>()
            .having((s) => s.isSaving, 'isSaving', isFalse),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'emits PixelArtError when saveCanvas throws',
      build: build,
      setUp: () {
        when(() => repo.saveCanvas(any()))
            .thenThrow(Exception('Firestore write failed'));
      },
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtCanvasSaved());
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>()
            .having((s) => s.isSaving, 'isSaving', isTrue),
        isA<PixelArtError>(),
        isA<PixelArtEditing>()
            .having((s) => s.isSaving, 'isSaving', isFalse),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'ignored when not in editing state',
      build: build,
      act: (bloc) => bloc.add(const PixelArtCanvasSaved()),
      expect: () => [],
    );
  });

  // ── PixelArtCanvasExported ────────────────────────────────────────────────

  group('PixelArtCanvasExported', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'emits PixelArtExported on successful export',
      build: build,
      setUp: () {
        when(() => repo.exportAndUpload(any()))
            .thenAnswer((_) async => 'https://storage.example.com/canvas.png');
      },
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtCanvasExported());
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>()
            .having((s) => s.isExporting, 'isExporting', isTrue),
        isA<PixelArtExported>().having(
          (s) => s.url,
          'url',
          'https://storage.example.com/canvas.png',
        ),
        isA<PixelArtEditing>()
            .having((s) => s.isExporting, 'isExporting', isFalse),
      ],
    );

    blocTest<PixelArtBloc, PixelArtState>(
      'emits PixelArtError when exportAndUpload returns null',
      build: build,
      setUp: () {
        when(() => repo.exportAndUpload(any())).thenAnswer((_) async => null);
      },
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas()));
        bloc.add(const PixelArtCanvasExported());
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>()
            .having((s) => s.isExporting, 'isExporting', isTrue),
        isA<PixelArtError>(),
        isA<PixelArtEditing>()
            .having((s) => s.isExporting, 'isExporting', isFalse),
      ],
    );
  });

  // ── PixelArtCanvasSizeChanged ─────────────────────────────────────────────

  group('PixelArtCanvasSizeChanged', () {
    blocTest<PixelArtBloc, PixelArtState>(
      'replaces canvas with blank canvas of new dimensions',
      build: build,
      act: (bloc) async {
        bloc.add(PixelArtCanvasLoaded(_blankCanvas(size: 4)));
        bloc.add(const PixelArtCanvasSizeChanged(8, 8));
      },
      expect: () => [
        isA<PixelArtEditing>(),
        isA<PixelArtEditing>()
            .having((s) => s.canvas.width, 'width', 8)
            .having((s) => s.canvas.height, 'height', 8)
            .having((s) => s.undoStack, 'undoStack cleared', isEmpty),
      ],
    );
  });
}
