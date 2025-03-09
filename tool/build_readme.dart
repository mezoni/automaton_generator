import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  var readme = File(r'tool\README.md').readAsStringSync();
  final dir = Directory('example');
  final List<FileSystemEntity> entities = dir.listSync().toList();
  for (final entity in entities) {
    final stat = entity.statSync();
    if (stat.type != FileSystemEntityType.file) {
      continue;
    }

    if (!entity.path.endsWith('.dart')) {
      continue;
    }

    final path = p.relative(entity.path).replaceAll(r'\', '/');
    final contents = File(entity.path).readAsStringSync();
    readme = readme.replaceAll('{{@$path}}', '''
[$path](https://github.com/mezoni/automaton_generator/tree/main/$path)

```dart
$contents
```''');
  }

  File(r'README.md').writeAsStringSync(readme);
}
