import 'dart:io';

void main() {
  updateImportsInDirectory('lib/screens');
  updateImportsInDirectory('lib/widgets');
  print('Import statements updated successfully!');
}

void updateImportsInDirectory(String dirPath) {
  final dir = Directory(dirPath);
  final files = dir
      .listSync(recursive: true)
      .where((file) => file.path.endsWith('.dart'))
      .cast<File>();

  for (final file in files) {
    updateImportsInFile(file);
  }
}

void updateImportsInFile(File file) {
  String content = file.readAsStringSync();

  // Update widget imports
  content = content.replaceAll('../widgets/variable_cost_widget.dart',
      '../widgets/hpp/variable_cost_widget.dart');

  content = content.replaceAll('../widgets/fixed_cost_widget.dart',
      '../widgets/hpp/fixed_cost_widget.dart');

  // Add more replacements as needed...

  file.writeAsStringSync(content);
}
