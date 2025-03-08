import 'dart:io';

import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/extra.dart';
import 'package:automaton_generator/helper.dart';
import 'package:automaton_generator/state.dart';

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
  final s0 = automaton('void', startState, '{{@state}}',
      accept: 'continue;', reject: reject);
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

extension on Operation {
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
