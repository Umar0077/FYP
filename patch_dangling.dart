import 'dart:io';

void main() async {
  final dir = Directory('lib/views/admin');
  if (!dir.existsSync()) return;

  for (var file in dir.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    String content = await file.readAsString();
    bool changed = false;

    // clean up the orphaned )), that became ), or )
    if (content.contains('),')) {
       // match margin: ... \n ), \n child:
       content = content.replaceAll(RegExp(r'\s*\),\s*child:'), '\n      child:');
       content = content.replaceAll(RegExp(r'margin:\s*([^,]+),\s*\),\s*child:'), r'margin: $1,\n      child:');
       
       // also my card regex messed up the names
       // I replaced Card( with GlassCard( globally!
       // So `class _SummaryCard` became `class _SummaryGlassCard` !
       content = content.replaceAll('_SummaryGlassCard', '_SummaryCard');
       content = content.replaceAll('GlassCard(', 'GlassCard(');
       // Wait, AdminUserManagementScreen uses GlassCard instead of Card.
       
       changed = true;
    }
    
    // fix import if any duplicated
    if (changed) {
      await file.writeAsString(content);
      print('Fixed braces in: \${file.path}');
    }
  }
}
