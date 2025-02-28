import 'node.dart';

/// The [Automaton] is a definition of a node formation and is used to generate
/// the automaton source code.
class Automaton {
  /// The template of accepting code.
  ///
  /// This template has a key `result` which allows to obtain the value of the
  /// computation in the final node.
  final String accept;

  /// The template of reject code.
  final String reject;

  /// The starting node.
  final Node start;

  Automaton({
    required this.accept,
    required this.reject,
    required this.start,
  });
}
