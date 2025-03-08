class Automaton {
  final String? accept;

  final String? branchResult;

  final String placeholder;

  final String? reject;

  final String result;

  final String template;

  const Automaton({
    this.accept,
    this.branchResult,
    this.placeholder = '{{@state}}',
    this.reject,
    this.result = 'null',
    required this.template,
  });
}
