/*// lib/engine/workspace_drag_surface.dart
import 'package:flutter/material.dart';
import 'workspace_svg.dart'; // For BlockWidget reference

/// A floating surface that holds blocks while dragging,
/// so blocks can be moved efficiently without repainting everything.
class WorkspaceDragSurface extends StatefulWidget {
  WorkspaceDragSurface({Key? key}) : super(key: key);

  final _WorkspaceDragSurfaceState _state = _WorkspaceDragSurfaceState();

  /// Show the surface with given blocks
  void setContents(List<BlockWidget> blocks, double scale) {
    _state.setContents(blocks, scale);
  }

  /// Clear contents and hide the surface
  void clear() {
    _state.clear();
  }

  @override
  _WorkspaceDragSurfaceState createState() => _state;
}

class _WorkspaceDragSurfaceState extends State<WorkspaceDragSurface> {
  List<BlockWidget> _blocks = [];
  double _scale = 1.0;

  void setContents(List<BlockWidget> blocks, double scale) {
    setState(() {
      _blocks = List<BlockWidget>.from(blocks);
      _scale = scale;
    });
  }

  void clear() {
    setState(() {
      _blocks.clear();
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_blocks.isEmpty) return SizedBox.shrink();

    return Positioned(
      left: 0,
      top: 0,
      child: Transform.scale(
        scale: _scale,
        alignment: Alignment.topLeft,
        child: Stack(
          children: _blocks,
        ),
      ),
    );
  }
}
*/
