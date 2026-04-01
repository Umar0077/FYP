import 'dart:io';

void main() {
  final file = File('lib/views/admin/admin_login_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(RegExp(r"if \(_emailController\.text == '' &&\s*_passwordController\.text == ''\)"), "if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty)");
  file.writeAsStringSync(content);
}
