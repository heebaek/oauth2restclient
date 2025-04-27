import 'oauth2_provider.dart';

class Google extends OAuth2Provider {
  Google({
    required super.clientId,
    super.clientSecret,
    required super.redirectUri,
    required super.scopes,
  }) : super(
         authEndpoint: "https://accounts.google.com/o/oauth2/auth",
         tokenEndpoint: "https://oauth2.googleapis.com/token",
       );
}
