/*import 'dart:math';
import 'package:flutter/material.dart';

import 'connection.dart';
import '../models/block_model.dart';
import '../core/block_svg.dart';

const double SNAP_RADIUS = 20.0;

/// Coordinate helper for snapping
class Coordinate {
  double x;
  double y;
  RenderedConnection? connection;
  double radius;

  Coordinate(this.x, this.y, {this.connection, this.radius = 0});
}

/// Rendered (UI-aware) Connection
class RenderedConnection extends Connection {
  /// Offset relative to block top-left
  Coordinate offsetInBlock = Coordinate(0, 0);

  RenderedConnection(
    BlockModel sourceBlock,
    ConnectionType type,
  ) : super(sourceBlock, type);

  /// Safe UI accessor
  BlockSvg? get sourceBlockSvg => sourceBlock.uiBlock as BlockSvg?;

  // --------------------------------------------------
  // Geometry
  // --------------------------------------------------

  @override
  double distanceFrom(Connection other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  Coordinate closest(double maxRadius, Coordinate point) {
    final dx = x - point.x;
    final dy = y - point.y;
    final dist = sqrt(dx * dx + dy * dy);

    return Coordinate(
      x,
      y,
      connection: dist <= maxRadius ? this : null,
      radius: dist,
    );
  }

  // --------------------------------------------------
  // Movement
  // --------------------------------------------------

  void moveTo(double x, double y) {
    if (inDB) db?.removeConnection(this);
    this.x = x;
    this.y = y;
    if (!hidden) db?.addConnection(this);
  }

  void moveBy(double dx, double dy) {
    moveTo(x + dx, y + dy);
  }

  void moveToOffset(Coordinate blockTL) {
    moveTo(
      blockTL.x + offsetInBlock.x,
      blockTL.y + offsetInBlock.y,
    );
  }

  void setOffsetInBlock(double x, double y) {
    offsetInBlock.x = x;
    offsetInBlock.y = y;
  }

  // --------------------------------------------------
  // Snap avoidance (SAFE)
  // --------------------------------------------------

  void bumpAwayFrom(RenderedConnection staticConnection) {
    final svg = sourceBlockSvg;
    if (svg == null) return;

    double dx = (staticConnection.x + SNAP_RADIUS) - x;
    double dy = (staticConnection.y + SNAP_RADIUS) - y;

    svg.moveBy(dx, dy);
  }

  // --------------------------------------------------
  // Connect / Disconnect
  // --------------------------------------------------

  @override
  void connect(Connection childConnection) {
    super.connect(childConnection);

    final parentSvg = sourceBlockSvg;
    final childSvg = childConnection.sourceBlock.uiBlock as BlockSvg?;

    parentSvg?.renderBlock();
    childSvg?.renderBlock();
  }

  // --------------------------------------------------
  // Visibility
  // --------------------------------------------------

  void setHidden(bool value) {
    hidden = value;
    value ? db?.removeConnection(this) : db?.addConnection(this);
  }

  /// MUST match base signature
  @override
  List<BlockModel> unhideAll() {
    hidden = false;
    final blocks = <BlockModel>[];

    final block = targetBlock();
    if (block != null) blocks.add(block);

    if (targetConnection != null) {
      blocks.addAll(targetConnection!.unhideAll());
    }

    return blocks;
  }

  void hideAll() {
    hidden = true;
    targetConnection?.hideAll();
  }

  // --------------------------------------------------
  // Validation
  // --------------------------------------------------

  /// MUST match base signature
  @override
  bool isConnectionAllowed(Connection candidate) {
    if (distanceFrom(candidate) > SNAP_RADIUS) return false;
    return super.isConnectionAllowed(candidate);
  }

  // --------------------------------------------------
  // Check updates
  // --------------------------------------------------

  void onCheckChanged() {
    if (isConnected() && !checkType(targetConnection!)) {
      disconnect();
    }
  }
}
*/
