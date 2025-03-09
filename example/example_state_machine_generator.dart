import 'dart:io';

import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/extra.dart';

import 'example_helper.dart';

void main(List<String> args) {
  final sm = StateMachine('Door');
  final closed = sm.add('closed');
  final open = sm.add('open');
  final locked = sm.add('locked');
  closed.add('open', open);
  open.add('close', closed);
  closed.add('lock', locked);
  locked.add('unlock', closed);
  sm.start = closed;
  final source = sm.generate();
  const outputFile = 'example/example_state_machine.dart';
  File(outputFile).writeAsStringSync(source);
  Process.runSync(Platform.executable, ['format', outputFile]);
}

class S {
  final StateMachine stateMachine;

  final String name;

  final Map<String, S> commands = {};

  S(this.name, this.stateMachine);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(other) {
    if (other is S) {
      return other.name == name;
    }

    return false;
  }

  void add(String name, S state) {
    if (commands.containsKey(name)) {
      final state = commands[name];
      throw StateError('Command \'$name\' already exists: $state');
    }

    commands[name] = state;
  }

  @override
  String toString() {
    return name;
  }
}

class StateMachine {
  static const _template = r"""
void main(List<String> args) {
  final door = {{name}}Machine((sm, cmd) {
    throw StateError('''
Unable to move to next state.
State machine: $sm
State: ${sm.state}
Command: $cmd
''');
  });

  door.addListener((command,  previous, current) {
    if (current == {{name}}State.open) {
      final now = DateTime.now();
      print('Hello, I am a door watcher, the door was open at $now');
    }
  });

  door.addListener((command,  previous, current) {
    print("Move from '${previous.name}' state to '${current.name}' state using '${command.name}' command");
  });

  door.addListener((command,  previous, current) {
    if (current == {{name}}State.closed) {
      print('Good bye!');
    }
  });

  door.moveNext({{name}}Command.open);
  door.moveNext({{name}}Command.close);
  door.moveNext({{name}}Command.lock);
  door.moveNext({{name}}Command.unlock);
  door.moveNext({{name}}Command.open);
}

class {{name}}Machine {
  void Function({{name}}Machine machine, {{name}}Command command) onError;

  final _listeners = <void Function(
    {{name}}Command command,
    {{name}}State previous,
    {{name}}State current,
  )>[];

  {{name}}State _state = {{name}}State.closed;

  {{name}}Machine(this.onError);

  {{name}}State get state => _state;

  void addListener(
      void Function(
        {{name}}Command command,
        {{name}}State previous,
        {{name}}State current,
      )  listener) {
    if (_listeners.contains(listener)) {
      _listeners.remove(listener);
    }

    _listeners.add(listener);
  }

  void moveNext({{name}}Command command) {
    {{@state}}
  }

  void removeListener(void Function(
        {{name}}Command command,
        {{name}}State previous,
        {{name}}State current,
      ) listener) {
    _listeners.remove(listener);
  }

  void _setState({{name}}Command command, {{name}}State previous, {{name}}State current) {
    _state = current;
    for (final listener in _listeners.toList()) {
      listener(command, previous, current);
    }
  }
}

enum {{name}}Command { {{commands}} }

enum {{name}}State { {{states}} }

""";

  final String name;

  S? start;

  final Map<String, S> states = {};

  StateMachine(this.name);

  S add(String name) {
    if (states.containsKey(name)) {
      throw StateError('The state \'$name\' already exists');
    }

    final state = S(name, this);
    states[name] = state;
    return state;
  }

  String generate() {
    String stateExpr(S s) {
      return '${name}State.$s';
    }

    final stateAlternatives = <Operation>[];
    final stateSet = <String>{};
    final commandSet = <String>{};
    String setState(S s) => '_setState(command, _state, ${stateExpr(s)});';
    for (final s in states.values) {
      final testState = Test('_state == ${stateExpr(s)}');
      final commands = <Operation>[];
      for (final entry in s.commands.entries) {
        final commandName = entry.key;
        final nextState = entry.value;
        final testTransition = Test('command == ${name}Command.$commandName');
        final action = testTransition + Action(setState(nextState));
        commands.add(action);
        commandSet.add(commandName);
      }

      final stateAlternative = testState + Choice(commands);
      stateAlternatives.add(stateAlternative);
      stateSet.add(s.name);
    }

    final start = Choice(stateAlternatives);
    final startState = start.toState();
    final s0 = automaton(
      'void',
      startState,
      '{{@state}}',
      accept: 'return;',
      reject: 'onError(this, command);',
    );
    s0.generate(Allocator().allocate);
    final stateList = stateSet.toList();
    final commandList = commandSet.toList();
    stateList.sort();
    commandList.sort();
    var template = _template;
    template = template.replaceAll('{{name}}', name);
    template = template.replaceAll('{{@state}}', s0.source);
    template = template.replaceAll('{{commands}}', commandList.join(', '));
    template = template.replaceAll('{{states}}', stateList.join(', '));
    return template;
  }
}
