import 'package:flutter/material.dart';
import 'package:flutter_app/components/top_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_app/supabase.dart';

class DevLogin extends StatelessWidget {
  const DevLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: signInWithTestUser,
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

  Future<void> signInWithTestUser() async {
    try {
      await supabase.auth
          .signUp(email: 'test@test.com', password: 'testtesttest');
    } catch (_) {
      await supabase.auth
          .signInWithPassword(email: 'test@test.com', password: 'testtesttest');
    }
  }
}
