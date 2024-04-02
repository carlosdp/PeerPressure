import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/components/top_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

final supabase = Supabase.instance.client;

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: signInWithApple,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.apple, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Sign in with Apple',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> signInWithApple() async {
    final rawNonce = supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
      webAuthenticationOptions: WebAuthenticationOptions(
        redirectUri: Uri.parse(
          'https://example.com/auth/callback',
        ),
        clientId: 'com.example.app',
      ),
    );

    final idToken = appleCredential.identityToken;

    if (idToken == null) {
      throw const AuthException(
          'Could not find token from generated credential');
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }
}
