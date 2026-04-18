// lib/engine/flyout/flyout_extension_category_header.dart

import 'package:flutter/material.dart';
import 'flyout_button.dart';

/// State of extension (READY / NOT READY)
enum ExtensionStatus { ready, notReady }

/// Header shown in flyout for Scratch extensions.
/// Displays:
///   • Category label (text)
///   • Status button (image)
class FlyoutExtensionCategoryHeader extends StatelessWidget {
  final String extensionId;
  final String label;
  final double flyoutWidth;

  /// Callback called when status button is tapped
  final VoidCallback onStatusTap;

  /// Current extension status
  final ExtensionStatus status;

  const FlyoutExtensionCategoryHeader({
    super.key,
    required this.extensionId,
    required this.label,
    required this.flyoutWidth,
    required this.onStatusTap,
    required this.status,
  });

  /// Select icon based on extension status
  String get iconAsset {
    switch (status) {
      case ExtensionStatus.ready:
        return "assets/status_ready.png"; // replace with your assets
      case ExtensionStatus.notReady:
        return "assets/status_not_ready.png"; // replace with your assets
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: flyoutWidth,
      height: 48,
      child: Stack(
        children: [
          // Category label
          Positioned(
            left: 0,
            top: 0,
            right: 70,
            bottom: 0,
            child: FlyoutButton(
              text: label,
              isLabel: true,
              isCategoryLabel: true,
              position: const Offset(0, 0),
            ),
          ),
          // Status button (image)
          Positioned(
            right: 20,
            top: 6,
            child: GestureDetector(
              onTap: onStatusTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Image.asset(
                  iconAsset,
                  height: 30,
                  width: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
