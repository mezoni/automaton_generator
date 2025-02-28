# automaton_generator

The `automaton generator` is a low-level generator for use with generators of converters (encoders/decoders), scanners, parsers, state machines and the like

Version: 1.0.0

[![Pub Package](https://img.shields.io/pub/v/automaton_generator.svg)](https://pub.dev/packages/automaton_generator)
[![GitHub Issues](https://img.shields.io/github/issues/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/issues)
[![GitHub Forks](https://img.shields.io/github/forks/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/forks)
[![GitHub Stars](https://img.shields.io/github/stars/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/stargazers)
[![GitHub License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://raw.githubusercontent.com/mezoni/automaton_generator/main/LICENSE)

## About this software

The `automaton generator` is a low-level generator for use with generators of converters (encoders/decoders), scanners, parsers, state machines and the like.  
This software was created primarily for use as a base code generator in a parser generator. But this method of use does not limit its purpose. Because it is a universal and abstract generator.  
Why is it abstract? Because the generator and the generated code have no idea what they are doing and what the purpose is.

Using this software directly can be a bit difficult due to the fact that it is a low-level generator. However, it is not impossible.  
Higher (middle) level data structures may be implemented in the future, but they are not provided at this time.  
The (middle) level (layer) structures is `virtual` compound statements.  
Low-level nodes are not data structures that can be actually combined into data structures. Because the only data structure is the automaton.  
The automaton has one input and multiple outputs.  
This is roughly the same as machine instructions. Machine code does not have compound statements.  
Yes, it is not machine code and it is not the same thing at all, but it is just nodes connected to each other.  
In this case, a node is a piece of source code consisting of nodes, each of which is simultaneously a state, a transition, and an action (all in one, depending on what code is defined for the node.). And, in addition, it is a switch in the automaton to the `accepted` or `rejected` branch.  

The generated code executes very, very fast.  All it does is switch between two states and direct execution to one of the branches.  
Right or left, right or left, that's the whole logic of automaton.  
This is the low level logic of operation.  
The logic of higher-level operations can be as complex as necessary. But this requires a higher level generator, an application specific level generator.

The simplest non-illogical node can be defined as follows.:  

```dart
{{accept}}
```

This is always a successful machine node.  

Another node:

```dart
{{reject}}
```

This is not a logical node. Although it is possible that it could also be used, because from the point of view of the automaton this is a completely normal node.  

The most commonly used type of node:

```dart
{{accept}}
{{reject}}
```

This is a bidirectional branching node.  

A more practical example.  

```dart
if (condition) {
  {{accept}}
}
{{reject}}
```

Is this some kind of language?  
No. This is a normal source code template, where by convention `{{accept}}` and `{{reject}}` are placeholders for code from the subsequent nodes.  
The automaton is built from such nodes.  

Any node can execute another automaton within itself.  
Typically this is required, whether a `parent-child` approach to implementation is necessary. Because such a concept cannot be implemented out of the box in practice. This requires the implementation of the embedded automaton.  

Does this affect performance? No, no and no again.  
The automaton does not have its own code. It is just generated virtual switches in one of two directions, without a single line of code.  

Example:

Node 1

```dart
1
{{accept}}
{{reject}}
```

Node 2

```dart
2
{{accept}}
{{reject}}
```

This is all self-logical automaton.  
Below is a proof of the truth of the automaton concept.  

```dart
import 'package:automaton/automaton/allocator.dart';
import 'package:automaton/automaton/automaton.dart';
import 'package:automaton/automaton/automaton_generator.dart';
import 'package:automaton/automaton/node_generator.dart';

void main() {
  final allocator = Allocator();
  final nodeGenerator = NodeGenerator(allocator);
  final n1 = nodeGenerator.code(_node1.$1, result: _node1.$2);
  final n2 = nodeGenerator.code(_node2.$1, result: _node2.$2);
  final seq = nodeGenerator.sequence([n1, n2]);
  final automaton = Automaton(
    accept: 'return {{result}};',
    reject: '',
    start: seq,
  );
  final automatonGenerator = AutomatonGenerator(
    allocator: allocator,
    automaton: automaton,
  );
  final code = automatonGenerator.generate();
  print('''
String automaton() {
 $code
}''');
}

const _node1 = (
  '''
1
{{accept}}
{{reject}}
''',
  '1'
);

const _node2 = (
  '''
2
{{accept}}
{{reject}}
''',
  'Hello!'
);

```

Output:  

```text
String automaton() {
 1
2
return Hello!;

}
```

There is not a single piece of code in it that would add automaton, but it works as defined.

Below is an example of a very primitive generator. This is not a very correct way to create a generator, but it demonstrates the capabilities of the automaton generator.

```dart
import 'dart:io';

import 'package:automaton/automaton/allocator.dart';
import 'package:automaton/automaton/automaton.dart';
import 'package:automaton/automaton/automaton_generator.dart';
import 'package:automaton/automaton/node.dart';
import 'package:automaton/automaton/node_generator.dart';

void main(List<String> args) {
  final definitions = [
    ('turn_on', ['!power'], 'power = true; volume = 2;'),
    ('turn_off', ['power'], 'power = false;'),
    ('volume_up', ['volume < 5', 'power'], 'volume++;'),
    ('volume_down', ['volume > 0', 'power'], 'volume--;'),
  ];
  final allocator = Allocator();
  final nodeGenerator = NodeGenerator(allocator);
  final h = _Helper(NodeGenerator(allocator));
  final alternatives = <Node>[];
  for (final definition in definitions) {
    final command = definition.$1;
    final stateTest = definition.$2.join(' && ');
    final action = definition.$3;
    final checkCommand = h.check("command == '$command'");
    final checkState = h.check(stateTest);
    final performAction = h.action(action);
    final showState = h.action(r"print('power: $power, volume: $volume');");
    final notification = h.action('''print("Command '$command' rejected");''');
    final success =
        nodeGenerator.sequence([checkState, performAction, showState]);
    final failure = notification;
    final alternative = nodeGenerator.sequence([
      checkCommand,
      nodeGenerator.choice([success, failure]),
    ]);
    alternatives.add(alternative);
  }

  alternatives.add(h.action(r"print('Unknown command: $command');"));
  final start = nodeGenerator.choice(alternatives);
  final automaton = Automaton(
    accept: 'continue;',
    reject: '',
    start: start,
  );
  final automatonGenerator = AutomatonGenerator(
    allocator: allocator,
    automaton: automaton,
  );
  final code = automatonGenerator.generate();
  final stateMachine = '''
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
      print('*' * 40);
      print(command);
      $code
    }
  }
}''';
  const outputFile = 'example/example.dart';
  File(outputFile).writeAsStringSync(stateMachine);
  Process.runSync(Platform.executable, ['format', outputFile]);
}

class _Helper {
  final NodeGenerator g;

  _Helper(this.g);

  Node action(String code) {
    return g.code('''
$code
{{accept}}
{{reject}}''');
  }

  Node check(String predicate) {
    return g.code('''
if ($predicate) {
  {{accept}}
}
{{reject}}''');
  }
}

```

The generated code, when executed, produces the following output.

```text
****************************************
turn_off
Command 'turn_off' rejected
****************************************
turn_on
power: true, volume: 2
****************************************
volume_up
power: true, volume: 3
****************************************
volume_up
power: true, volume: 4
****************************************
volume_up
power: true, volume: 5
****************************************
volume_up
Command 'volume_up' rejected
****************************************
volume_down
power: true, volume: 4
****************************************
good_buy
Unknown command: good_buy
****************************************
turn_off
power: false, volume: 4
```

Once again, it is necessary to remind that this is a basic, primitive example of creating a generator.  

Below is the source code of the application (user code and automaton code).  

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
      print('*' * 40);
      print(command);
      {
        if (command == 'turn_on') {
          {
            if (!power) {
              power = true;
              volume = 2;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'turn_on' rejected");
          continue;
        }
      }
      {
        if (command == 'turn_off') {
          {
            if (power) {
              power = false;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'turn_off' rejected");
          continue;
        }
      }
      {
        if (command == 'volume_up') {
          {
            if (volume < 5 && power) {
              volume++;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'volume_up' rejected");
          continue;
        }
      }
      {
        if (command == 'volume_down') {
          {
            if (volume > 0 && power) {
              volume--;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'volume_down' rejected");
          continue;
        }
      }
      print('Unknown command: $command');
      continue;
    }
  }
}

```
