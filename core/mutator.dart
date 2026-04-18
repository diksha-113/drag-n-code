/*// lib/engine/mutator.dart

import 'package:flutter/material.dart';
import 'block.dart';
import 'workspace.dart';
import 'events.dart';
import 'icon.dart';
import 'input.dart';

/// ------------------ WorkspaceComment ------------------
class WorkspaceComment {
  String id = '';
  double width = 100;
  double height = 50;
  Offset xy = Offset.zero;

  WorkspaceComment();

  void dispose() {}

  static WorkspaceComment fromXml(Map<String, dynamic> xml, Workspace ws) {
    return WorkspaceComment();
  }

  Map<String, dynamic> toXml() => {};
  Map<String, double> getRelativeToSurfaceXY() => {"x": 0, "y": 0};
}

/// ------------------- Mutator -------------------
class Mutator {
  final List<String> quarkNames;

  double workspaceWidth = 0;
  double workspaceHeight = 0;

  Workspace? workspace;
  Block? rootBlock;
  Block? block;

  late final BlockIcon icon;

  Mutator(this.quarkNames, {this.block}) {
    icon = BlockIcon(
      iconContent: const Icon(Icons.settings, size: 14),
      bubble: Bubble(content: const Text("Mutator Editor")),
      initialPosition: const Offset(0, 0),
    );
  }

  void iconClick() {
    if (block != null && block!.isEditable) {
      if (workspace == null) {
        createEditor();
        _showIconBubble();
      } else {
        setVisible(false);
      }
    }
  }

  void _showIconBubble() {
    final bubble = icon.bubble;
    final context = icon.context;
    if (bubble == null || context == null) return;

    final pos = icon.initialPosition + Offset(icon.size / 2, icon.size / 2);
    bubble.show(context, pos);
  }

  Workspace createEditor() {
    if (block == null) {
      throw Exception("Mutator has no block assigned.");
    }

    workspace = Workspace(
      optOptions: WorkspaceOptions(parentWorkspace: block!.workspace),
    );
    workspace!.isMutator = true;

    rootBlock = block!.decompose(workspace!);
    if (rootBlock != null) {
      rootBlock!
        ..movable = false
        ..deletable = false;
    }

    workspace!.addChangeListener(workspaceChanged);
    return workspace!;
  }

  void setVisible(bool visible) {
    if (!visible) {
      workspace?.cleanUp();
      workspace = null;
      rootBlock = null;
      workspaceWidth = 0;
      workspaceHeight = 0;
      icon.bubble?.hide();
    }
  }

  void workspaceChanged() {
    if (workspace == null || workspace!.isDragging) return;

    if (block != null && rootBlock != null) {
      final oldMutation = block!.mutationToString();
      block!.compose(rootBlock!);
      final newMutation = block!.mutationToString();

      if (oldMutation != newMutation) {
        Events.fireBlockChange(block!, 'mutation', oldMutation, newMutation);
        block!.render();
      }
    }
  }

  void updateEditable() {
    if (block != null && !block!.isInFlyout && !block!.isEditable) {
      setVisible(false);
    }
  }

  void dispose() {
    if (block != null) {
      block!.mutator = null;
    }
    icon.bubble?.hide();
  }

  /// ---------- FIXED reconnect ----------
  static bool reconnect(
    BlockConnection? connectionChild,
    Block block,
    String inputName,
  ) {
    if (connectionChild == null ||
        connectionChild.sourceBlock.workspace == null) {
      return false;
    }

    final input = block.getInput(inputName);
    final BlockConnection? connectionParent =
        input?.connection as BlockConnection?;

    if (connectionParent == null) return false;

    final currentParent = connectionChild.targetBlock;

    if ((currentParent == null || currentParent == block) &&
        connectionParent.targetConnection != connectionChild) {
      if (connectionParent.isConnected == true) {
        connectionParent.disconnect();
      }
      connectionParent.connect(connectionChild);
      return true;
    }
    return false;
  }
}

/// ------------------ Workspace Extensions ------------------
class WorkspaceWithMutator extends Workspace {
  bool isMutator = false;
  bool isDragging = false;
}

/// ------------------ Block Extensions ------------------
class BlockWithMutator extends Block {
  bool isEditable = true;
  bool isInFlyout = false;

  /// MUST match base class type
  @override
  dynamic mutator;

  List<Block> children = [];

  BlockWithMutator(Workspace workspace, String? type, [String? id])
      : super(workspace, type, id);

  @override
  Block decompose(Workspace ws) {
    final clone = BlockWithMutator(ws, type, id);
    clone.children.addAll(children);
    return clone;
  }

  @override
  void compose(Block rootBlock) {
    children = List<Block>.from(
      (rootBlock as BlockWithMutator).children,
    );
  }

  @override
  String mutationToString() => children.map((c) => c.id).join(',');

  @override
  Input? getInput(String name) {
    for (final input in inputList) {
      if (input.name == name) return input;
    }
    return null;
  }
}

/// ------------------ BlockConnection ------------------
class BlockConnection {
  final Block sourceBlock;
  Block? targetBlock;
  BlockConnection? targetConnection;

  BlockConnection(this.sourceBlock);

  bool get isConnected => targetConnection != null;

  void disconnect() {
    targetConnection = null;
  }

  void connect(BlockConnection conn) {
    targetConnection = conn;
    conn.targetBlock = sourceBlock;
  }
}

/// ------------------ Events ------------------
class Events {
  static void fireBlockChange(
    Block block,
    String type,
    String oldValue,
    String newValue,
  ) {
    debugPrint('Block ${block.id} changed: $oldValue → $newValue');
  }
}

/// ------------------ BlockIcon Extensions ------------------
extension IconContext on BlockIcon {
  BuildContext? get context => null;
  double get size => 14.0;
}
*/
