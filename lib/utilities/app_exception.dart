class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

String friendlyError(Object error) => error is AppException
    ? error.message
    : 'Das hat leider nicht geklappt. Deine gespeicherten Erinnerungen bleiben erhalten. Bitte versuche es erneut.';
