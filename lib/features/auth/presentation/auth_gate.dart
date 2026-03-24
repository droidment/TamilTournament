import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../dashboard/presentation/dashboard_page.dart';
import 'sign_in_page.dart';

final class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late User? _user;
  late bool _resolvedInitialState;
  StreamSubscription<User?>? _subscription;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _resolvedInitialState = _user != null;
    _subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) {
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      setState(() {
        _resolvedInitialState = true;
        _user = user ?? currentUser;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolvedInitialState) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const SignInPage();
    }

    return const DashboardPage();
  }
}
