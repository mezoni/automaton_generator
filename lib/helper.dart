String escapeString(String text, [String? quote = '\'']) {
  if (quote != null && !((quote != '\'') || quote != '"')) {
    throw ArgumentError.value(quote, 'quote', 'Unknown quote');
  }

  text = text.replaceAll('\\', r'\\');
  text = text.replaceAll('\b', r'\b');
  text = text.replaceAll('\f', r'\f');
  text = text.replaceAll('\n', r'\n');
  text = text.replaceAll('\r', r'\r');
  text = text.replaceAll('\t', r'\t');
  text = text.replaceAll('\v', r'\v');
  text = text.replaceAll('\$', r'\$');
  if (quote == '\'') {
    text = text.replaceAll('\'', '\\\'');
  } else {
    text = text.replaceAll('"', "\\\"");
  }

  if (quote == null) {
    return text;
  }

  return '$quote$text$quote';
}

String getNullableType(String type) {
  if (type.trim().endsWith('?')) {
    return type;
  }

  switch (type) {
    case 'Null':
    case 'dynamic':
    case 'void':
      return type;
    default:
      return '$type?';
  }
}
