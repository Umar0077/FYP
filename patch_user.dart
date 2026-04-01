import 'dart:io';

void main() {
  final file = File('lib/views/admin/admin_user_management_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("title: const Text('User Management')", "title: const Text('User Practice Stats')");
  file.writeAsStringSync(content);
}
