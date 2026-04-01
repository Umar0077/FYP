import 'dart:io';

void main() async {
  final adminDir = Directory('lib/views/admin');
  if (!adminDir.existsSync()) {
    print('admin dir not found');
    return;
  }

  for (var file in adminDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = await file.readAsString();
      bool modified = false;

      // Rule 1: Replace generic dashboard text
      if (content.contains('Nova Prep') || content.contains('novaprep')) {
        content = content.replaceAll(RegExp(r'(?i)nova(\s|_)?prep'), 'AI Interview Assistant Coach');
        modified = true;
      }
      
      if (content.contains('Scaffold(') && !content.contains('AppScaffold(')) {
          // just standardizing background color for Scaffold to match AppScaffold
          content = content.replaceAll('Scaffold(', '''Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF00002E) : Colors.white,''');
          modified = true;
      }
      
      if (modified) {
        await file.writeAsString(content);
        print('Updated: \${file.path}');
      }
    }
  }
}