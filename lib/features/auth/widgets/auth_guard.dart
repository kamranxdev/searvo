import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

/// Authentication guard widget
/// Redirects to auth screen if user is not authenticated
class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAuth;

  const AuthGuard({
    super.key,
    required this.child,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        // If auth is not required, show child
        if (!requireAuth) {
          return child;
        }

        // Wait for auth to initialize
        if (!authService.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        if (!authService.isAuthenticated) {
          // Redirect to auth screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/auth');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is authenticated, show child
        return child;
      },
    );
  }
}
