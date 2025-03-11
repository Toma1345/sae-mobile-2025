import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sae_mobile_2025/main.dart';
import 'package:sae_mobile_2025/pages/account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo:
          kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
      );
      if (mounted) {
        context.showSnackBar('Consultez dans vos mails, le lien de connexion !');

        _emailController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar("Une erreur inattendue s'est produite ...", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
        (data) {
          if (_redirecting) return;
          final session = data.session;
          if (session != null) {
            _redirecting = true;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AccountPage()
              ),
            );
          }
        },
      onError: (error) {
          if (error is AuthException) {
            context.showSnackBar(error.message, isError: true);
          } else {
            context.showSnackBar("Une erreur inattendue s'est produite ...", isError: true);
          }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connexion"),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text("Connectez-vous via le lien magique avec votre email ci-dessous"),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "Email"
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: Text(_isLoading ? "Envoi ..." : "Envoyer le lien Magique"),
          ),
        ],
      ),
    );
  }
}