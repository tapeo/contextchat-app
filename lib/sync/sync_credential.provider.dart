import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final githubCredentialsProvider = Provider<GitHubCredentialsService>((ref) {
  return GitHubCredentialsService();
});

class GitHubCredentialsService {
  static const _tokenKey = 'github_token';
  final _secureStorage = const FlutterSecureStorage();

  Future<void> setToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
