import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/extra.dart';
import 'package:automaton_generator/state.dart';
import 'package:test/test.dart';

void main() {
  testChoice();
  testSequence();
}

ChoiceState alt(String type, List<State> states) {
  return ChoiceState(type, states);
}

State s(int index) {
  final template = '''
if (v == $index) {
  {{@accept}}
}
 {{@reject}}''';
  final s = OperationState('type', template, result: '$index');
  return s;
}

SequenceState seq(List<State> states) {
  return SequenceState(states);
}

void testChoice() {
  test('ChoiceState', () {
    final s0 = seq([
      s(1),
      seq([s(2), s(3)]),
      s(4),
      alt('type', [s(5), s(6)])
    ]);

    final allocator = Allocator();
    final s1 = functionBody('int', s0, '{{0}}', 'null');
    s1.generate(allocator.allocate);
    final source = s0.source;

    const expected = r'''
    if (v == 1) {
      if (v == 2) {
        if (v == 3) {
          if (v == 4) {
            if (v == 5) {
              return 5;
            }
            if (v == 6) {
              return 6;
            }
          }
        }
      }
    }
    return null;
    ''';
    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('void'));
  });
}

void testSequence() {
  test('SequenceState', () {
    final s0 = seq([
      s(1),
      seq([
        s(2),
        alt('int', [s(3), s(4)])
      ]),
      alt('int', [s(5), s(6)])
    ]);

    final allocator = Allocator();
    final s1 = functionBody('int', s0, '{{0}}', 'null');
    s1.generate(allocator.allocate);
    final source = s0.source;

    const expected = r'''
    if (v == 1) {
      var $tmp = false;
      if (v == 2) {
        if (v == 3) {
          $tmp = true;
        }
        if (v == 4) {
          $tmp = true;
        }
      }
      if ($tmp) {
        if (v == 5) {
          return 5;
        }
        if (v == 6) {
          return 6;
        }
      }
    }
    return null;
''';
    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('void'));
  });
}

String _compact(String string) {
  string = string.replaceAll(' ', '');
  string = string.replaceAll('\n', '');
  return string;
}
