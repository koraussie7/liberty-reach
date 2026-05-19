/// Authentication Service
///
/// Wraps Firebase Auth + social providers and exchanges tokens
/// with the DADA-AI backend.
///
/// Setup required before this works:
///   1. Firebase project → google-services.json / GoogleService-Info.plist
///   2. Kakao developer app → native app key
///   3. Apple developer account → Service ID + key
///   4. Google Cloud Console → OAuth client ID
///   5. Facebook Developer app → app ID
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Represents the authenticated user.
class AuthUser {
  final String uid;
  final String? email;
  final String? name;
  final String? picture;
  final String provider;
  final String accessToken;

  AuthUser({
    required this.uid,
    this.email,
    this.name,
    this.picture,
    required this.provider,
    required this.accessToken,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'picture': picture,
        'provider': provider,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json, String token) =>
      AuthUser(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        name: json['name'] as String?,
        picture: json['picture'] as String?,
        provider: json['provider'] as String? ?? 'unknown',
        accessToken: token,
      );
}

/// Service that handles all auth operations.
class AuthService extends ChangeNotifier {
  AuthUser? _user;
  bool _isLoading = false;
  String? _error;

  // Configure your server URL
  static const String _baseUrl = 'http://dada.privseai.com:8000';

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Register a new account with Vultisig wallet auto-creation
  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    String displayName = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'display_name': displayName,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _user = AuthUser(
          uid: data['user']['uid'] as String,
          email: data['user']['email'] as String?,
          name: data['user']['name'] as String?,
          provider: 'vultisig',
          accessToken: data['access_token'] as String,
        );
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        _error = body['detail'] as String? ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Check if user has a stored session (token in secure storage).
  Future<bool> tryRestoreSession() async {
    // TODO: Implement token persistence with flutter_secure_storage
    return false;
  }

  /// Social login — sends the provider ID token to our backend.
  Future<bool> loginWithToken({
    required String provider,
    required String idToken,
    String? accessToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'id_token': idToken,
          'access_token': accessToken,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _user = AuthUser.fromJson(
          data['user'] as Map<String, dynamic>,
          data['access_token'] as String,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed: ${resp.body}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with wallet address (no password, wallet = identity)
  Future<bool> walletLogin({
    required String walletAddress,
    String chain = 'ethereum',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/wallet-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet_address': walletAddress,
          'chain': chain,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _user = AuthUser(
          uid: data['user']['uid'] as String,
          name: data['user']['name'] as String?,
          provider: data['user']['provider'] as String? ?? 'wallet',
          accessToken: data['access_token'] as String,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Wallet login failed: ${resp.body}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  void logout() {
    _user = null;
    _error = null;
    notifyListeners();
  }
}
