import 'package:automaton_generator/state.dart';

class Action extends Operation {
  final String source;

  Action(this.source);

  @override
  State toState() {
    final template = '''
$source
{{@accept}}
''';
    final state = OperationState('void', template);
    return state;
  }
}

class Choice extends Operation {
  final List<Operation> operations;

  Choice(this.operations);

  @override
  State toState() {
    return ChoiceState('void', operations.map((e) => e.toState()).toList());
  }
}

class Fatal extends Operation {
  final String source;

  Fatal(this.source);

  @override
  State toState() {
    final template = '''
$source
{{@reject}}
''';
    final state = OperationState('void', template);
    return state;
  }
}

abstract class Operation {
  State toState();
}

class Sequence extends Operation {
  final List<Operation> operations;

  Sequence(this.operations);

  @override
  State toState() {
    return SequenceState(operations.map((e) => e.toState()).toList());
  }
}

class Test extends Operation {
  final String condition;

  Test(this.condition);

  @override
  State toState() {
    final template = '''
if ($condition) {
  {{@accept}}
}
{{@reject}}''';
    final state = OperationState('void', template);
    return state;
  }
}

extension OperationExt on Operation {
  Sequence operator +(Operation operation) {
    if (this case final Sequence sequence) {
      sequence.operations.add(operation);
      return sequence;
    } else {
      return Sequence([this, operation]);
    }
  }

  Choice operator |(Operation operation) {
    if (this case final Choice choice) {
      choice.operations.add(operation);
      return choice;
    } else {
      return Choice([this, operation]);
    }
  }
}
