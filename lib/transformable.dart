library transformable;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:transformable/inertial_motion.dart';

class Transformable extends StatefulWidget {
  Transformable({
    Key key,
    // The child to perform the transformations on.
    @required this.child,
    // Max/Min values
    this.maxScale = 2.5,
    this.minScale = 0.8,
    // Initial Values
    this.initialTranslation,
    this.initialScale,
    this.initialRotation, // Any and all of the possible transformations can be disabled.
    this.disableTranslation = false,
    this.disableScale = false,
    this.disableRotation = true,
    // Access to event callbacks from GestureDetector. Called with untransformed
    // coordinates in an Offset.
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressUp,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  })  : assert(child != null),
        assert(minScale != null),
        assert(minScale > 0),
        assert(disableTranslation != null),
        assert(disableScale != null),
        assert(disableRotation != null);

  /// [Matrix4] change notification callback
  ///
  final Widget child;
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final GestureTapCallback onTap;
  final GestureTapCancelCallback onTapCancel;
  final GestureTapCallback onDoubleTap;
  final GestureLongPressCallback onLongPress;
  final GestureLongPressUpCallback onLongPressUp;
  final GestureDragDownCallback onVerticalDragDown;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragCancelCallback onVerticalDragCancel;
  final GestureDragDownCallback onHorizontalDragDown;
  final GestureDragStartCallback onHorizontalDragStart;
  final GestureDragUpdateCallback onHorizontalDragUpdate;
  final GestureDragEndCallback onHorizontalDragEnd;
  final GestureDragCancelCallback onHorizontalDragCancel;
  final GestureDragDownCallback onPanDown;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final GestureDragCancelCallback onPanCancel;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;
  final double maxScale;
  final double minScale;
  final bool disableTranslation;
  final bool disableScale;
  final bool disableRotation;
  final Offset initialTranslation;
  final double initialScale;
  final double initialRotation;

  @override
  _TransformableState createState() => _TransformableState();
}

enum _GestureType {
  translate,
  scale,
  rotate,
}

typedef MatrixGestureDetectorCallback = void Function(Matrix4 matrix);

class _TransformableState extends State<Transformable> {
  // The translation that will be applied to the scene (not viewport).
  // A positive x offset moves the scene right, viewport left.
  // A positive y offset moves the scene down, viewport up.
  Offset _translateFromScene; // Point where a single translation began.
  double _scaleStart; // Scale value at start of scaling gesture.
  double _rotationStart = 0.0; // Rotation at start of rotation gesture.
  Matrix4 _transform = Matrix4.identity();
  double _currentRotation = 0.0;
  _GestureType gestureType;

  // The transformation matrix that gives the initial home position.
  Matrix4 get _initialTransform {
    Matrix4 matrix = Matrix4.identity();
    if (widget.initialTranslation != null) {
      matrix = matrixTranslate(matrix, widget.initialTranslation);
    }
    if (widget.initialScale != null) {
      matrix = matrixScale(matrix, widget.initialScale);
    }
    if (widget.initialRotation != null) {
      matrix = matrixRotate(matrix, widget.initialRotation, Offset.zero);
    }
    return matrix;
  }

  // Return the scene point at the given viewport point.
  static Offset fromViewport(Offset viewportPoint, Matrix4 transform) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(transform);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }

  // Get the offset of the current widget from the global screen coordinates.
  // TODO(justinmc): Protect against calling this during first build.
  static Offset getOffset(BuildContext context) {
    final RenderBox renderObject = context.findRenderObject();
    return renderObject.localToGlobal(Offset.zero);
  }

  @override
  void initState() {
    super.initState();
    _transform = _initialTransform;
  }

  @override
  Widget build(BuildContext context) {
    // A GestureDetector allows the detection of panning and zooming gestures on
    // its child, which is the CustomPaint.
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Necessary when translating off screen
      onTapDown: widget.onTapDown == null
          ? null
          : (TapDownDetails details) {
              widget.onTapDown(TapDownDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onTapUp: widget.onTapUp == null
          ? null
          : (TapUpDetails details) {
              widget.onTapUp(TapUpDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onTap: widget.onTap,
      onTapCancel: widget.onTapCancel,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onLongPressUp: widget.onLongPressUp,
      onVerticalDragDown: widget.onVerticalDragDown == null
          ? null
          : (DragDownDetails details) {
              widget.onVerticalDragDown(DragDownDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onVerticalDragStart: widget.onVerticalDragStart == null
          ? null
          : (DragStartDetails details) {
              widget.onVerticalDragStart(DragStartDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onVerticalDragUpdate: widget.onVerticalDragUpdate == null
          ? null
          : (DragUpdateDetails details) {
              widget.onVerticalDragUpdate(DragUpdateDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onVerticalDragEnd: widget.onVerticalDragEnd,
      onVerticalDragCancel: widget.onVerticalDragCancel,
      onHorizontalDragDown: widget.onHorizontalDragDown == null
          ? null
          : (DragDownDetails details) {
              widget.onHorizontalDragDown(DragDownDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onHorizontalDragStart: widget.onHorizontalDragStart == null
          ? null
          : (DragStartDetails details) {
              widget.onHorizontalDragStart(DragStartDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onHorizontalDragUpdate: widget.onHorizontalDragUpdate == null
          ? null
          : (DragUpdateDetails details) {
              widget.onHorizontalDragUpdate(DragUpdateDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
      onHorizontalDragCancel: widget.onHorizontalDragCancel,
      onPanDown: widget.onPanDown == null
          ? null
          : (DragDownDetails details) {
              widget.onPanDown(DragDownDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onPanStart: widget.onPanStart == null
          ? null
          : (DragStartDetails details) {
              widget.onPanStart(DragStartDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onPanUpdate: widget.onPanUpdate == null
          ? null
          : (DragUpdateDetails details) {
              widget.onPanUpdate(DragUpdateDetails(
                globalPosition: fromViewport(
                    details.globalPosition - getOffset(context), _transform),
              ));
            },
      onPanEnd: widget.onPanEnd,
      onPanCancel: widget.onPanCancel,
      onScaleEnd: _onScaleEnd,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: Transform(
        transform: _transform,
        child: widget.child,
      ),
    );
  }

  // Return a new matrix representing the given matrix after applying the given
  // translation.
  Matrix4 matrixTranslate(Matrix4 matrix, Offset translation) {
    if (widget.disableTranslation || translation == Offset.zero) {
      return matrix;
    }

    final Matrix4 nextMatrix = matrix.clone()
      ..translate(
        translation.dx,
        translation.dy,
      );

    return nextMatrix;
  }

  // Return a new matrix representing the given matrix after applying the given
  // scale transform.
  Matrix4 matrixScale(Matrix4 matrix, double scale) {
    if (widget.disableScale || scale == 1) {
      return matrix;
    }
    assert(scale != 0);

    // Don't allow a scale that results in an overall scale beyond min/max
    // scale.
    final double currentScale = _transform.getMaxScaleOnAxis();
    final double totalScale = currentScale * scale;
    final double clampedTotalScale = totalScale.clamp(
      widget.minScale,
      widget.maxScale,
    );
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix..scale(clampedScale);
  }

  // Return a new matrix representing the given matrix after applying the given
  // rotation transform.
  // Rotating the scene cannot cause the viewport to view beyond _boundaryRect.
  Matrix4 matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (widget.disableRotation || rotation == 0) {
      return matrix;
    }
    final Offset focalPointScene = fromViewport(focalPoint, matrix);
    return matrix
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  // Handle the start of a gesture of _GestureType.
  void _onScaleStart(ScaleStartDetails details) {
    if (widget.onScaleStart != null) {
      widget.onScaleStart(details);
    }

    gestureType = null;
    setState(() {
      _scaleStart = _transform.getMaxScaleOnAxis();
      _translateFromScene = fromViewport(details.focalPoint, _transform);
      _rotationStart = _currentRotation;
    });
  }

  // Handle an update to an ongoing gesture of _GestureType.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    double scale = _transform.getMaxScaleOnAxis();
    if (widget.onScaleUpdate != null) {
      widget.onScaleUpdate(ScaleUpdateDetails(
        focalPoint: fromViewport(details.focalPoint, _transform),
        scale: details.scale,
        rotation: details.rotation,
      ));
    }
    final Offset focalPointScene = fromViewport(
      details.focalPoint,
      _transform,
    );
    // Decide which type of gesture this is by comparing the amount of scale
    // and rotation in the gesture, if any. Scale starts at 1 and rotation
    // starts at 0. Translate will have 0 scale and 0 rotation because it uses
    // only one finger.
    if ((details.scale - 1).abs() > details.rotation.abs()) {
      gestureType = _GestureType.scale;
      print('scale');
    } else if (details.rotation != 0) {
      gestureType = _GestureType.rotate;
      print('rotate');
    } else {
      gestureType = _GestureType.translate;
      print('translate');
    }
    setState(() {
      if (gestureType == _GestureType.scale && _scaleStart != null) {
        // details.scale gives us the amount to change the scale as of the
        // start of this gesture, so calculate the amount to scale as of the
        // previous call to _onScaleUpdate.
        final double desiredScale = _scaleStart * details.scale;
        final double scaleChange = desiredScale / scale;
        _transform = matrixScale(_transform, scaleChange);
        scale = _transform.getMaxScaleOnAxis();

        // While scaling, translate such that the user's two fingers stay on the
        // same places in the scene. That means that the focal point of the
        // scale should be on the same place in the scene before and after the
        // scale.
        final Offset focalPointSceneNext = fromViewport(
          details.focalPoint,
          _transform,
        );
        _transform =
            matrixTranslate(_transform, focalPointSceneNext - focalPointScene);
      } else if (gestureType == _GestureType.rotate &&
          details.rotation != 0.0) {
        final double desiredRotation = _rotationStart + details.rotation;
        _transform = matrixRotate(
            _transform, _currentRotation - desiredRotation, details.focalPoint);
        _currentRotation = desiredRotation;
      } else if (_translateFromScene != null && details.scale == 1.0) {
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange = focalPointScene - _translateFromScene;
        _transform = matrixTranslate(_transform, translationChange);
        _translateFromScene = fromViewport(details.focalPoint, _transform);
      }
    });
  }

  // Handle the end of a gesture of _GestureType.
  void _onScaleEnd(ScaleEndDetails details) {
    if (widget.onScaleEnd != null) {
      widget.onScaleEnd(details);
    }
    setState(() {
      _scaleStart = null;
      _rotationStart = null;
      _translateFromScene = null;
    });

    // If the scale ended with velocity, animate inertial movement
    final double velocityTotal = details.velocity.pixelsPerSecond.dx.abs() +
        details.velocity.pixelsPerSecond.dy.abs();
    if (velocityTotal == 0) {
      return;
    }

    final Vector3 translationVector = _transform.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
