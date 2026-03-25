import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'drawing_state.dart';
import 'stroke.dart';

class DrawingCubit extends Cubit<DrawingState> {
  static const int _maxHistory = 150;

  DrawingCubit() : super(DrawingState.initial());

  void setMode(StrokeMode mode) {
    emit(state.copyWith(
      mode: mode,
      brush: state.brush.copyWith(
        kind: mode == StrokeMode.eraser
            ? BrushKind.eraser
            : _nonEraserKind(state.brush.kind),
      ),
    ));
  }

  void setBrushKind(BrushKind kind) {
    emit(state.copyWith(
      mode: kind == BrushKind.eraser ? StrokeMode.eraser : StrokeMode.brush,
      brush: state.brush.copyWith(kind: kind),
    ));
  }

  void setBrush(double screenPx) {
    emit(state.copyWith(
      brushSize: screenPx,
      brush: state.brush.copyWith(width01: _px2w01(screenPx)),
    ));
  }

  void setBrushWidth01(double width01) {
    final w = width01.clamp(0.001, 0.5);
    emit(state.copyWith(
      brushSize: _w012px(w),
      brush: state.brush.copyWith(width01: w),
    ));
  }

  void showCursorAt(Offset p) =>
      emit(state.copyWith(showCursor: true, cursorPoint: p));

  void hideCursor() => emit(state.copyWith(
    showCursor: false,
    cursorPoint: null,
  ));

  void startStrokeImagePx(Offset imagePoint, {required double widthPx}) {
    if (widthPx.isNaN || widthPx.isInfinite || widthPx <= 0) return;

    final next = List<Stroke>.from(state.strokes)
      ..add(
        Stroke(
          pts: [imagePoint],
          width: widthPx.clamp(1.0, 600.0),
          mode: state.mode,
        ),
      );

    final trimmed =
    next.length > _maxHistory ? next.sublist(next.length - _maxHistory) : next;

    emit(state.copyWith(
      strokes: trimmed,
      redoStack: const [],
      showCursor: true,
      cursorPoint: imagePoint,
    ));
  }

  void addPointImagePx(Offset imagePoint) {
    if (state.strokes.isEmpty) return;

    final list = List<Stroke>.from(state.strokes);
    final last = list.removeLast();

    final previousPoint = last.pts.last;
    final dx = previousPoint.dx - imagePoint.dx;
    final dy = previousPoint.dy - imagePoint.dy;
    final minDistance = (last.width * 0.08).clamp(1.2, 4.0);

    if ((dx * dx) + (dy * dy) < (minDistance * minDistance)) {
      emit(state.copyWith(
        showCursor: true,
        cursorPoint: imagePoint,
      ));
      return;
    }

    list.add(last.copyWith(pts: [...last.pts, imagePoint]));
    emit(state.copyWith(
      strokes: list,
      showCursor: true,
      cursorPoint: imagePoint,
    ));
  }

  void endStroke() => emit(state.copyWith(
    showCursor: false,
    cursorPoint: null,
  ));

  void undo() {
    if (state.strokes.isEmpty) return;
    final list = List<Stroke>.from(state.strokes);
    final last = list.removeLast();

    emit(state.copyWith(
      strokes: list,
      redoStack: [...state.redoStack, last],
      showCursor: false,
      cursorPoint: null,
    ));
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final redo = List<Stroke>.from(state.redoStack);
    final last = redo.removeLast();

    final next = [...state.strokes, last];
    final trimmed =
    next.length > _maxHistory ? next.sublist(next.length - _maxHistory) : next;

    emit(state.copyWith(
      strokes: trimmed,
      redoStack: redo,
      showCursor: false,
      cursorPoint: null,
    ));
  }

  void clear() => emit(state.copyWith(
    strokes: const [],
    redoStack: const [],
    showCursor: false,
    cursorPoint: null,
  ));

  BrushKind _nonEraserKind(BrushKind k) =>
      k == BrushKind.eraser ? BrushKind.solid : k;

  double _px2w01(double px) {
    const minPx = 8.0, maxPx = 120.0;
    const min01 = 0.01, max01 = 0.25;
    final t = ((px - minPx) / (maxPx - minPx)).clamp(0.0, 1.0);
    return (min01 + (max01 - min01) * t).clamp(min01, max01);
  }

  double _w012px(double w01) {
    const minPx = 8.0, maxPx = 120.0;
    const min01 = 0.01, max01 = 0.25;
    final t = ((w01 - min01) / (max01 - min01)).clamp(0.0, 1.0);
    return (minPx + (maxPx - minPx) * t).clamp(minPx, maxPx);
  }
}