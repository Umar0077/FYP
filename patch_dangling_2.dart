import 'dart:io';

void main() async {
  final dir = Directory('lib/views/admin');
  if (!dir.existsSync()) return;

  for (var file in dir.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    String content = await file.readAsString();
    bool changed = false;

    // Fix trailing `)` that got eaten.
    // e.g. padding: const EdgeInsets.all(16\n      child: -> padding: const EdgeInsets.all(16),\n      child:
    // Actually, let's just look for any number/word passing straight to `\n      child:`
    // Example: margin: const EdgeInsets.only(bottom: 12\n      child: ListTile(
    final rx = RegExp(r'(\d+|[a-zA-Z_]+|\]|\))\s*\n\s*child:');
    
    // Wait, let's carefully restore.
    // I know that `EdgeInsets.all(16` is missing `),`
    content = content.replaceAll(RegExp(r'EdgeInsets\.all\(([\d.]+)\s*\n\s*child:'), r'EdgeInsets.all($1),\n      child:');
    
    // margin: const EdgeInsets.only(bottom: 12\n
    content = content.replaceAll(RegExp(r'EdgeInsets\.only\(([^)]+)\s*\n\s*child:'), r'EdgeInsets.only($1),\n      child:');
    
    // Navigator.pop(context\n      child:
    content = content.replaceAll(RegExp(r'Navigator\.pop\(context\s*\n\s*child:'), r'Navigator.pop(context),\n      child:');

    // And other places missing `),`
    // Wait, if it missed `),` it was because I stripped it. Let's look for `\n      child:` right after something that is unbalanced.
    // It's safer to just do: if the previous non-whitespace character is a number/letter/context, add `),`.
    // Let's just fix it by evaluating `flutter analyze` line by line?
    
    // Let me find all "child:" preceded by unbalanced parentheses? 
    // The previous regex was `\s*\),\s*child:` became `\n      child:`.
    // Meaning I literally deleted `),` before `child:`!
    // So anywhere `\n      child:` occurs now, I should replace it with `),\n      child:`?
    // NO, because valid `child:` like `Column(\n      child:` would become `Column(), child:`.
    // Wait, `),` means it was the END of an argument list. So things like `padding: EdgeInsets.all(16),`
    
    // Let's replace ONLY where I'm 100% sure the syntax requires `),`.
    // If it's `padding: EdgeInsets.all(16`, it clearly needs `),`
    content = content.replaceAll(RegExp(r'(EdgeInsets(?:Geometry)?\.[a-zA-Z]+\([^)]+)\n\s+child:'), r'$1),\n      child:');
    
    content = content.replaceAll(RegExp(r'(Navigator.pop\([^\)]+)\n\s+child:'), r'$1),\n      child:');

    // let's look at `GlassCard(` args. If there's `margin: const EdgeInsets.only(...)`
    
    if (content != file.readAsStringSync()) {
      changed = true;
    }

    if (changed) {
      await file.writeAsString(content);
      print('Fixed braces in: \${file.path}');
    }
  }
}
