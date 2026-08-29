import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/profile_service.dart';
import '../../navigation/main_navigation.dart';
import 'login_screen.dart';
import 'update_password_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;

  Session? _session;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();

    _session = Supabase.instance.client.auth.currentSession;

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint('AUTH EVENT: ${data.event}');
        debugPrint('AUTH SESSION EXISTS: ${data.session != null}');

        if (!mounted) return;

       setState(() {
  _session = data.session;

  if (data.event == AuthChangeEvent.passwordRecovery) {
    _isPasswordRecovery = true;
  }

  if (data.event == AuthChangeEvent.userUpdated) {
    _isPasswordRecovery = false;
  }
});

if (data.event == AuthChangeEvent.passwordRecovery) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  });
}
      },
      onError: (Object error) {
        debugPrint('Authentication stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPasswordRecovery) {
      return const UpdatePasswordScreen();
    }

    if (_session == null) {
      return const LoginScreen();
    }

    return FutureBuilder<void>(
      future: ProfileService().ensureProfileExists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your profile.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const MainNavigation();
      },
    );
  }
}