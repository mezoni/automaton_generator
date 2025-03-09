# automaton_generator

An automaton generator is a code generator (codegen) for use in generators of converters, scanners, parsers, state machines, etc.

Version: 2.0.10

[![Pub Package](https://img.shields.io/pub/v/automaton_generator.svg)](https://pub.dev/packages/automaton_generator)
[![GitHub Issues](https://img.shields.io/github/issues/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/issues)
[![GitHub Forks](https://img.shields.io/github/forks/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/forks)
[![GitHub Stars](https://img.shields.io/github/stars/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/stargazers)
[![GitHub License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://raw.githubusercontent.com/mezoni/automaton_generator/main/LICENSE)

## What is an automaton generator?

An automaton generator is a code generator (codegen) for use in generators of converters, scanners, parsers, state machines, etc.  
It is a template-based branch code generator.  
More precisely, a generator of an automaton consisting of states.  
Each state is a computational unit and must necessarily define one of two (or usually both) template placeholders.  
These are the `acceptance` and `rejection` placeholders.  
They are specified in templates using special markers:

- `{{@accept}}`
- `{{@reject}}`

There are three kinds of states available for generating states:

- `Choice`
- `Sequence`
- `Operation`

The `Choice` state generates selective branches, where each branch is an `alternative`.  
These branches are ordered, meaning that the computations do not happen simultaneously, but they are performed in the order specified.  
The `Sequence` state generates sequential branches. The sequential branch is an indivisible alternative. If any element causes a failure, the entire sequence of computation will be rejected.  

The most important kind of state is `Operation`.  
The `Operation` state acts as a `transition` and as an `action`.  
That is, not a generator, but the source code in the template determines the `transition conditions`.  
With this approach to implementation, the generator does not create any restrictions on the implementation of the automaton logic.  

## What is the difference between a state and an automaton?

The `State` after code generation will contain placeholders (`{{@accept}}`, and/or `{{@reject}}`).  
In fact, at this point in time, the `State` is in an intermediate condition.  
It is ready for further use but it is not yet an automaton.  
The `State` is not yet an automaton, since an automaton implies the presence of acceptors.  
`Acceptor` is a `State` that transfers control to another computation process.  
In this condition, two actions can be performed on the `State`.

- Subsequent state code injection
- Finalization code injection (transformation into an `acceptor`)

Subsequent state code injection is the process of placing the source code of the subsequent `State` into the appropriate placeholder.  
That is, it is part of the process of building a code base based on templates with placeholders for nested code.  
In fact, the templates may seem strange because it is not entirely clear how such code can work.  

Example:

```text
if (condition) {
  {{@accept}}
}
{{@reject}}
```

Another, more complex, example, with a `failure registration` code and a `recovery` code.

```text
final {{pos}} = scanner.position;
if (condition) {
  {{@accept}}
} else {
  // failure registration
}
// Recovery
scanner.position = {{pos}};
{{@reject}}
```

Why will the `rejection` code never execute the code after the `acceptance` code has finished executing?  
The answer is very simple, the `acceptance` code will never return control to the `rejection` code  if `acceptance` branch of computation completes successfully.  
Otherwise (if the `acceptance` branch `rejects` computation), code execution will continue down until it reaches the lowest `rejection` point.  
During code generation, all intermediate `rejection` points will be removed, allowing alternative code to be executed.  
Thus, either a successful exit (`acceptance`) with transfer of control will occur anywhere or at the very bottom point of the computation the control will be transferred forcibly (without any result) to external (or outer) computation.  

Even a single `State` can be an `automaton` but to transform this `State` into an `automaton` it is necessary to `close` it.
That is, transforming it into an `acceptor`.  
It is possible to use `return`, `continue` or `break` statements as `acceptors`. Or `shared` variable assignment `statement` if it is necessary for the computation to descend to a lower point and make a branches based on the analysis of the variable value (an example can be found in the `mux` function in the [extra](https://github.com/mezoni/automaton_generator/blob/main/lib/extra.dart) library.).

It is not very convenient to `close` all `ending` states manually correctly, and therefore there is a special generator (`AutomatonGenerator`) and an auxiliary helper function `automaton` for this purpose. In fact, this is a wrapper for the generator.

## How to use this software?

For convenient code generation, it is not enough to use only states.  
For this purpose (and as an example of usage) the [extra](https://github.com/mezoni/automaton_generator/blob/main/lib/extra.dart) library has helper functions to simplify code generation.  
These are the most commonly used general-purpose computations.  
Below is a list of these functions:

- `automaton`
- `block`
- `functionBody`
- `many`
- `many1`
- `map`
- `mux`
- `optional`
- `procedureBody`
- `recognize`
- `skipMany`
- `skipMany1`

All of them, except for the `recognize` function, are context-free generators.  
The `recognize` function requires context parameters (`position` and `substring`), but can be used in most cases.  

## Example of a command machine

In order to reduce duplicate code, a `helper` library will be used in the examples. It is used exclusively to simplify code generation.  
Also, the need for such `helper` libraries arises because the automaton states are primitive and very limited objects. In fact, they should be considered as `instructions` (and data structures) of an `intermediate` language.

Below is the source code for the `helper` library.

```dart
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

```

And the source code for a simple `command machine` generator.  
This is a free-form generator in its implementation approach.  

```dart
import 'dart:io';

import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/extra.dart';
import 'package:automaton_generator/helper.dart';
import 'package:automaton_generator/state.dart';

import 'example_helper.dart';

void main(List<String> args) {
  final definitions = [
    ('turn_on', ['!power'], 'power = true; volume = 2;'),
    ('turn_off', ['power'], 'power = false; volume = 0 ;'),
    ('volume_up', ['volume < 5', 'power'], 'volume++;'),
    ('volume_down', ['volume > 0', 'power'], 'volume--;'),
  ];

  final states = <Operation>[];
  const printState = 'print(\'power: \$power, volume: \$volume\');';
  for (final definition in definitions) {
    final commandName = escapeString(definition.$1, '"');
    final commandCondition = definition.$2.join(' && ');
    final commandAction = definition.$3;
    final testCommand = Test('command == $commandName');
    final testCondition = Test(commandCondition);
    final work = Action(commandAction);
    final showState = Action(printState);
    final notifyRejected = Action('print(\'Command $commandName rejected\');');
    final onRejected = showState + notifyRejected;
    final state =
        testCommand + ((testCondition + work + showState) | onRejected);
    states.add(state);
  }

  const unknownCommand = 'print(\'Unknown command: \$command\');';

  bool getMode() => true;
  final ignoreFailures = getMode();
  String? reject;
  if (!ignoreFailures) {
    reject = 'break;';
    states.add(Fatal(unknownCommand));
  } else {
    states.add(Action(unknownCommand));
  }

  final start = Choice(states);
  final startState = start.toState();
  final s0 = automaton(
    'void',
    startState,
    '{{@state}}',
    accept: 'continue;',
    reject: reject,
  );
  s0.generate(Allocator().allocate);
  final source = s0.source;

  final library = '''
import 'dart:collection';

void main(List<String> args) {
  final audio = Audio();
  final commands = [
    'turn_off',
    'turn_on',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_down',
  ];
  audio.commands.addAll(commands);
  audio.execute();
  commands.clear();
  commands.addAll([
    'good_buy',
    'turn_off',
  ]);
  audio.commands.addAll(commands);
  audio.execute();
}

class Audio {
  final Queue<String> commands = Queue();

  var power = false;

  int volume = 2;

  void execute() {
    while (commands.isNotEmpty) {
      final command = commands.removeFirst();
      print('-' * 40);
      print(command);
      $source
    }
  }
}''';
  const outputFile = 'example/example.dart';
  File(outputFile).writeAsStringSync(library);
  Process.runSync(Platform.executable, ['format', outputFile]);
}

class Command extends Operation {
  final String name;

  Command(this.name);

  @override
  State toState() {
    final escapedName = escapeString(name);
    final template = '''
if (command == $escapedName) {
  {{@accept}}
}
{{@reject}}''';
    final state = OperationState('void', template);
    return state;
  }
}

```

This free-form generator generates the following source code:

```dart
import 'dart:collection';

void main(List<String> args) {
  final audio = Audio();
  final commands = [
    'turn_off',
    'turn_on',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_down',
  ];
  audio.commands.addAll(commands);
  audio.execute();
  commands.clear();
  commands.addAll([
    'good_buy',
    'turn_off',
  ]);
  audio.commands.addAll(commands);
  audio.execute();
}

class Audio {
  final Queue<String> commands = Queue();

  var power = false;

  int volume = 2;

  void execute() {
    while (commands.isNotEmpty) {
      final command = commands.removeFirst();
      print('-' * 40);
      print(command);
      if (command == "turn_on") {
        if (!power) {
          power = true;
          volume = 2;
          print('power: $power, volume: $volume');
          continue;
        }
        print('power: $power, volume: $volume');
        print('Command "turn_on" rejected');
        continue;
      }
      if (command == "turn_off") {
        if (power) {
          power = false;
          volume = 0;
          print('power: $power, volume: $volume');
          continue;
        }
        print('power: $power, volume: $volume');
        print('Command "turn_off" rejected');
        continue;
      }
      if (command == "volume_up") {
        if (volume < 5 && power) {
          volume++;
          print('power: $power, volume: $volume');
          continue;
        }
        print('power: $power, volume: $volume');
        print('Command "volume_up" rejected');
        continue;
      }
      if (command == "volume_down") {
        if (volume > 0 && power) {
          volume--;
          print('power: $power, volume: $volume');
          continue;
        }
        print('power: $power, volume: $volume');
        print('Command "volume_down" rejected');
        continue;
      }
      print('Unknown command: $command');
      continue;
    }
  }
}
```

That is, without much effort, a simple `command machine` code generator was created.  

An example of a `command machine` in operation.

```text
----------------------------------------
turn_off
power: false, volume: 2
Command "turn_off" rejected
----------------------------------------
turn_on
power: true, volume: 2
----------------------------------------
volume_up
power: true, volume: 3
----------------------------------------
volume_up
power: true, volume: 4
----------------------------------------
volume_up
power: true, volume: 5
----------------------------------------
volume_up
power: true, volume: 5
Command "volume_up" rejected
----------------------------------------
volume_down
power: true, volume: 4
----------------------------------------
good_buy
Unknown command: good_buy
----------------------------------------
turn_off
power: false, volume: 0
```

Another way to implement such a generator.

- Using `TOML`
- Using `Stream`

```dart
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

```

This generator generates the following source code:

```dart
void main(List<String> args) {
  final door = DoorMachine((sm, cmd) {
    throw StateError('''
Unable to move to next state.
State machine: $sm
State: ${sm.state}
Command: $cmd
''');
  });

  door.addListener((command, previous, current) {
    if (current == DoorState.open) {
      final now = DateTime.now();
      print('Hello, I am a door watcher, the door was open at $now');
    }
  });

  door.addListener((command, previous, current) {
    print(
        "Move from '${previous.name}' state to '${current.name}' state using '${command.name}' command");
  });

  door.addListener((command, previous, current) {
    if (current == DoorState.closed) {
      print('Good bye!');
    }
  });

  door.moveNext(DoorCommand.open);
  door.moveNext(DoorCommand.close);
  door.moveNext(DoorCommand.lock);
  door.moveNext(DoorCommand.unlock);
  door.moveNext(DoorCommand.open);
}

class DoorMachine {
  void Function(DoorMachine machine, DoorCommand command) onError;

  final _listeners = <void Function(
    DoorCommand command,
    DoorState previous,
    DoorState current,
  )>[];

  DoorState _state = DoorState.closed;

  DoorMachine(this.onError);

  DoorState get state => _state;

  void addListener(
      void Function(
        DoorCommand command,
        DoorState previous,
        DoorState current,
      ) listener) {
    if (_listeners.contains(listener)) {
      _listeners.remove(listener);
    }

    _listeners.add(listener);
  }

  void moveNext(DoorCommand command) {
    if (_state == DoorState.closed) {
      if (command == DoorCommand.open) {
        _setState(command, _state, DoorState.open);
        return;
      }
      if (command == DoorCommand.lock) {
        _setState(command, _state, DoorState.locked);
        return;
      }
    }
    if (_state == DoorState.open) {
      if (command == DoorCommand.close) {
        _setState(command, _state, DoorState.closed);
        return;
      }
    }
    if (_state == DoorState.locked) {
      if (command == DoorCommand.unlock) {
        _setState(command, _state, DoorState.closed);
        return;
      }
    }
    onError(this, command);
  }

  void removeListener(
      void Function(
        DoorCommand command,
        DoorState previous,
        DoorState current,
      ) listener) {
    _listeners.remove(listener);
  }

  void _setState(DoorCommand command, DoorState previous, DoorState current) {
    _state = current;
    for (final listener in _listeners.toList()) {
      listener(command, previous, current);
    }
  }
}

enum DoorCommand { close, lock, open, unlock }

enum DoorState { closed, locked, open }

```

## Example of a state machine

```dart
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
      throw StateError('Transition \'$name\' already exists: $state');
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
    if (command == {{name}}Command.open) {
      final now = DateTime.now();
      print('Hello, I am a door watcher, the door was open at $now');
    }
  });

  door.addListener((command,  previous, current) {
    print("Move from '${previous.name}' state to '${current.name}' state using '${command.name}' command");
  });

  door.addListener((command,  previous, current) {
    if (command == {{name}}Command.close) {
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

```

Source code of the generated state machine.

```dart
void main(List<String> args) {
  final door = DoorMachine((sm, cmd) {
    throw StateError('''
Unable to move to next state.
State machine: $sm
State: ${sm.state}
Command: $cmd
''');
  });

  door.addListener((command, previous, current) {
    if (command == DoorCommand.open) {
      final now = DateTime.now();
      print('Hello, I am a door watcher, the door was open at $now');
    }
  });

  door.addListener((command, previous, current) {
    print(
        "Move from '${previous.name}' state to '${current.name}' state using '${command.name}' command");
  });

  door.addListener((command, previous, current) {
    if (command == DoorCommand.close) {
      print('Good bye!');
    }
  });

  door.moveNext(DoorCommand.close);
  door.moveNext(DoorCommand.open);
  door.moveNext(DoorCommand.close);
  door.moveNext(DoorCommand.lock);
  door.moveNext(DoorCommand.unlock);
  door.moveNext(DoorCommand.open);
}

class DoorMachine {
  void Function(DoorMachine machine, DoorCommand command) onError;

  final _listeners = <void Function(
    DoorCommand command,
    DoorState previous,
    DoorState current,
  )>[];

  DoorState _state = DoorState.closed;

  DoorMachine(this.onError);

  DoorState get state => _state;

  void addListener(
      void Function(
        DoorCommand command,
        DoorState previous,
        DoorState current,
      ) listener) {
    if (_listeners.contains(listener)) {
      _listeners.remove(listener);
    }

    _listeners.add(listener);
  }

  void moveNext(DoorCommand command) {
    if (_state == DoorState.closed) {
      if (command == DoorCommand.open) {
        _setState(command, _state, DoorState.open);
        return;
      }
      if (command == DoorCommand.lock) {
        _setState(command, _state, DoorState.locked);
        return;
      }
    }
    if (_state == DoorState.open) {
      if (command == DoorCommand.close) {
        _setState(command, _state, DoorState.closed);
        return;
      }
    }
    if (_state == DoorState.locked) {
      if (command == DoorCommand.unlock) {
        _setState(command, _state, DoorState.closed);
        return;
      }
    }
    onError(this, command);
  }

  void removeListener(
      void Function(
        DoorCommand command,
        DoorState previous,
        DoorState current,
      ) listener) {
    _listeners.remove(listener);
  }

  void _setState(DoorCommand command, DoorState previous, DoorState current) {
    _state = current;
    for (final listener in _listeners.toList()) {
      listener(command, previous, current);
    }
  }
}

enum DoorCommand { close, lock, open, unlock }

enum DoorState { closed, locked, open }

```

An example of how this example works.

```text
Hello, I am a door watcher, the door was open at 2025-03-09 23:46:29.464238
Move from 'closed' state to 'open' state using 'open' command
Move from 'open' state to 'closed' state using 'close' command
Good bye!
Move from 'closed' state to 'locked' state using 'lock' command
Move from 'locked' state to 'closed' state using 'unlock' command
Hello, I am a door watcher, the door was open at 2025-03-09 23:46:29.469235
Move from 'closed' state to 'open' state using 'open' command
```

## More complex examples

More complex application examples will be provided later.  
