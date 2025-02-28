import 'dart:convert';

import 'allocator.dart';

class Renderer {
  const Renderer();

  String render(
      String template, Map<String, Object> values, Allocator allocator) {
    values = {...values};
    final re = RegExp(r'{{([_a-zA-Z][_a-zA-Z0-9]*)}}');
    var keys = re.allMatches(template).map((m) => m[1]!).toSet().toList();
    keys.remove('accept');
    keys.remove('reject');
    for (final key in keys) {
      if (!values.containsKey(key)) {
        values[key] = allocator.allocate(key);
      }
    }

    keys.sort();
    keys = keys.reversed.toList();
    for (final key in keys) {
      final value = values[key]!;
      template = template.replaceAll('{{$key}}', '$value');
    }

    final buffer = StringBuffer();
    final lines = const LineSplitter().convert(template);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        continue;
      }

      if (i < lines.length - 1) {
        buffer.writeln(line);
      } else {
        buffer.write(line);
      }
    }

    return buffer.toString();
  }
}
