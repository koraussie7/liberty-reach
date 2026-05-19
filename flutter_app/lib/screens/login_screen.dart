/// Social Login Screen
///
/// Shows buttons for Kakao, Apple, Google, Facebook login.
/// Each button triggers the respective social SDK, then exchanges
/// the ID token with our backend.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo / Title ──
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.blueAccent, size: 44),
                ),
                const SizedBox(height: 24),
                const Text(
                  'DADA-AI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with your social account',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 48),

                // ── Error ──
                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // ── Loading ──
                if (auth.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),

                // ── Kakao ──
                _SocialButton(
                  label: 'Continue with Kakao',
                  icon: Icons.chat_bubble,
                  color: const Color(0xFFFEE500),
                  textColor: Colors.black,
                  onPressed: auth.isLoading
                      ? null
                      : () => _onKakaoLogin(context),
                ),
                const SizedBox(height: 12),

                // ── Apple ──
                _SocialButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  color: Colors.white,
                  textColor: Colors.black,
                  onPressed: auth.isLoading
                      ? null
                      : () => _onAppleLogin(context),
                ),
                const SizedBox(height: 12),

                // ── Google ──
                _SocialButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  color: Colors.white,
                  textColor: Colors.black87,
                  onPressed: auth.isLoading
                      ? null
                      : () => _onGoogleLogin(context),
                ),
                const SizedBox(height: 12),

                // ── Facebook ──
                _SocialButton(
                  label: 'Continue with Facebook',
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  textColor: Colors.white,
                  onPressed: auth.isLoading
                      ? null
                      : () => _onFacebookLogin(context),
                ),

                const SizedBox(height: 32),

                // ── Skip ──
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Social login handlers ──────────────────────────────────────────

  Future<void> _onKakaoLogin(BuildContext context) async {
    // TODO: Integrate Kakao SDK
    // 1. flutter_kakao_login → access token
    // 2. Send to backend via auth.loginWithToken()
    _showPlaceholder(context, 'Kakao SDK not yet integrated');
  }

  Future<void> _onAppleLogin(BuildContext context) async {
    // TODO: Integrate Sign in with Apple
    // 1. sign_in_with_apple → identity token
    // 2. Send to backend via auth.loginWithToken()
    _showPlaceholder(context, 'Apple SDK not yet integrated');
  }

  Future<void> _onGoogleLogin(BuildContext context) async {
    // TODO: Integrate Google Sign-In
    // 1. google_sign_in → authentication
    // 2. Firebase Auth → credential
    // 3. Send ID token to backend
    _showPlaceholder(context, 'Google SDK not yet integrated');
  }

  Future<void> _onFacebookLogin(BuildContext context) async {
    // TODO: Integrate Facebook Login
    // 1. flutter_facebook_auth → access token
    // 2. Firebase Auth → credential
    // 3. Send ID token to backend
    _showPlaceholder(context, 'Facebook SDK not yet integrated');
  }

  void _showPlaceholder(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}

// ── Social Button Widget ──────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.9),
          foregroundColor: textColor,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
