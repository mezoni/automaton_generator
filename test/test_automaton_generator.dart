import 'package:automaton_generator/allocator.dart';
import 'package:automaton_generator/extra.dart';
import 'package:automaton_generator/state.dart';
import 'package:test/test.dart';

void main() {
  testFunctionBody();
  testMany();
  testMany1();
  testMap();
  testMux();
  testRecognize();
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
  final s = OperationState(
    'int',
    template,
    result: '$index',
  );
  return s;
}

SequenceState seq(List<State> states) {
  return SequenceState(states);
}

void testFunctionBody() {
  test('function body', () {
    final s1 = alt('int', [
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = functionBody('int', s1, '{{0}}', 'null');
    s0.generate(Allocator().allocate);
    final source = s0.source;

    const expected = r'''
if (v == 1) {
  return 1;
}
 if (v == 2) {
  return 2;
}
 if (v == 3) {
  return 3;
}
 return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('int'));
  });

  test('map sequence', () {
    final s1 = seq([
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = map('String', s1, '"{{0}}{{1}}{{2}}"');
    _generateFunctionBody(s0);
    final source = s0.source;

    print(source);

    const expected = r'''
if (v == 1) {
  if (v == 2) {
  if (v == 3) {
  final $v = "123";
return $v;
}
}
}
return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('String'));
  });
}

void testMany() {
  test('many', () {
    final s1 = alt('int', [
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = many(s1);
    _generateFunctionBody(s0);
    final source = s0.source;

    const expected = r'''
final $list = <int>[];
while (true) {
  if (v == 1) {
  $list.add(1);
continue;
}
 if (v == 2) {
  $list.add(2);
continue;
}
 if (v == 3) {
  $list.add(3);
continue;
}
 break;

}
return $list
;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('List<int>'));
  });
}

void testMany1() {
  {
    test('many1', () {
      final s1 = alt('int', [
        s(1),
        s(2),
        s(3),
      ]);

      final s0 = many1(s1);
      _generateFunctionBody(s0);
      final source = s0.source;

      const expected = r'''
final $list = <int>[];
while (true) {
  if (v == 1) {
  $list.add(1);
continue;
}
 if (v == 2) {
  $list.add(2);
continue;
}
 if (v == 3) {
  $list.add(3);
continue;
}
 break;

}
if ($list).isNotEmpty {
  return $list
;
}
return null;
''';

      expect(_compact(source), _compact(expected));
      expect(_compact(s0.type), _compact('List<int>'));
    });
  }

  test('many1(recognize)', () {
    final s1 = alt('int', [
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = many1(recognize(
      s1,
      position: 'position',
      substring: 'substring',
    ));
    _generateFunctionBody(s0);
    final source = s0.source;

    const expected = r'''
final $list = <String>[];
while (true) {
  final $pos = position;
var $tmp = false;
if (v == 1) {
  $tmp = true;
}
 if (v == 2) {
  $tmp = true;
}
 if (v == 3) {
  $tmp = true;
}


if ($tmp) {
  final $res = substring($pos, position);
  $list.add($res
);
continue;

}
break;

}
if ($list).isNotEmpty {
  return $list
;
}
return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('List<String>'));
  });
}

void testMap() {
  test('map choice', () {
    final s1 = alt('int', [
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = map('String', s1, '"{{0}}"');
    _generateFunctionBody(s0);
    final source = s0.source;

    const expected = r'''
if (v == 1) {
  final $v = "1";
return $v;
}
 if (v == 2) {
  final $v1 = "2";
return $v1;
}
 if (v == 3) {
  final $v2 = "3";
return $v2;
}
 return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('String'));
  });

  test('map sequence', () {
    final s1 = seq([
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = map('String', s1, '"{{0}}{{1}}{{2}}"');
    _generateFunctionBody(s0);
    final source = s0.source;

    const expected = r'''
if (v == 1) {
  if (v == 2) {
  if (v == 3) {
  final $v = "123";
return $v;
}
}
}
return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('String'));
  });
}

void testMux() {
  test('mux (int)', () {
    final s1 = alt('int', [
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = mux(s1);
    _generateFunctionBody(s0);
    final source = s0.source;

    const expected = r'''
(int,)? $tmp = false;
if (v == 1) {
  $tmp = (1,);
}
 if (v == 2) {
  $tmp = (2,);
}
 if (v == 3) {
  $tmp = (3,);
}


if ($tmp) {
  return $tmp.$1
;
}
return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('int'));
  });

  test('mux (void)', () {
    final s1 = alt('void', [
      s(1),
      s(2),
      s(3),
    ]);

    final s0 = mux(s1);
    _generateFunctionBody(s0);
    final source = s0.source;

    const expected = r'''
var $tmp = false;
if (v == 1) {
  $tmp = true;
}
 if (v == 2) {
  $tmp = true;
}
 if (v == 3) {
  $tmp = true;
}


if ($tmp) {
  return null
;
}
return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('void'));
  });
}

void testRecognize() {
  test('recognize', () {
    final s1 = alt('int', [
      s(1),
      s(2),
      s(3),
    ]);

    final s0 =
        recognize(s1, position: 'position', substring: 'input.substring');
    _generateFunctionBody(s0);
    final source = s0.source;

    const expected = r'''
final $pos = position;
var $tmp = false;
if (v == 1) {
  $tmp = true;
}
 if (v == 2) {
  $tmp = true;
}
 if (v == 3) {
  $tmp = true;
}

if ($tmp) {
  final $res = input.substring($pos, position);
  return $res;
}
return null;
''';

    expect(_compact(source), _compact(expected));
    expect(_compact(s0.type), _compact('String'));
  });
}

String _compact(String string) {
  string = string.replaceAll(' ', '');
  string = string.replaceAll('\n', '');
  return string;
}

void _generateFunctionBody(State start) {
  final allocator = Allocator();
  final s0 = functionBody('int', start, '{{0}}', 'null');
  s0.generate(allocator.allocate);
}
