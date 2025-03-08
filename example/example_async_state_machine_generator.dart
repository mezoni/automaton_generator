import 'dart:io';

import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/extra.dart';
import 'package:automaton_generator/helper.dart';
import 'package:automaton_generator/state.dart';
import 'package:toml/toml.dart';

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
  const outputFile = 'example/example_async_state_machine.dart';
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
