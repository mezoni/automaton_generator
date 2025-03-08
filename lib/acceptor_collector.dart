import 'state.dart';

class AcceptorCollector implements StateVisitor<List<OperationState>> {
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
