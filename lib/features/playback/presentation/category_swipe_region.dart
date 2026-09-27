import 'package:flutter/material.dart';

/// Converts horizontal drags into a previous/next category request.
/// Placement decides where the gesture is active; the seek bar sits outside it.
class CategorySwipeRegion extends StatefulWidget {
  const CategorySwipeRegion({
    super.key,
    required this.onShift,
    required this.child,
  });

  final ValueChanged<int> onShift;
  final Widget child;

  @override
  State<CategorySwipeRegion> createState() => _CategorySwipeRegionState();
}

class _CategorySwipeRegionState extends State<CategorySwipeRegion> {
  double _distance = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragStart: (_) => _distance = 0,
    onHorizontalDragUpdate: (details) => _distance += details.delta.dx,
    onHorizontalDragEnd: (details) {
      final velocity = details.primaryVelocity ?? 0;
      if (_distance.abs() < 44 && velocity.abs() < 300) return;
      final direction = _distance.abs() >= 44 ? _distance : velocity;
      widget.onShift(direction < 0 ? 1 : -1);
    },
    child: widget.child,
  );
}
