import 'oauth2_provider.dart';

class Google extends OAuth2Provider {
  Google({
    required super.clientId,
    super.clientSecret,
    required super.redirectUri,
    required super.scopes,
  }) : super(
        authEndpoint: "https://www.dropbox.com/oauth2/authorize",
        tokenEndpoint: "https://api.dropboxapi.com/oauth2/token",
       );
}