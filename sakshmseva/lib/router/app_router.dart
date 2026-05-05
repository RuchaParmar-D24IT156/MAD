import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/auth_provider.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/aadhaar_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/schemes/presentation/schemes_list_screen.dart';
import '../features/schemes/presentation/scheme_detail_screen.dart';
import '../features/eligibility/presentation/eligibility_checker_screen.dart';
import '../features/saved/presentation/saved_schemes_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/document_vault_screen.dart';
import '../features/profile/presentation/personal_info_screen.dart';
import '../features/profile/presentation/application_history_screen.dart';
import '../features/chatbot/presentation/chatbot_screen.dart';
import '../shared/widgets/scaffold_with_bottom_nav.dart';

/// Route name constants – use these for programmatic navigation
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const schemes = '/schemes';
  static const schemeDetail = '/schemes/:id';
  static const eligibility = '/eligibility';
  static const saved = '/saved';
  static const chatbot = '/chatbot';
  static const profile = '/profile';
  static const documentVault = '/document-vault';
  static const aadhaar = '/aadhaar';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // If we are still waiting for the initial auth state, don't redirect yet
      return authState.when(
        loading: () => null,
        error: (_, __) => AppRoutes.login,
        data: (user) {
          final isLoggingIn = state.uri.toString() == AppRoutes.login || 
                              state.uri.toString() == AppRoutes.signup ||
                              state.uri.toString() == AppRoutes.forgotPassword;
          final isSplash = state.uri.toString() == AppRoutes.splash;

          if (user == null) {
            // Unauthenticated users can only see splash, login, signup, forgot password
            if (isSplash || isLoggingIn) {
              return null;
            }
            return AppRoutes.login;
          } else {
            // Authenticated users shouldn't see login screens
            // Check if Aadhaar is missing
            return userAsync.when(
              data: (userModel) {
                if (userModel == null) return null; // Still loading or missing doc
                final missingAadhaar = userModel.aadhaarNumber?.isEmpty ?? true;
                final isAadhaarScreen = state.uri.toString() == AppRoutes.aadhaar;
                
                if (missingAadhaar && !isAadhaarScreen) {
                  return AppRoutes.aadhaar;
                } else if (!missingAadhaar && isAadhaarScreen) {
                  return AppRoutes.home;
                }

                if (isLoggingIn || isSplash) {
                  return missingAadhaar ? AppRoutes.aadhaar : AppRoutes.home;
                }
                return null;
              },
              loading: () => null, // Wait for user data to load
              error: (_, __) => AppRoutes.login,
            );
          }
        },
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.aadhaar,
        builder: (context, state) => const AadhaarScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.documentVault,
        builder: (context, state) => const DocumentVaultScreen(),
      ),
      GoRoute(
        path: '/profile/info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profile/history',
        builder: (context, state) => const ApplicationHistoryScreen(),
      ),
      // Shell route for bottom nav
      ShellRoute(
        builder: (context, state, child) =>
            ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.schemes,
            builder: (context, state) => const SchemesListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => SchemeDetailScreen(
                  schemeId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.eligibility,
            builder: (context, state) => const EligibilityCheckerScreen(),
          ),
          GoRoute(
            path: AppRoutes.saved,
            builder: (context, state) => const SavedSchemesScreen(),
          ),
          GoRoute(
            path: AppRoutes.chatbot,
            builder: (context, state) => const ChatbotScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
