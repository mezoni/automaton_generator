# automaton_generator

An automaton generator is a code generator (codegen) for use in generators of converters, scanners, parsers, state machines, etc.

Version: 2.0.9

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

## Simple example of usage

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
import 'package:automaton_generator/helper.dart';
import 'package:automaton_generator/state.dart';
import 'package:toml/toml.dart';

import 'example_helper.dart';

void main(List<String> args) {
  final document = TomlDocument.parse(_definition);
  final map = document.toMap();
  final states = <Operation>[];
  const printState = 'print(\'power: \$power, volume: \$volume\');';
  for (final entry in (map['state'] as Map).entries) {
    final command = entry.key as String;
    final value = entry.value as Map;
    final commandCondition = value['condition'] as String;
    final accept = value['accept'] as String;
    final commandName = escapeString(command, '"');
    final commandAction = accept;
    final testCommand = Test('command == $commandName');
    final testCondition = Test(commandCondition);
    final work = Action(commandAction);
    final showState = Action(printState);
    final notifyRejected = Action('print(\'Command $commandName rejected\');');
    final onRejected = notifyRejected + showState;
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
    accept: 'return;',
    reject: reject,
  );
  s0.generate(Allocator().allocate);
  final source = s0.source;

  final library = '''
import 'dart:async';

void main(List<String> args) async {
  final commands = StreamController<String>();
  Audio(commands.stream);
  final commandList = [
    'turn_off',
    'turn_on',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_down',
    'good_buy',
    'turn_off',
  ];

  await for (final command in Stream.fromIterable(commandList)) {
    commands.add(command);
  }
}

class Audio {
  final Stream<String> commands;

  var power = false;

  int volume = 2;

  Audio(this.commands) {
    commands.listen(_onCommand);
  }

  void _onCommand(String command) {
    print('-' * 40);
    print(command);
    $source
  }
}
''';
  const outputFile = 'example/example_async_command_machine.dart';
  File(outputFile).writeAsStringSync(library);
  Process.runSync(Platform.executable, ['format', outputFile]);
}

const _definition = """
[state.turn_on]
condition = '!power'
accept = '''
power = true; volume = 2;
'''

[state.turn_off]
condition = 'power'
accept = '''
power = false; volume = 0;
'''

[state.volume_up]
condition = 'volume < 5 && power'
accept = '''
volume++;;
'''

[state.volume_down]
condition = 'volume > 0 && power'
accept = '''
volume--;
'''

""";

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

This generator generates the following source code:

```dart
import 'dart:async';

void main(List<String> args) async {
  final commands = StreamController<String>();
  Audio(commands.stream);
  final commandList = [
    'turn_off',
    'turn_on',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_down',
    'good_buy',
    'turn_off',
  ];

  await for (final command in Stream.fromIterable(commandList)) {
    commands.add(command);
  }
}

class Audio {
  final Stream<String> commands;

  var power = false;

  int volume = 2;

  Audio(this.commands) {
    commands.listen(_onCommand);
  }

  void _onCommand(String command) {
    print('-' * 40);
    print(command);
    if (command == "turn_on") {
      if (!power) {
        power = true;
        volume = 2;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "turn_on" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    if (command == "turn_off") {
      if (power) {
        power = false;
        volume = 0;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "turn_off" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    if (command == "volume_up") {
      if (volume < 5 && power) {
        volume++;
        ;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "volume_up" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    if (command == "volume_down") {
      if (volume > 0 && power) {
        volume--;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "volume_down" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    print('Unknown command: $command');
    return;
  }
}

```

## More complex examples

More complex application examples will be provided later.  
