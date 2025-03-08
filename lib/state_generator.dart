import 'dart:convert';

import 'allocator.dart';
import 'extra.dart';
import 'renderer.dart';
import 'state.dart';
import 'warning.dart';

class StateGenerator implements StateVisitor<void> {
  final Allocate allocate;

  final Renderer _renderer;

  StateGenerator({
    required this.allocate,
  }) : _renderer = Renderer(allocate);

  String generate(State state) {
    state.accept(this);
    return state.source;
  }

  @override
  void visitChoice(ChoiceState node) {
    final children = node.states;
    node.source = State.rejectPlaceholder;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      child.accept(this);
      if (i < children.length - 1) {
        if (!_canReject(child)) {
          warning('''
The 'Choice' state element #$i does not define a 'rejection' placeholder
State element #$i source:
 ${child.source}''');
        }
      }

      node.renderRejection(child.source);
    }

    node.source = _removeEmptyLines(node.source);
    _notify(node);
  }

  @override
  void visitOperation(OperationState node) {
    node.renderedValues = {};
    node.source = _render(node.template, node.values, node.renderedValues);
    node.result = _render(node.result, node.renderedValues, {}).trim();
    node.source = _removeEmptyLines(node.source);
    _notify(node);
  }

  @override
  void visitSequence(SequenceState node) {
    final children = node.states.toList();
    var canReject = false;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      State? surrogate;
      if (i < children.length - 1) {
        if (!child.hasSingleOutput) {
          surrogate = mux(child);
        }
      }

      if (surrogate != null) {
        surrogate.accept(this);
        child.source = surrogate.source;
      } else {
        child.accept(this);
      }

      if (_canReject(child)) {
        canReject = true;
      }
    }

    final last = children.last;
    var source = last.source;
    source = source.replaceAll(State.rejectPlaceholder, '');
    last.source = source;
    for (var i = children.length - 2; i >= 0; i--) {
      final child = children[i];
      if (!_canAccept(child)) {
        warning('''
The 'Sequence' state element #$i does not define an 'acceptance' placeholder.
State element #$i source:
${child.source}''');
      }

      child.renderAcceptance(source);
      child.source = child.source.replaceAll(State.rejectPlaceholder, '');
      source = child.source;
    }

    if (canReject) {
      source = '''
$source
${State.rejectPlaceholder}''';
    }

    node.source = _removeEmptyLines(source);
    _notify(node);
  }

  bool _canAccept(State node) => node.source.contains(State.acceptPlaceholder);

  bool _canReject(State node) => node.source.contains(State.rejectPlaceholder);

  void _notify(State node) {
    final listeners = node.listeners;
    for (final listener in listeners) {
      listener(allocate);
    }
  }

  String _removeEmptyLines(String source) {
    return source = const LineSplitter()
        .convert(source)
        .map((e) => e.trim().isEmpty ? '' : '$e\n')
        .join();
  }

  String _render(
    String template,
    Map<String, String> values,
    Map<String, String> renderedValues,
  ) {
    return _renderer.render(template, values, renderedValues);
  }
}
