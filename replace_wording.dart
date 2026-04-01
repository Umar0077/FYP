import 'dart:io';

void main() {
  final dir = Directory('lib/views/admin');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  for (var file in files) {
    var content = file.readAsStringSync();
    
    content = content.replaceAll("'Interview Management'", "'Interview Sessions'");
    content = content.replaceAll("'Users'", "'User Practice Stats'");
    // Wait, replacing 'Users' might break some route or variable names if matched loosely. Let's do exact match.
    content = content.replaceAll("title: const Text('Users')", "title: const Text('User Practice Stats')");
    content = content.replaceAll("title: const Text('Interview Detail')", "title: const Text('Results Review')");
    
    file.writeAsStringSync(content);
  }
}
