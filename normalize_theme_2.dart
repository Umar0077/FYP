import 'dart:io';

void main() {
  final dir = Directory('lib/views/admin');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  for (var file in files) {
    var content = file.readAsStringSync();
    
    // Fix Card radius to 16
    content = content.replaceAll('BorderRadius.circular(12)', 'BorderRadius.circular(16)');
    
    // Fix Padding to 16/20/24 standards
    // Just ensuring we use standard text colors. 
    // We already aligned color to 0xFF0B0F4E. Let's align primary/secondary text.
    // The previous generation had "color: isDark ? Colors.white70 : Colors.black87"
    content = content.replaceAll('Colors.black87', 'const Color(0xFF0A0F2E)');
    content = content.replaceAll('Colors.black54', 'const Color(0xFF27308A)');
    
    file.writeAsStringSync(content);
  }
}
