import 'dart:io';

void main() {
  final dir = Directory('lib/views/admin');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  for (var file in files) {
    var content = file.readAsStringSync();
    
    // Normalize Colors
    content = content.replaceAll(
      'isDark ? const Color(0xFF1E1E3F) : Colors.white', 
      'isDark ? const Color(0xFF0B0F4E) : Colors.white'
    );
    content = content.replaceAll(
      'isDark ? const Color(0xFF1E1E3F) : const Color(0xFFF5F6FA)',
      'isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA)'
    );
    
    // Normalize generic words -> App-specific 
    // Example: "Admin Dashboard" -> "AI Interview Assistant Coach"
    content = content.replaceAll('Admin Dashboard', 'Admin Dashboard - AI Interview Assistant Coach');
    content = content.replaceAll('Admin Portal', 'AI Interview Assistant Coach - Admin');

    file.writeAsStringSync(content);
  }
}
