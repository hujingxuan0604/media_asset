import 'dart:io';

class LocalFileRevealService {
  const LocalFileRevealService();

  Future<void> reveal(String path) async {
    if (Platform.isWindows) {
      await _run('explorer', ['/select,', path]);
      return;
    }

    if (Platform.isMacOS) {
      await _run('open', ['-R', path]);
      return;
    }

    if (Platform.isLinux) {
      await _run('xdg-open', [File(path).parent.path]);
      return;
    }

    throw UnsupportedError('Unsupported desktop platform');
  }

  Future<void> _run(String executable, List<String> arguments) async {
    final result = await Process.run(executable, arguments);
    if (result.exitCode == 0) {
      return;
    }

    throw ProcessException(
      executable,
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }
}
