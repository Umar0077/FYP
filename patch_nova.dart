import 'dart:io';

void main() {
  final file = File('lib/views/admin/admin_activity_logs_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("admin@nova.com", "admin@email.com");
  file.writeAsStringSync(content);
}
