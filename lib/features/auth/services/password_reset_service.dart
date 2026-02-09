import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/core/services/supabase/supabase_service.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling password reset operations using Supabase
class PasswordResetService {
  final LocalDatabaseService databaseService;

  PasswordResetService({required this.databaseService});

  /// Deep link redirect URL for password reset
  static const String redirectUrl = 'savvylite://reset-password';

  /// Send password reset code (OTP) via Supabase
  /// Returns true if code was sent successfully
  Future<PasswordResetResult> sendPasswordResetCode(String email) async {
    try {
      // First, check if the email exists in local database
      final userExists = await _checkEmailExists(email);
      if (!userExists) {
        return PasswordResetResult(
          success: false,
          message: 'No account found with this email address',
          errorType: PasswordResetErrorType.emailNotFound,
        );
      }

      // Ensure user exists in Supabase (Lazy Registration)
      try {
        final randomPassword = _generateRandomPassword();
        await SupabaseService.instance.auth.signUp(
          email: email,
          password: randomPassword,
        );
        developer.log('User lazily registered in Supabase: $email');
      } on AuthException catch (e) {
        if (!e.message.contains('already registered') &&
            !e.message.contains('User already exists')) {
          developer.log('Supabase sign up warning: ${e.message}');
        }
      } on SocketException {
        return PasswordResetResult(
          success: false,
          message:
              'No internet connection. Please check your network and try again.',
          errorType: PasswordResetErrorType.networkError,
        );
      } on http.ClientException {
        return PasswordResetResult(
          success: false,
          message:
              'No internet connection. Please check your network and try again.',
          errorType: PasswordResetErrorType.networkError,
        );
      }

      // Send password reset code (email)
      // We use resetPasswordForEmail effectively triggering the recovery flow
      await SupabaseService.instance.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl, // Optional redirect URL
      );

      developer.log('Password reset code sent to: $email');

      return PasswordResetResult(
        success: true,
        message: 'Password reset code sent successfully',
      );
    } on AuthException catch (e) {
      developer.log('Supabase auth error: ${e.message}');

      // Parse the error message for user-friendly responses
      final errorMessage = e.message.toLowerCase();
      String userFriendlyMessage;

      if (errorMessage.contains('error sending') ||
          errorMessage.contains('unexpected_failure') ||
          errorMessage.contains('recovery email')) {
        // Email service issue - likely rate limit or SMTP config
        userFriendlyMessage =
            'Unable to send reset email at this time. Please wait a few minutes and try again, or contact support if the issue persists.';
      } else if (errorMessage.contains('rate limit') ||
          errorMessage.contains('too many requests')) {
        userFriendlyMessage =
            'Too many reset attempts. Please wait a few minutes before trying again.';
      } else if (errorMessage.contains('invalid email') ||
          errorMessage.contains('email not found')) {
        userFriendlyMessage = 'Please check your email address and try again.';
      } else if (errorMessage.contains('user not found')) {
        userFriendlyMessage = 'No account found with this email address.';
      } else {
        // Generic fallback with the original message
        userFriendlyMessage =
            'Unable to send reset email. Please try again later.';
      }

      return PasswordResetResult(
        success: false,
        message: userFriendlyMessage,
        errorType: PasswordResetErrorType.supabaseError,
      );
    } on SocketException {
      developer.log('Network error: No internet connection');
      return PasswordResetResult(
        success: false,
        message:
            'No internet connection. Please check your network and try again.',
        errorType: PasswordResetErrorType.networkError,
      );
    } on http.ClientException catch (e) {
      developer.log('Network error (ClientException): $e');
      return PasswordResetResult(
        success: false,
        message:
            'No internet connection. Please check your network and try again.',
        errorType: PasswordResetErrorType.networkError,
      );
    } catch (e) {
      developer.log('Failed to send password reset code: $e');
      // Check if it's a network-related error in the message
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('socket') ||
          errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('clientexception') ||
          errorMessage.contains('failed host lookup')) {
        return PasswordResetResult(
          success: false,
          message:
              'No internet connection. Please check your network and try again.',
          errorType: PasswordResetErrorType.networkError,
        );
      }
      return PasswordResetResult(
        success: false,
        message: 'Failed to send reset code. Please try again.',
        errorType: PasswordResetErrorType.unknown,
      );
    }
  }

  /// Verify the 8-digit OTP code
  Future<PasswordResetResult> verifyOTP({
    required String email,
    required String code,
  }) async {
    try {
      final response = await SupabaseService.instance.auth.verifyOTP(
        token: code,
        type: OtpType.recovery, // Use recovery for password reset flow
        email: email,
      );

      if (response.session == null) {
        return PasswordResetResult(
          success: false,
          message: 'Invalid code or verification failed',
          errorType: PasswordResetErrorType.invalidToken,
        );
      }

      developer.log('OTP verified successfully for: $email');

      return PasswordResetResult(
        success: true,
        message: 'Code verified successfully',
        email: email,
      );
    } on AuthException catch (e) {
      developer.log('OTP verification error: ${e.message}');
      return PasswordResetResult(
        success: false,
        message: e.message,
        errorType: PasswordResetErrorType.invalidToken,
      );
    } catch (e) {
      developer.log('Failed to verify OTP: $e');
      return PasswordResetResult(
        success: false,
        message: 'Failed to verify code. Please check and try again.',
        errorType: PasswordResetErrorType.unknown,
      );
    }
  }

  String _generateRandomPassword() {
    return '${DateTime.now().millisecondsSinceEpoch}SavvyLite${1000 + (DateTime.now().microsecond % 8999)}';
  }

  /// Check if email exists in local database
  Future<bool> _checkEmailExists(String email) async {
    try {
      final db = await databaseService.database;
      final result = await db.query(
        'user_table',
        where: 'user_email = ? AND status = ?',
        whereArgs: [email.toLowerCase().trim(), 'active'],
      );
      return result.isNotEmpty;
    } catch (e) {
      developer.log('Error checking email existence: $e');
      return false;
    }
  }

  /// Get user by email from local database
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final db = await databaseService.database;
      final result = await db.query(
        'user_table',
        where: 'user_email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );

      if (result.isEmpty) return null;
      return UserModel.fromMap(result.first);
    } catch (e) {
      developer.log('Error getting user by email: $e');
      return null;
    }
  }

  /// Update password in local database after Supabase verification
  Future<PasswordResetResult> updateLocalPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Hash the new password using SHA256 (same as auth_bloc)
      final hashedPassword = await UserModel.sha256Hash(newPassword);

      final db = await databaseService.database;

      // Update the password in the local database
      final updateCount = await db.update(
        'user_table',
        {
          'password': hashedPassword,
          'password_last_updated': DateTime.now().millisecondsSinceEpoch,
          'date_updated': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'user_email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );

      if (updateCount == 0) {
        return PasswordResetResult(
          success: false,
          message: 'No account found with this email address',
          errorType: PasswordResetErrorType.emailNotFound,
        );
      }

      developer.log('Password updated successfully for: $email');

      return PasswordResetResult(
        success: true,
        message: 'Password has been reset successfully',
      );
    } catch (e) {
      developer.log('Failed to update password: $e');
      return PasswordResetResult(
        success: false,
        message: 'Failed to update password. Please try again.',
        errorType: PasswordResetErrorType.databaseError,
      );
    }
  }

  Future<bool> isPasswordUsedBefore(String password) async {
    final db = await databaseService.database;
    final hashedPassword = await UserModel.sha256Hash(password);
    final result = await db.query(
      'user_table',
      where: 'password = ?',
      whereArgs: [hashedPassword],
    );
    return result.isNotEmpty;
  }

  /// Verify the access token from Supabase deep link
  /// This exchanges the recovery token for a session
  Future<PasswordResetResult> verifyRecoveryToken(String accessToken) async {
    try {
      // Set the session using the access token from the recovery link
      final response = await SupabaseService.instance.auth.setSession(
        accessToken,
      );

      if (response.user == null) {
        return PasswordResetResult(
          success: false,
          message: 'Invalid or expired reset link',
          errorType: PasswordResetErrorType.invalidToken,
        );
      }

      final email = response.user!.email;
      if (email == null || email.isEmpty) {
        return PasswordResetResult(
          success: false,
          message: 'Could not retrieve email from reset token',
          errorType: PasswordResetErrorType.invalidToken,
        );
      }

      developer.log('Recovery token verified for: $email');

      return PasswordResetResult(
        success: true,
        message: 'Token verified successfully',
        email: email,
      );
    } on AuthException catch (e) {
      developer.log('Token verification error: ${e.message}');
      return PasswordResetResult(
        success: false,
        message: e.message,
        errorType: PasswordResetErrorType.invalidToken,
      );
    } catch (e) {
      developer.log('Failed to verify recovery token: $e');
      return PasswordResetResult(
        success: false,
        message: 'Failed to verify reset link. Please request a new one.',
        errorType: PasswordResetErrorType.unknown,
      );
    }
  }

  /// Exchange the recovery code for a session (PKCE flow)
  Future<PasswordResetResult> exchangeRecoveryCode(String code) async {
    try {
      final response = await SupabaseService.instance.auth
          .exchangeCodeForSession(code);

      final email = response.session.user.email;
      if (email == null || email.isEmpty) {
        return PasswordResetResult(
          success: false,
          message: 'Could not retrieve email from reset code',
          errorType: PasswordResetErrorType.invalidToken,
        );
      }

      developer.log('Recovery code exchanged for: $email');

      return PasswordResetResult(
        success: true,
        message: 'Code verified successfully',
        email: email,
      );
    } on AuthException catch (e) {
      developer.log('Code exchange error: ${e.message}');
      return PasswordResetResult(
        success: false,
        message: e.message,
        errorType: PasswordResetErrorType.invalidToken,
      );
    } catch (e) {
      developer.log('Failed to exchange recovery code: $e');
      return PasswordResetResult(
        success: false,
        message: 'Failed to verify reset code. Please request a new one.',
        errorType: PasswordResetErrorType.unknown,
      );
    }
  }
}

/// Result class for password reset operations
class PasswordResetResult {
  final bool success;
  final String message;
  final PasswordResetErrorType? errorType;
  final String? email;

  PasswordResetResult({
    required this.success,
    required this.message,
    this.errorType,
    this.email,
  });
}

/// Error types for password reset operations
enum PasswordResetErrorType {
  emailNotFound,
  invalidToken,
  tokenExpired,
  supabaseError,
  databaseError,
  networkError,
  passwordUsedBefore,
  unknown,
}
