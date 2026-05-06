import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const oauthProvider = String.fromEnvironment(
    'SUPABASE_OAUTH_PROVIDER',
    defaultValue: 'google',
  );
  static const redirectUrl = String.fromEnvironment('SUPABASE_REDIRECT_URL');
  static const persistSsoSession = bool.fromEnvironment(
    'SUPABASE_PERSIST_SESSION',
    defaultValue: false,
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static String? get effectiveRedirectUrl {
    if (redirectUrl.isNotEmpty) return redirectUrl;
    if (kIsWeb) return '${Uri.base.origin}/login';
    return null;
  }

  static OAuthProvider get provider {
    switch (oauthProvider.toLowerCase()) {
      case 'azure':
      case 'microsoft':
      case 'entra':
        return OAuthProvider.azure;
      case 'google':
      default:
        return OAuthProvider.google;
    }
  }

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: persistSsoSession ? null : const EmptyLocalStorage(),
      ),
    );
  }
}
