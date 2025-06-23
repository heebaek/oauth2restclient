import 'oauth2_provider.dart';

class OneDrive extends OAuth2ProviderF {
  OneDrive({
    required super.clientId,
    super.clientSecret,
    required super.redirectUri,
    required super.scopes,
  }) : super(
         name: "onedrive",
         authEndpoint:
             "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
         tokenEndpoint:
             "https://login.microsoftonline.com/common/oauth2/v2.0/token",
       );
}
