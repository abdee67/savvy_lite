import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

/// Centralized Supabase initialization and configuration service
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Get the Supabase client instance
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  /// Initialize Supabase with environment variables
  /// Call this in main.dart before runApp()
  static Future<void> initialize() async {
    if (_client != null) {
      developer.log('Supabase already initialized');
      return;
    }

    try {
      // Ensure dotenv is loaded first
      await dotenv.load(fileName: '.env');

      final projectUrl = dotenv.env['PROJECT_URL'];
      final anonKey = dotenv.env['ANON_KEY'];

      if (projectUrl == null || projectUrl.isEmpty) {
        throw Exception('PROJECT_URL not found in .env file');
      }
      if (anonKey == null || anonKey.isEmpty) {
        throw Exception('ANON_KEY not found in .env file');
      }

      await Supabase.initialize(
        url: projectUrl,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        debug: false,
      );

      _client = Supabase.instance.client;
      developer.log('Supabase initialized successfully');
    } catch (e) {
      developer.log('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Get the current Supabase auth instance
  GoTrueClient get auth => client.auth;
}
