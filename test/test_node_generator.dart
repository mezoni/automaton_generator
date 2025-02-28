import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/automaton.dart';
import 'package:automaton_generator/automaton_generator.dart';
import 'package:automaton_generator/node_generator.dart';
import 'package:test/test.dart';

void main() {
  _testAndThen();
  _testBlock();
  _testChoice();
  _testCode();
  _testSequence();
}

String _normalize(String string) {
  string = string.replaceAll(' ', '');
  string = string.replaceAll('\n', '');
  return string;
}

void _testAndThen() {
  test('andThen 1', () {
    final allocator = Allocator();
    final nodeGenerator = NodeGenerator(allocator);
    final s1 = nodeGenerator.code('''
if (v == 1) {
  {{accept}}
}
{{reject}}''', result: '1');
    final s2 = nodeGenerator.code('''
if (v == 2) {
  {{accept}}
}
{{reject}}''', result: '2');
    nodeGenerator.andThen(s1, s2);
    final automaton = Automaton(
      accept: 'return {{result}};',
      reject: '',
      start: s1,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );
    final code = automatonGenerator.generate();
    print(code);
    const original = r'''
if (v == 1) {
  if (v == 2) {
    return 2;
  }
}''';
    expect(_normalize(code), _normalize(original));
  });

  test('andThen 2', () {
    final allocator = Allocator();
    final nodeGenerator = NodeGenerator(allocator);
    final s1 = nodeGenerator.code('''
if (v == 1) {
  {{accept}}
}
{{reject}}''', result: '1');
    final s2 = nodeGenerator.code('''
if (v == 2) {
  {{accept}}
}
{{reject}}''', result: '2');
    final s3 = nodeGenerator.code('''
if (v == 3) {
  {{accept}}
}
{{reject}}''', result: '3');
    nodeGenerator.andThen(s1, s2);
    nodeGenerator.andThen(s2, s3);
    final automaton = Automaton(
      accept: 'return {{result}};',
      reject: '',
      start: s1,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );
    final code = automatonGenerator.generate();
    print(code);
    const original = r'''
if (v == 1) {
  if (v == 2) {
    if (v == 3) {
     return 3;
    }
  }
}''';
    expect(_normalize(code), _normalize(original));
  });
}

void _testBlock() {
  test('block', () {
    final allocator = Allocator();
    final nodeGenerator = NodeGenerator(allocator);
    const type = 'int';
    final s1 = nodeGenerator.code('''
if (v == 1) {
  {{accept}}
}
{{reject}}''', result: '1');
    final s2 = nodeGenerator.code('''
if (v == 2) {
  {{accept}}
}
{{reject}}''', result: '2');
    final s3 = nodeGenerator.or(s1, s2);
    final s4 = nodeGenerator.block(type, s3);
    final automaton = Automaton(
      accept: 'return {{result}};',
      reject: '',
      start: s4,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );
    final code = automatonGenerator.generate();
    const original = r'''
(int,)? $0;
  switch (0) {
    default:
      {
        if (v == 1) {
          $0 = (1,);
          break;
        }
      }
      if (v == 2) {
        $0 = (2,);
        break;
      }
      break;
  }
  if ($0 != null) {
    return $0.$1;
  }''';
    expect(_normalize(code), _normalize(original));
  });
}

void _testChoice() {
  test('choice 2', () {
    final allocator = Allocator();
    final nodeGenerator = NodeGenerator(allocator);
    final s1 = nodeGenerator.code('''
if (v == 1) {
  {{accept}}
}
{{reject}}''', result: '1');
    final s2 = nodeGenerator.code('''
if (v == 2) {
  {{accept}}
}
{{reject}}''', result: '2');
    final s3 = nodeGenerator.or(s1, s2);
    final automaton = Automaton(
      accept: 'return {{result}};',
      reject: '',
      start: s3,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );
    final code = automatonGenerator.generate();
    print(code);
    const original = r'''
{
  if (v == 1) {
    return 1;
  }
}
if (v == 2) {
  return 2;
}''';
    expect(_normalize(code), _normalize(original));
  });

  test('choice 3', () {
    final allocator = Allocator();
    final nodeGenerator = NodeGenerator(allocator);
    final s1 = nodeGenerator.code('''
if (v == 1) {
  {{accept}}
}
{{reject}}''', result: '1');
    final s2 = nodeGenerator.code('''
if (v == 2) {
  {{accept}}
}
{{reject}}''', result: '2');
    final s3 = nodeGenerator.code('''
if (v == 3) {
  {{accept}}
}
{{reject}}''', result: '3');
    final s4 = nodeGenerator.choice([s1, s2, s3]);
    final automaton = Automaton(
      accept: 'return {{result}};',
      reject: '',
      start: s4,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );
    final code = automatonGenerator.generate();

    const original = r'''
{
  if (v == 1) {
    return 1;
  }
}
{
  if (v == 2) {
    return 2;
  }
}
if (v == 3) {
  return 3;
}''';
    expect(_normalize(code), _normalize(original));
  });
}

void _testCode() {
  test('code', () {
    final allocator = Allocator();
    final nodeGenerator = NodeGenerator(allocator);
    final s1 = nodeGenerator.code('''
if (v == 1) {
  {{accept}}
}
{{reject}}''', result: '1');
    final automaton = Automaton(
      accept: 'return {{result}};',
      reject: '',
      start: s1,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );
    final code = automatonGenerator.generate();
    const original = r'''
if (v == 1) {
  return 1;
} ''';
    expect(_normalize(code), _normalize(original));
  });
}

void _testSequence() {
  test('sequence', () {
    final allocator = Allocator();
    final nodeGenerator = NodeGenerator(allocator);
    final s1 = nodeGenerator.code('''
if (v == 1) {
  {{accept}}
}
{{reject}}''', result: '1');
    final s2 = nodeGenerator.code('''
if (v == 2) {
  {{accept}}
}
{{reject}}''', result: '2');
    final s3 = nodeGenerator.code('''
if (v == 3) {
  {{accept}}
}
{{reject}}''', result: '3');
    final s4 = nodeGenerator.sequence([s1, s2, s3]);
    final automaton = Automaton(
      accept: 'return {{result}};',
      reject: '',
      start: s4,
    );

    final automatonGenerator = AutomatonGenerator(
      allocator: allocator,
      automaton: automaton,
    );
    final code = automatonGenerator.generate();
    const original = r'''
if (v == 1) {
  if (v == 2) {
    if (v == 3) {
      return 3;
   }
  }
} ''';
    expect(_normalize(code), _normalize(original));
  });
}
