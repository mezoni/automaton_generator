import 'dart:convert';

import 'allocator.dart';

class Renderer {
  final Allocate allocate;

  Renderer(this.allocate);

  String render(
    String template,
    Map<String, String> values,
    Map<String, String> renderedValues,
  ) {
    values = {...values};
    final re = RegExp(r'{{([_a-zA-Z][_a-zA-Z0-9]*)}}');
    var keys = re.allMatches(template).map((m) => m[1]!).toSet().toList();
    for (final key in keys) {
      if (!values.containsKey(key)) {
        values[key] = allocate(key);
      }
    }

    keys.sort();
    keys = keys.reversed.toList();
    for (final key in keys) {
      final value = values[key]!;
      renderedValues[key] = value;
      template = template.replaceAll('{{$key}}', value);
    }

    template = const LineSplitter()
        .convert(template)
        .map((e) => e.trim().isEmpty ? '' : '$e\n')
        .join();
    return template;
  }
}

extension StringRendererExt on String {
  String render(
    Map<String, String> values,
    Allocate allocate,
    Map<String, String> renderedValues,
  ) {
    return Renderer(allocate).render(this, values, renderedValues);
  }
}
