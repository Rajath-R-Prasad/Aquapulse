import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/api_client.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  return Supabase.instance.client.auth.currentSession;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;

  final dio = ref.watch(dioProvider);
  final response = await dio.get('/v1/me');
  final data = response.data;
  if (data is! Map<String, dynamic>) {
    throw const FormatException(
      'The server returned an invalid engineer profile.',
    );
  }
  return UserProfile.fromJson(data);
});

class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  void clearError() {
    state = const AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        state = AsyncValue.error(
          const ApiException(
            statusCode: 401,
            type: 'auth-failed',
            title: 'Sign in failed',
            detail: 'Incorrect email or password.',
          ),
          StackTrace.current,
        );
        return;
      }
      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      _setAuthError(e);
    } on DioException catch (e) {
      state = AsyncValue.error(extractApiException(e), StackTrace.current);
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(dioProvider)
          .post(
            '/v1/auth/signup',
            data: {
              'full_name': fullName.trim(),
              'email': email.trim(),
              'password': password,
            },
          );

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session == null) {
        state = AsyncValue.error(
          const ApiException(
            statusCode: 401,
            type: 'auth-failed',
            title: 'Sign in failed',
            detail:
                'Account created, but automatic sign-in failed. Sign in with your new credentials.',
          ),
          StackTrace.current,
        );
        return;
      }
      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      _setAuthError(e);
    } on DioException catch (e) {
      state = AsyncValue.error(extractApiException(e), StackTrace.current);
    }
  }

  void _setAuthError(AuthException error) {
    state = AsyncValue.error(
      ApiException(
        statusCode: error.statusCode != null
            ? int.tryParse(error.statusCode!) ?? 401
            : 401,
        type: 'auth-failed',
        title: 'Authentication failed',
        detail: error.message,
      ),
      StackTrace.current,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    ref.invalidate(userProfileProvider);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(
  AuthNotifier.new,
);
