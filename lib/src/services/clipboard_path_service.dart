import 'package:flutter/services.dart';

class ClipboardPathService {
  const ClipboardPathService();

  Future<void> copyPaths(Iterable<String> paths) {
    return Clipboard.setData(ClipboardData(text: paths.join('\n')));
  }
}
