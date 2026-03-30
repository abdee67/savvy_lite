import 'dart:io';

void main() {
  final dir = Directory('lib');
  final libFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  int totalReplacements = 0;

  for (final file in libFiles) {
    if (file.path.contains('database_service.dart') ||
        file.path.contains('base_repo.dart') ||
        file.path.contains('db_helper.dart') ||
        file.path.contains('sync_repository.dart') ||
        file.path.contains('sync_service.dart')) {
      continue;
    }

    String content = file.readAsStringSync();
    bool modified = false;

    // We want to wrap the second argument of db.insert
    // db.insert('table', map) -> db.insert('table', withSyncKey(map))
    // We can use a simple regex if the second argument is just a variable or method call without trailing weirdness.
    // Or we can just find 'db.insert(' and manually find comma and parenthesis matching.

    int cursor = 0;
    StringBuffer newContent = StringBuffer();

    while (true) {
      int idx = content.indexOf('db.insert(', cursor);
      if (idx == -1) {
        newContent.write(content.substring(cursor));
        break;
      }

      int startArgs = idx + 'db.insert('.length;
      newContent.write(content.substring(cursor, startArgs));

      // Find first comma (separates table name and payload)
      int nextComma = -1;
      int parens = 0;
      int quotes = 0;
      for (int i = startArgs; i < content.length; i++) {
        if (content[i] == "'" || content[i] == '"') {
             quotes++; 
        }
        if (quotes % 2 == 0) {
           if (content[i] == '(') parens++;
           if (content[i] == ')') parens--;
           if (content[i] == ',' && parens == 0) {
             nextComma = i;
             break;
           }
        }
      }

      if (nextComma != -1) {
        newContent.write(content.substring(startArgs, nextComma + 1)); // write up to comma (and the comma)
        
        // Find the second argument (the map)
        // It's from nextComma+1 until the next top-level comma or the end of the db.insert() statement.
        int endArg = -1;
        parens = 0;
        quotes = 0;
        int braces = 0;
        for (int i = nextComma + 1; i < content.length; i++) {
          if (content[i] == "'" || content[i] == '"') quotes++;
          if (quotes % 2 == 0) {
            if (content[i] == '(') parens++;
            if (content[i] == ')') parens--;
            if (content[i] == '{') braces++;
            if (content[i] == '}') braces--;

            if ((content[i] == ',' || content[i] == ')') && parens <= 0 && braces == 0) {
              endArg = i;
              break;
            }
          }
        }

        if (endArg != -1) {
          String argStr = content.substring(nextComma + 1, endArg);
          
          if (!argStr.contains('withSyncKey')) {
             newContent.write(' withSyncKey(');
             // strip leading space
             newContent.write(argStr.trimLeft());
             newContent.write(')');
             newContent.write(content.substring(endArg, endArg + 1)); // add the trailing comma or paren
             cursor = endArg + 1;
             modified = true;
             totalReplacements++;
          } else {
             newContent.write(argStr);
             newContent.write(content[endArg]);
             cursor = endArg + 1;
          }
        } else {
          cursor = startArgs;
        }

      } else {
        cursor = startArgs;
      }
    }

    if (modified) {
      file.writeAsStringSync(newContent.toString());
      print('Modified   ${file.path}');
    }
  }

  print('Total db.insert replacements made: \$totalReplacements');
}
