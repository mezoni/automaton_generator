import 'allocator.dart';
import 'automaton.dart';
import 'node.dart';

/// The [AutomatonGenerator] is a generator of the automaton source code.
class AutomatonGenerator {
  /// Identifier allocator.
  final Allocator allocator;

  /// Automaton definition.
  final Automaton automaton;

  AutomatonGenerator({
    required this.allocator,
    required this.automaton,
  });

  /// Generates the source code of the automaton.
  String generate() {
    return _generate(automaton.start, {});
  }

  String _generate(Node node, Set<Node> processed) {
    if (!processed.add(node)) {
      throw StateError('''Recursive node:
Node template: ${node.template}''');
    }

    final result = node.result;
    var template = node.template;
    final accept = node.getAccept();
    if (accept != null) {
      final code = _generate(accept, processed);
      template = template.replaceAll('{{accept}}', code);
    } else {
      var code = automaton.accept;
      code = code.replaceAll('{{result}}', result);
      template = template.replaceAll('{{accept}}', code);
    }

    final reject = node.getReject();
    if (reject != null) {
      final code = _generate(reject, processed);
      template = template.replaceAll('{{reject}}', code);
    } else {
      final code = automaton.reject;
      template = template.replaceAll('{{reject}}', code);
    }

    return template;
  }
}
