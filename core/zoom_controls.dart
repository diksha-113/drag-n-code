/*// lib/engine/zoom_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'workspace.dart';

class ZoomControls extends StatefulWidget {
  final Workspace workspace;
  final double bottomOffset;

  const ZoomControls(
      {super.key, required this.workspace, this.bottomOffset = 12});

  @override
  _ZoomControlsState createState() => _ZoomControlsState();
}

class _ZoomControlsState extends State<ZoomControls> {
  static const double width = 36;
  static const double height = 124;
  static const double marginBetween = 8;
  static const double marginSide = 12;

  double left = 0; // Prevents red line
  double top = 0; // Prevents red line

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => positionControls());
  }

  void positionControls() {
    final metrics = widget.workspace.getMetrics(); // Always valid

    // Position at bottom-right
    left = metrics.viewWidth - width - marginSide;
    top = metrics.viewHeight - height - widget.bottomOffset;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        children: [
          // Zoom in button
          GestureDetector(
            onTap: () {
              widget.workspace.markFocused();
              widget.workspace.zoomCenter(1);
            },
            child: SvgPicture.asset(
              'assets/images/zoom-in.svg', // updated path
              width: width,
              height: width,
            ),
          ),
          const SizedBox(height: marginBetween),

          // Zoom out button
          GestureDetector(
            onTap: () {
              widget.workspace.markFocused();
              widget.workspace.zoomCenter(-1);
            },
            child: SvgPicture.asset(
              'assets/images/zoom-out.svg', // updated path
              width: width,
              height: width,
            ),
          ),
          const SizedBox(height: marginBetween),

          // Zoom reset button
          GestureDetector(
            onTap: () {
              widget.workspace.markFocused();
              widget.workspace.setScale(widget.workspace.startScale);
              widget.workspace.scrollCenter();
            },
            child: SvgPicture.asset(
              'assets/images/zoom-reset.svg', // updated path
              width: width,
              height: width,
            ),
          ),
        ],
      ),
    );
  }
}
*/
