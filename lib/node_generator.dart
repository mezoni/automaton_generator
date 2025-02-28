import 'allocator.dart';
import 'automaton.dart';
import 'automaton_generator.dart';
import 'node.dart';
import 'renderer.dart';

/// The [NodeGenerator] is a helper class that helps generate the most common
/// types of node formations.
class NodeGenerator {
  /// Identifier allocator
  final Allocator allocator;

  NodeGenerator(this.allocator);

  /// Allocates an identifier.
  String allocate([String name = '']) {
    return allocator.allocate(name);
  }

  /// Connects nodes [first] and [second] so that they form a sequence.
  void andThen(Node first, Node second) {
    first.addNodes(accept: second);
  }

  /// Creates a block (the scope of variables) for [node] and returns the
  /// starting node of the block.
  ///
  /// The block is created as `single-input and single-output` formation.
  Node block(String type, Node node) {
    const template = '''
({{type}},)? {{variable}};
switch (0) {
  default:
    {{code}}
    break;
}
if ({{variable}} != null) {
  {{accept}}
}
{{reject}}''';
    final block = code(template);
    final variable = allocate();
    block.result = '$variable.\$1';
    final automaton = Automaton(
      accept: '$variable = ({{result}},);\nbreak;',
      reject: '',
      start: node,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );

    final values = {
      'code': automatonGenerator.generate(),
      'type': type,
      'variable': variable,
    };

    block.template = const Renderer().render(template, values, allocator);
    return block;
  }

  /// Connects [nodes] so that they form an ordered selection for the specified
  /// nodes.
  ///
  /// Returns the starting node of the selection.
  Node choice(List<Node> nodes) {
    if (nodes.length < 2) {
      throw ArgumentError(
          'The list of nodes must contain at least 2 elements', 'nodes');
    }

    nodes = nodes.toList();
    for (var i = nodes.length - 1; i >= 1; i--) {
      final first = nodes[i - 1];
      final second = nodes[i];
      nodes[i - 1] = or(first, second);
    }

    return nodes.first;
  }

  /// Creates a node with the specified [template] and returned [result].
  Node code(String template, {String result = 'null'}) {
    final node = Node(result: result, template: template);
    return node;
  }

  /// Forms an ordered selection from nodes [first] and [second].
  ///
  /// Returns the starting node of the selection.
  Node or(Node first, Node second) {
    if (first == second) {
      throw ArgumentError('The nodes must be different');
    }

    const template = '''
{
  {{accept}}
}
{{reject}}''';
    final node = code(template);
    node.addNodes(accept: first, reject: second);
    return node;
  }

  /// Forms a sequence of [nodes].
  ///
  /// Returns the starting node of the sequence.
  Node sequence(List<Node> nodes) {
    if (nodes.isEmpty) {
      throw ArgumentError('Must not be empty', 'nodes');
    }

    for (var i = 1; i < nodes.length; i++) {
      final previous = nodes[i - 1];
      final current = nodes[i];
      previous.addNodes(accept: current);
    }

    return nodes.first;
  }
}
