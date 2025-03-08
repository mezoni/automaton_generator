import 'acceptor_collector.dart';
import 'automaton.dart';
import 'renderer.dart';
import 'state.dart';

class AutomatonGenerator {
  final Automaton automaton;

  const AutomatonGenerator(this.automaton);

  State generate(
    String type,
    State state, {
    Map<String, String> values = const {},
  }) {
    final start = OperationState(
      type,
      automaton.template,
      result: automaton.result,
      values: values,
    );

    start.listen((allocate) {
      final collector = AcceptorCollector();
      final lastAcceptor = collector.collect(state).last;
      state.listenToAcceptors((acceptor, allocate) {
        final renderedValues = {
          ...start.renderedValues,
          ...acceptor.renderedValues,
        };

        final branchResult = automaton.branchResult;
        if (branchResult != null) {
          acceptor.result = branchResult.render(
            renderedValues,
            allocate,
            {},
          );
        }

        String? acceptance;
        final accept = automaton.accept;
        if (accept != null) {
          acceptance = accept.render(renderedValues, allocate, {});
          acceptance = acceptance.replaceAll('{{0}}', acceptor.result);
        }

        if (acceptor != lastAcceptor) {
          acceptor.renderAcceptance(acceptance);
        } else {
          final hasAccept = acceptor.source.contains(State.acceptPlaceholder);
          if (hasAccept) {
            acceptor.renderAcceptance(acceptance);
          }
        }
      });
      state.generate(allocate);
      state.renderRejection(automaton.reject);
      start.source =
          start.source.replaceAll(automaton.placeholder, state.source);
    });
    return start;
  }
}
