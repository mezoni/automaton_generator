import 'dart:collection';

import 'acceptor_collector.dart';
import 'allocator.dart';
import 'automaton.dart';
import 'automaton_generator.dart';
import 'state_generator.dart';
import 'warning.dart';

typedef Listener = void Function(String Function([String]) allocate);

class ChoiceState extends GroupingState {
  ChoiceState(
    super.type,
    super.states, {
    super.result,
  });

  @override
  bool get hasSingleOutput => states.length < 2;

  @override
  T accept<T>(StateVisitor<T> visitor) {
    return visitor.visitChoice(this);
  }

  @override
  String toString() {
    return states.join('\n');
  }
}

abstract class GroupingState extends State {
  final List<State> states;

  GroupingState(
    super.type,
    List<State> states, {
    super.result,
  }) : states = UnmodifiableListView(states.toList()) {
    if (states.isEmpty) {
      throw ArgumentError('Must not be empty', 'states');
    }

    states.first.parent = this;
    for (var i = 1; i < states.length; i++) {
      final previous = states[i - 1];
      final next = states[i - 1];
      previous.next = next;
      next.previous = previous;
    }
  }

  @override
  void visitChildren<T>(StateVisitor<T> visitor) {
    for (final state in states) {
      state.accept(visitor);
    }
  }
}

class OperationState extends State {
  Map<String, String> renderedValues = <String, String>{};

  String template;

  Map<String, String> values;

  OperationState(
    super.type,
    this.template, {
    super.result,
    this.values = const {},
  });

  @override
  T accept<T>(StateVisitor<T> visitor) {
    return visitor.visitOperation(this);
  }

  @override
  String toString() {
    return template;
  }
}

class SequenceState extends GroupingState {
  SequenceState(List<State> states) : super('void', states);

  @override
  bool get hasSingleOutput {
    final last = states.last;
    return last.hasSingleOutput;
  }

  @override
  T accept<T>(StateVisitor<T> visitor) {
    return visitor.visitSequence(this);
  }

  @override
  String toString() {
    return states.join(' ');
  }
}

abstract class State {
  static const acceptPlaceholder = '{{@accept}}';

  static const rejectPlaceholder = '{{@reject}}';

  final List<Listener> listeners = [];

  String result;

  String source = '';

  String type;

  State? _next;

  State? _parent;

  State? _previous;

  State(
    this.type, {
    this.result = 'null',
  });

  bool get hasSingleOutput => true;

  State? get next {
    return _next;
  }

  set next(State? next) {
    if (_next == null && next != null) {
      _next = next;
      return;
    }

    throw StateError("Unable to set 'next'");
  }

  State? get parent {
    return _parent;
  }

  set parent(State? parent) {
    if (_parent == null && parent != null) {
      _parent = parent;
      return;
    }

    throw StateError("Unable to set 'parent'");
  }

  State? get previous {
    return _previous;
  }

  set previous(State? previous) {
    if (_previous == null && previous != null) {
      _previous = previous;
      return;
    }

    throw StateError("Unable to set 'previous'");
  }

  T accept<T>(StateVisitor<T> visitor);

  State automaton(
      String type, Automaton automaton, Map<String, String> values) {
    final generator = AutomatonGenerator(automaton);
    final state = generator.generate(type, this, values: values);
    return state;
  }

  String generate(Allocate allocate) {
    final generator = StateGenerator(allocate: allocate);
    final source = generator.generate(this);
    return source;
  }

  void listen(Listener listener) {
    listeners.add(listener);
  }

  void listenToAcceptors(
      void Function(OperationState acceptor, Allocate allocate) callback) {
    final collector = AcceptorCollector();
    final acceptors = collector.collect(this);
    for (final acceptor in acceptors) {
      acceptor.listen((allocate) {
        callback(acceptor, allocate);
      });
    }
  }

  void renderAcceptance(String? acceptance) {
    if (acceptance != null) {
      _expectedPlaceholder('accept', State.acceptPlaceholder, acceptance);
      source = source.replaceAll(State.acceptPlaceholder, acceptance);
      source = source.replaceAll('{{0}}', result);
    } else {
      _unexpectedPlaceholder('accept', State.acceptPlaceholder);
    }
  }

  void renderRejection(String? rejection) {
    if (rejection != null) {
      _expectedPlaceholder('reject', State.rejectPlaceholder, rejection);
      source = source.replaceAll(State.rejectPlaceholder, rejection);
    } else {
      _unexpectedPlaceholder('reject', State.rejectPlaceholder);
    }
  }

  void visitChildren<T>(StateVisitor<T> visitor) {
    //
  }

  void _expectedPlaceholder(String name, String placeholder, String code) {
    if (!source.contains(placeholder)) {
      warning('''
------------------------------------------------
Expected placeholder '$placeholder' in state template.
$name: ${code.trim()}
State source:
${source.trim()}''');
    }
  }

  void _unexpectedPlaceholder(String name, String placeholder) {
    if (source.contains(placeholder)) {
      warning('''
----------------------------------------
Unexpected placeholder '$placeholder' in state template.
State source:
${source.trim()}''');
    }
  }
}

abstract class StateVisitor<T> {
  T visitChoice(ChoiceState node);

  T visitOperation(OperationState node);

  T visitSequence(SequenceState node);
}

mixin StateVisitorMixin<T> implements StateVisitor<T> {
  @override
  T visitChoice(ChoiceState node) => visitNode(node);

  T visitNode(State node);

  @override
  T visitOperation(OperationState node) => visitNode(node);

  @override
  T visitSequence(SequenceState node) => visitNode(node);
}
