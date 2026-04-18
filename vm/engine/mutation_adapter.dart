// lib/vm/engine/mutation_adapter.dart

import 'package:xml/xml.dart' as xml;
import 'dart:convert' as dart_convert;

/// ------------------------------------------------------------
/// HTML/Entity decoding (lightweight decode-html replacement)
/// ------------------------------------------------------------
String decodeHtml(String input) {
  return input
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

/// ------------------------------------------------------------
/// Mutation Node model (clean Dart object)
/// ------------------------------------------------------------
class MutationNode {
  final String? tagName;
  final Map<String, dynamic> attributes;
  final List<MutationNode> children;

  MutationNode({
    required this.tagName,
    required this.attributes,
    required this.children,
  });

  @override
  String toString() {
    return 'MutationNode(tagName: $tagName, attributes: $attributes, children: $children)';
  }
}

/// ------------------------------------------------------------
/// Convert mutation DOM to Dart MutationNode
/// (Equivalent to JS mutatorTagToObject)
/// ------------------------------------------------------------
MutationNode mutatorTagToObject(xml.XmlNode dom) {
  final String? name = dom is xml.XmlElement ? dom.name.local : null;

  final Map<String, dynamic> obj = {};
  final List<MutationNode> childList = [];

  if (dom is xml.XmlElement) {
    for (final attr in dom.attributes) {
      final prop = attr.name.local;

      if (prop == 'xmlns') continue;

      String decoded = decodeHtml(attr.value);
      obj[prop] = decoded;

      // JS logic: blockinfo → blockInfo (camel case)
      if (prop == 'blockinfo') {
        obj['blockInfo'] = decoded.isNotEmpty ? jsonDecode(decoded) : {};
        obj.remove('blockinfo');
      }
    }

    // Process children
    for (final c in dom.children) {
      if (c is xml.XmlElement) {
        childList.add(mutatorTagToObject(c));
      }
    }
  }

  return MutationNode(
    tagName: name,
    attributes: obj,
    children: childList,
  );
}

/// Required for jsonDecode
dynamic jsonDecode(String s) {
  try {
    return s.isNotEmpty ? jsonParser(s) : {};
  } catch (e) {
    return {};
  }
}

/// Minimal JSON parser using dart:convert
dynamic jsonParser(String s) {
  return dartJsonDecode(s);
}

dynamic dartJsonDecode(String s) {
  return dart_convert.jsonDecode(s);
}

/// ------------------------------------------------------------
/// mutationAdapter()
/// Equivalent to JS mutationAdapter function
/// ------------------------------------------------------------
MutationNode mutationAdapter(dynamic mutation) {
  xml.XmlElement root;

  if (mutation is xml.XmlElement) {
    root = mutation;
  } else if (mutation is String) {
    final parsed = xml.XmlDocument.parse(mutation);
    root = parsed.rootElement;
  } else {
    throw ArgumentError(
      "mutation must be XML string or XmlElement",
    );
  }

  return mutatorTagToObject(root);
}
