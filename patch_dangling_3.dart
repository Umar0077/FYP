import 'dart:io';

void main() async {
  final dir = Directory('lib/views/admin');
  if (!dir.existsSync()) return;

  for (var file in dir.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    String content = await file.readAsString();
    bool changed = false;

    // clean up my terrible $1 injection
    if (content.contains(r'$1),\n      child:')) {
       // it was previously broken.
       // example: padding: const $1),\n      child: Column(
       // Actually wait, if the source code was destroyed and replaced with `$1`, the original value is GONE!
       // Oh God. In `admin_login_screen.dart`, it was `padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)` replaced by `$1)`. The original value is lost.
    }
  }
}
