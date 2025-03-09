import 'state.dart';

/// The [AcceptorCollector] collects (finds) final (last) states of the [state].
///
/// Subsequently, these final states are transformed into `acceptors`.
///
/// The found states are used mainly to subscribe to the final stage of code
/// generation of these states, for further transformation (code generation).
class AcceptorCollector implements StateVisitor<List<OperationState>> {
  /// Collects (finds) the final (last) states of the [state] and returns them
  /// as a list.
  List<OperationState> collect(State state) {
    final states = state.accept(this);
    return states;
  }

  @override
  List<OperationState> visitChoice(ChoiceState node) {
    final children = node.states;
    final states = <OperationState>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final childStates = child.accept(this);
      states.addAll(childStates);
    }

    return states;
  }

  @override
  List<OperationState> visitOperation(OperationState node) {
    return [node];
  }

  @override
  List<OperationState> visitSequence(SequenceState node) {
    final children = node.states;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (i == children.length - 1) {
        final states = child.accept(this);
        return states;
      } else {
        child.accept(this);
      }
    }

    throw StateError('Internal error');
  }
}
