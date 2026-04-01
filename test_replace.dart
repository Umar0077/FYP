import 'dart:io';

void main() {
  var replacements = {
    'Nova Prep': 'AI Interview Assistant Coach',
    'novaprep.com': 'example.com',
    'admin@novaprep.com': 'admin@example.com',
    'admin123': 'password123',
    'NovaPrep': 'AI Interview Coach',
    'admin@novaprep.com / admin123': 'valid credentials',
    'Invalid admin credentials. Use admin@novaprep.com / admin123': 'Invalid admin credentials.',
    'admin@example.com / password123': 'valid credentials',
    'admin@example.com': '',
    'password123': ''
  };

  var dirs = ['lib/views/admin', 'lib/models/admin', 'lib/controllers/admin'];
  
  for (var d in dirs) {
    var dir = Directory(d);
    if (!dir.existsSync()) continue;
    var files = dir.listSync(recursive: true);
    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.dart')) {
        var content = entity.readAsStringSync();
        var newContent = content;
        replacements.forEach((k, v) {
          newContent = newContent.replaceAll(k, v);
        });
        if (newContent != content) {
          entity.writeAsStringSync(newContent);
          print('Updated ' + entity.path);
        }
      }
    }
  }
}
