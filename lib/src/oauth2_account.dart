

import 'dart:io';

import 'oauth2_login.dart';
import 'oauth2_provider.dart';
import 'oauth2_token.dart';
import 'oauth2_token_storage.dart';

class OAuth2Account 
{
  final Map<String, OAuth2Provider> _providers = {};
  late final OAuth2Login _login;
  late final OAuth2TokenStorage _tokenStorage;

  OAuth2Account({OAuth2Login? login, OAuth2TokenStorage? tokenStorage})
  {
    _login = login ?? OAuth2LoginF();

    if (Platform.isAndroid || Platform.isIOS)
    {
      _tokenStorage = tokenStorage ?? OAuth2TokenStorageSecure();
    }
    else
    {
      _tokenStorage = tokenStorage ?? OAuth2TokenStorageShared();
    }
  }

  void addProvider(String service, OAuth2Provider provider)
  {
    _providers[service] = provider;
  }

  static const tokenPrefix = "OAUTH2ACCOUNT102"; // ✅ OAuth 키를 구별하기 위한 접두사 추가

  String keyFor(String service, String userName) => "$tokenPrefix-$service-$userName";

  Future<void> saveAccount(String service, String userName, OAuth2Token token) async
  {
    var key = keyFor(service, userName);
    var value = token.toJsonString();
    _tokenStorage.save(key, value);
  }

  Future<OAuth2Token?> newAccount(String service) async
  {
    var provider = _providers[service];
    if (provider == null) throw Exception("Provider not found for service: $service");
    var token = await _login.login(provider);
    if (token != null)
    {
      await saveAccount(service, token.userName, token);
    } 
    return token;
  }

  Future<List<(String, String)>> allAccounts({String service = ""}) async 
  {
    final all = await _tokenStorage.loadAll(keyPrefix:tokenPrefix);

    return all.keys
        .map((key) {
          final parts = key.split("-");
          return (parts[1], parts[2]); // (serviceName, account)
        })
        .where((tuple) => service.isEmpty || tuple.$1.contains(service)) // ✅ 필터링 추가
        .toList();
  }

  Future<OAuth2Token?> loadAccount(String service, String userName) async
  {
    var key = keyFor(service, userName);
    var jsonString = await _tokenStorage.load(key);
    if (jsonString == null) return null;
    return OAuth2Token.fromJsonString(jsonString);
  }

  Future<void> deleteAccount(String service, String userName) async
  {
    var key = keyFor(service, userName);
    await _tokenStorage.delete(key);
  }

  Future<OAuth2Token?> any({String service = ""}) async 
  {
    var all = await allAccounts(service: service);
    if (all.isEmpty) return null;
    var first = all.first;
    return loadAccount(first.$1, first.$2);
  }
}
