import 'dart:io';

void main() {
  final file = File('lib/views/admin/admin_login_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "if (_emailController.text == '' &&\n        _passwordController.text == '')",
    "if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty)"
  );
  content = content.replaceAll("hintText: '',", "hintText: 'admin@email.com',");
  file.writeAsStringSync(content);
}
