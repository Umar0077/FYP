import 'dart:io';

void main() async {
  final dir = Directory('lib/views/admin');
  if (!dir.existsSync()) return;

  for (var file in dir.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    String content = await file.readAsString();
    bool changed = false;

    if (content.contains('Card(') && !content.contains('GlassCard(')) {
        if (!content.contains("import '../widgets/GlassCard.dart';") && 
            !content.contains("import '../../views/widgets/GlassCard.dart';")) {
            content = content.replaceFirst("import 'package:flutter/material.dart';", 
                "import 'package:flutter/material.dart';\nimport '../../views/widgets/GlassCard.dart';");
        }
        
        content = content.replaceAll(RegExp(r'shape:\s*RoundedRectangleBorder\([^)]*\),?'), '');
        content = content.replaceAll(RegExp(r'color:\s*isDark\s*\?\s*const\s*Color\([^)]+\)\s*:\s*Colors.[a-zA-Z]+,?'), '');
        content = content.replaceAll(RegExp(r'color:\s*isDark\s*\?\s*Colors.[a-zA-Z]+\s*:\s*Colors.[a-zA-Z]+,?'), '');
        content = content.replaceAll(RegExp(r'color:\s*Theme[^\)]+\)\)\s*:\s*Colors.[a-zA-Z]+,?'), '');
        content = content.replaceAll(RegExp(r'elevation:\s*\d+,?'), '');
        
        content = content.replaceAll('Card(', 'GlassCard(');
        changed = true;
    }

    if (content.contains('Scaffold(')) {
       if (!content.contains('backgroundColor:')) {
           content = content.replaceFirst('Scaffold(', '''Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF00002E) : Colors.white,''');
           changed = true;
       }
    }

    if (changed) {
      await file.writeAsString(content);
      print('Polished: \${file.path}');
    }
  }
}
