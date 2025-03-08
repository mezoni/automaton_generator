import 'automaton.dart';
import 'automaton_generator.dart';
import 'helper.dart';
import 'state.dart';

State automaton(
  String type,
  State state,
  String template, {
  String? accept,
  String placeholder = '{{@state}}',
  String? reject,
  String result = 'null',
  Map<String, String> values = const {},
}) {
  final automaton = Automaton(
    accept: accept,
    reject: reject,
    result: result,
    template: template,
  );
  final generator = AutomatonGenerator(automaton);
  final start = generator.generate(type, state, values: values);
  return start;
}

State block(State state) {
  final type = state.type;
  if (type.trim() == 'void') {
    const template = '''
final {{tmp}} = false;
{{@state}}
if ({{tmp}}) {
  {{@accept}}
}
{{@reject}}
''';
    const automaton = Automaton(
      accept: '{{tmp}} = true;',
      template: template,
    );
    const generator = AutomatonGenerator(automaton);
    final start = generator.generate(type, state);
    return start;
  } else {
    const template = '''
var ({{type}})? {{tmp}};
{{@state}}
if ({{tmp}} != null) {
  {{@accept}}
}
{{@reject}}
''';
    const automaton = Automaton(
      accept: '{{tmp}} = ({{0}},);',
      result: '{{tmp}}.\$1',
      template: template,
    );
    const generator = AutomatonGenerator(automaton);
    final start = generator.generate(type, state, values: {'type': type});
    return start;
  }
}

State functionBody(
    String type, State state, String acceptResult, String rejectResult) {
  const template = '''
{{@state}}
''';

  final automaton = Automaton(
    accept: 'return $acceptResult;',
    reject: 'return $rejectResult;',
    template: template,
  );

  final generator = AutomatonGenerator(automaton);
  final start = generator.generate(type, state);
  return start;
}

State many(State state) {
  const template = '''
final {{list}} = <{{type}}>[];
while (true) {
  {{@state}}
}
{{@accept}}
''';
  const automaton = Automaton(
    accept: '{{list}}.add({{0}});\ncontinue;',
    reject: 'break;',
    result: '{{list}}',
    template: template,
  );
  final elementType = state.type;
  final type = 'List<$elementType>';
  const generator = AutomatonGenerator(automaton);
  final start = generator.generate(type, state, values: {'type': elementType});
  return start;
}

State many1(State state) {
  const template = '''
final {{list}} = <{{type}}>[];
while (true) {
  {{@state}}
}
if ({{list}}).isNotEmpty {
  {{@accept}}
}
{{@reject}}
''';
  const automaton = Automaton(
    accept: '{{list}}.add({{0}});\ncontinue;',
    reject: 'break;',
    result: '{{list}}',
    template: template,
  );
  final elementType = state.type;
  final type = 'List<$elementType>';
  const generator = AutomatonGenerator(automaton);
  final start = generator.generate(type, state, values: {'type': elementType});
  return start;
}

State map(String type, State state, String expression) {
  state.listenToAcceptors((acceptor, allocate) {
    var result = expression;
    if (state is SequenceState) {
      final states = state.states;
      for (var i = 0; i < states.length; i++) {
        final state = states[i];
        result = result.replaceAll('{{$i}}', state.result);
      }
    } else {
      result = result.replaceAll('{{0}}', acceptor.result);
    }

    final v = allocate('v');
    final acceptance = '''
final $v = $result;
{{@accept}}''';
    acceptor.renderAcceptance(acceptance);
    acceptor.result = v;
    state.type = type;
  });

  return state;
}

State mux(State state) {
  final type = state.type.trim();
  if (type == 'void') {
    const template = '''
var {{tmp}} = false;
{{@state}}
if ({{tmp}}) {
  {{@accept}}
}
{{@reject}}
''';
    const automaton = Automaton(
      accept: '{{tmp}} = true;',
      reject: '',
      result: 'null',
      template: template,
    );
    const generator = AutomatonGenerator(automaton);
    final start = generator.generate(type, state);
    return start;
  } else {
    const template = '''
({{type}},)? {{tmp}};
{{@state}}
if ({{tmp}}) {
  {{@accept}}
}
{{@reject}}
''';
    const automaton = Automaton(
      accept: '{{tmp}} = ({{0}},);',
      reject: '',
      result: '{{tmp}}.\$1',
      template: template,
    );
    const generator = AutomatonGenerator(automaton);
    final start = generator.generate(type, state, values: {'type': type});
    return start;
  }
}

State optional(State state) {
  final type = getNullableType(state.type);
  final optional = ChoiceState(type, [state, value(type, 'null')]);
  return optional;
}

State procedureBody(String type, State state) {
  const template = '''
{{@state}}
''';

  final automaton = Automaton(
    accept: 'return;',
    template: template,
  );

  final generator = AutomatonGenerator(automaton);
  final start = generator.generate(type, state);
  return start;
}

State recognize(
  State state, {
  required String position,
  required String substring,
}) {
  const template = '''
final {{pos}} = {{position}};
var {{tmp}} = false;
{{@state}}
if ({{tmp}}) {
  final {{res}} = {{substring}}({{pos}}, {{position}});
  {{@accept}}
}
{{@reject}}
''';
  const automaton = Automaton(
    accept: '{{tmp}} = true;',
    reject: '',
    result: '{{res}}',
    template: template,
  );
  const generator = AutomatonGenerator(automaton);
  final start = generator.generate('String', state, values: {
    'position': position,
    'substring': substring,
  });
  return start;
}

State skipMany(State state) {
  const template = '''
while (true) {
  {{@state}}
}
{{@accept}}
''';
  const automaton = Automaton(
    accept: 'continue;',
    reject: 'break;',
    result: 'null',
    template: template,
  );
  const generator = AutomatonGenerator(automaton);
  final start = generator.generate('void', state);
  return start;
}

State skipMany1(State state) {
  const template = '''
var {{tmp}} = false;
while (true) {
  {{@state}}
}
if ({{tmp}}) {
  {{@accept}}
}
{{@reject}}
''';
  const automaton = Automaton(
    accept: '{{tmp}} = true;\ncontinue;',
    reject: 'break;',
    result: 'null',
    template: template,
  );
  const generator = AutomatonGenerator(automaton);
  final start = generator.generate('void', state);
  return start;
}

State value(String type, String value) {
  const template = '''
{{@accept}}
''';
  final state = OperationState(type, template, result: value);
  return state;
}
