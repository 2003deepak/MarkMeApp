import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/core/utils/app_logger.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  bool isRefreshing = false;
  int refreshAttemptCount = 0;
  Completer<Map<String, dynamic>>? refreshCompleter;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        AppLogger.info("🚀 [Request] ${options.method} → ${options.path}");

        final authStore = ref.read(authStoreProvider.notifier);
        final token = authStore.accessToken;

        // print("The value of token in dio provider = $token");

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
          AppLogger.warning("⚠️ No refresh token → logging out");
          await authStore.setLogOut();
          return handler.reject(error);
        }

        // Prevent parallel refreshes
        if (isRefreshing) {
          try {
            final refreshResult = await refreshCompleter!.future;
            if (refreshResult['success'] == true) {
              final newToken = refreshResult['data']['access_token'];
              requestOptions.headers["Authorization"] = "Bearer $newToken";
              final clonedResponse = await dio.fetch(requestOptions);
              return handler.resolve(clonedResponse);
            } else {
              throw Exception('Token refresh failed while waiting');
            }
          } catch (e) {
            AppLogger.error("🚨 Waiting request failed to refresh: $e");
            return handler.reject(error);
          }
        }

        // Begin refresh flow
        isRefreshing = true;
        refreshCompleter = Completer<Map<String, dynamic>>();
        refreshAttemptCount = 0;

        while (refreshAttemptCount < 2) {
          refreshAttemptCount++;
          AppLogger.info(
            "🔁 Attempt #$refreshAttemptCount to refresh token...",
          );

          try {
            final refreshResult = await authStore.refreshAccessToken();

            if (refreshResult['success'] == true) {
              final newAccessToken = refreshResult['data']['access_token'];
              AppLogger.info(
                "✅ Token refresh succeeded on attempt #$refreshAttemptCount",
              );

              refreshCompleter!.complete(refreshResult);
              requestOptions.headers["Authorization"] =
                  "Bearer $newAccessToken";
              final retryResponse = await dio.fetch(requestOptions);
              handler.resolve(retryResponse);
              break; // ✅ Exit loop after success
            } else {
              AppLogger.warning(
                "⚠️ Token refresh attempt #$refreshAttemptCount failed: ${refreshResult['message']}",
              );
            }
          } catch (refreshError) {
            AppLogger.error(
              "🚨 Exception during token refresh (attempt #$refreshAttemptCount): $refreshError",
            );
          }

          // Wait small delay before retry (optional)
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // If both attempts failed
        if (!refreshCompleter!.isCompleted) {
          AppLogger.error(
            "❌ Both token refresh attempts failed → logging out & rejecting request",
          );
          refreshCompleter!.completeError(
            'Token refresh failed after 2 attempts',
          );
          await authStore.setLogOut();
          handler.reject(error);
        }

        isRefreshing = false;
        refreshCompleter = null;
      },
    ),
  );

  return dio;
});
