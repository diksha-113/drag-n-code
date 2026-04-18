import 'package:flutter/material.dart';
import '../core/workspace.dart';

/// =======================================================
/// COLORS
/// =======================================================
const Color sensingPrimary = Color(0xFF5CB1D6);
const double blockHeight = 44;

/// =======================================================
/// SENSING BLOCK FACTORY
/// =======================================================
Widget getSensingBlock(String type, WorkspaceEngine engine, {String? value}) {
  switch (type) {
    case 'sensing_touchingobject':
      return BooleanSensingBlock(
        label: 'Touching Object?',
        icon: Icons.pan_tool,
      );

    case 'sensing_touchingcolor':
      return BooleanSensingBlock(
        label: 'Touching Color?',
        icon: Icons.palette,
        input: InlineColorInput(engine: engine, colorKey: 'color1'),
      );

    case 'sensing_coloristouchingcolor':
      return BooleanSensingBlock(
        label: 'Color',
        icon: Icons.palette,
        input: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InlineColorInput(engine: engine, colorKey: 'color1'),
            const SizedBox(width: 6),
            const Text(
              'is touching',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 6),
            InlineColorInput(engine: engine, colorKey: 'color2'),
          ],
        ),
      );

    case 'sensing_askandwait':
      return ReporterSensingBlock(
        label: 'Ask and Wait',
        icon: Icons.question_answer,
      );

    case 'sensing_answer':
      return ReporterSensingBlock(
        label: 'Answer',
        icon: Icons.message,
      );

    case 'sensing_keypressed':
      return BooleanSensingBlock(
        label: 'Key Pressed?',
        icon: Icons.keyboard,
      );

    case 'sensing_mousedown':
      return BooleanSensingBlock(
        label: 'Mouse Down?',
        icon: Icons.mouse,
      );

    case 'sensing_mousex':
      return ReporterSensingBlock(
        label: 'Mouse X',
        icon: Icons.mouse,
      );

    case 'sensing_mousey':
      return ReporterSensingBlock(
        label: 'Mouse Y',
        icon: Icons.mouse,
      );

    case 'sensing_timer':
      return ReporterSensingBlock(
        label: 'Timer',
        icon: Icons.timer,
      );

    case 'sensing_resettimer':
      return ReporterSensingBlock(
        label: 'Reset Timer',
        icon: Icons.restart_alt,
      );

    case 'sensing_of':
      return ReporterSensingBlock(
        label: 'Of',
        icon: Icons.list_alt,
      );

    case 'sensing_distance':
      return ReporterSensingBlock(
        label: 'Distance To',
        icon: Icons.straighten,
      );

    case 'sensing_loudness':
      return ReporterSensingBlock(
        label: 'Loudness',
        icon: Icons.mic,
      );

    case 'sensing_videoon':
      return BooleanSensingBlock(
        label: 'Video On?',
        icon: Icons.videocam,
      );

    default:
      return ReporterSensingBlock(
        label: 'Unknown',
        icon: Icons.help_outline,
      );
  }
}

/// =======================================================
/// BASE RECTANGLE BLOCK
/// =======================================================
class _BaseBlock extends StatelessWidget {
  final Widget child;

  const _BaseBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: blockHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: sensingPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

/// =======================================================
/// BOOLEAN BLOCK
/// =======================================================
class BooleanSensingBlock extends StatelessWidget {
  final String label;
  final Widget? input;
  final IconData? icon;

  const BooleanSensingBlock({
    required this.label,
    this.input,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseBlock(
      child: _BlockContent(
        label: label,
        icon: icon,
        input: input,
      ),
    );
  }
}

/// =======================================================
/// REPORTER BLOCK
/// =======================================================
class ReporterSensingBlock extends StatelessWidget {
  final String label;
  final IconData? icon;

  const ReporterSensingBlock({
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseBlock(
      child: _BlockContent(
        label: label,
        icon: icon,
      ),
    );
  }
}

/// =======================================================
/// BLOCK CONTENT
/// =======================================================
class _BlockContent extends StatelessWidget {
  final String label;
  final Widget? input;
  final IconData? icon;

  const _BlockContent({
    required this.label,
    this.input,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, color: Colors.white, size: 18),
        if (icon != null) const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (input != null) ...[
          const SizedBox(width: 8),
          input!,
        ],
      ],
    );
  }
}

/// =======================================================
/// INLINE COLOR SELECTOR (WORKS WITH STAGE)
/// =======================================================
class InlineColorInput extends StatelessWidget {
  final WorkspaceEngine engine;
  final String colorKey;

  const InlineColorInput({
    super.key,
    required this.engine,
    required this.colorKey,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color?>(
      valueListenable: engine.getColorNotifier(colorKey),
      builder: (_, color, __) {
        return GestureDetector(
          onTap: () {
            engine.showColorPickerDialog(colorKey);
          },
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color ?? Colors.red,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black),
            ),
          ),
        );
      },
    );
  }
}
