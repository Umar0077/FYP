import 'dart:io';

void main() async {
  final file = File('lib/views/widgets/AppScaffold.dart');
  var content = await file.readAsString();
  
  if (!content.contains('this.actions,')) {
    content = content.replaceFirst('this.resizeToAvoidBottomInset,', 'this.resizeToAvoidBottomInset,\n\t\tthis.actions,');
  }
  if (!content.contains('final List<Widget>? actions;')) {
    content = content.replaceFirst('final bool? resizeToAvoidBottomInset;', 'final bool? resizeToAvoidBottomInset;\n\tfinal List<Widget>? actions;');
  }
  
  content = content.replaceFirst('title: appBarTitle != null ? Text(appBarTitle!) : null,', 'title: appBarTitle != null ? Text(appBarTitle!) : null,\n\t\t\t\t\t\t\tactions: actions,');
  
  await file.writeAsString(content);
  print('AppScaffold patched!');
}