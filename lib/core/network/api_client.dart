import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/state/auth_state.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  bool isRefreshing = false;
  Completer<Map<String, dynamic>>? refreshCompleter;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        print("🚀 [Request] ${options.method} → ${options.path}");

        final authStore = ref.read(authStoreProvider.notifier);
        final token = authStore.accessToken;

        // Skip auth for specific endpoints
        const authExcludedPaths = [
          '/auth/login',
          '/auth/forgot-password',
          '/auth/verify-otp',
          '/auth/reset-password',
          '/auth/refresh-token',
          '/student/',
        ];

        if (authExcludedPaths.any((path) => options.path.endsWith(path))) {
          return handler.next(options);
        }

        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }

        handler.next(options);
      },
      onError: (DioException error, handler) async {
        final requestOptions = error.requestOptions;

        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        final authStore = ref.read(authStoreProvider.notifier);
        final refreshToken = await authStore.getRefreshToken();

        if (refreshToken == null) {
          print("⚠️ No refresh token → logging out");
          await authStore.setLogOut();
          return handler.reject(error);
        }

        // If a refresh is already in progress, wait for it
        if (isRefreshing) {
          try {
            final refreshResult = await refreshCompleter!.future;
            if (refreshResult['status'] == 'success') {
              final newToken = refreshResult['data']['access_token'];
              requestOptions.headers["Authorization"] = "Bearer $newToken";
              final clonedResponse = await dio.fetch(requestOptions);
              return handler.resolve(clonedResponse);
            } else {
              throw Exception('Token refresh failed');
            }
          } catch (e) {
            return handler.reject(error);
          }
        }

        // Start refresh process
        isRefreshing = true;
        refreshCompleter = Completer<Map<String, dynamic>>();

        try {
          final refreshResult = await authStore.refreshAccessToken();

          if (refreshResult['status'] == 'success') {
            final newAccessToken = refreshResult['data']['access_token'];

            // Complete the refresh completer so others waiting get the token
            refreshCompleter!.complete(refreshResult);

            // Retry the failed request with new token
            requestOptions.headers["Authorization"] = "Bearer $newAccessToken";
            final retryResponse = await dio.fetch(requestOptions);
            handler.resolve(retryResponse);
          } else {
            throw Exception(
              refreshResult['message'] ?? 'Failed to refresh token',
            );
          }
        } catch (refreshError) {
          print("🚨 Token refresh failed: $refreshError");
          refreshCompleter!.completeError(refreshError);
          await authStore.setLogOut();
          handler.reject(error);
        } finally {
          isRefreshing = false;
          refreshCompleter = null; // reset completer
        }
      },
    ),
  );

  return dio;
});
