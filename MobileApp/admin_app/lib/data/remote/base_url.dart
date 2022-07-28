import '../../env_manager.dart';

Uri buildUrl(String unencodedPath, [Map<String, String>? queryParameters]) {
  String? url = EnvManager.shared.get(EnvKey.BASE_URL);
  return Uri.http(
    (url == null) ? "" : url,
    unencodedPath,
    queryParameters,
  );
}
