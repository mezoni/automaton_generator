import 'dart:io';

import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/automaton.dart';
import 'package:automaton_generator/automaton_generator.dart';
import 'package:automaton_generator/node.dart';
import 'package:automaton_generator/node_generator.dart';

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
