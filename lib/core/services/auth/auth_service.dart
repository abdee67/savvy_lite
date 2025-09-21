import 'package:flutter/foundation.dart';
import 'package:savvy_stock/core/models/company.dart';
import 'package:savvy_stock/features/auth/models/user_model.dart';

class AuthService with ChangeNotifier {
  UserModel? _currentUser;
  Company? _currentCompany;

  // Fake IDs for testing
  static const int fakeCompanyId = 999;
  static const int fakeUserId = 888;

  AuthService() {
    _setupFakeAuth();
  }

  UserModel? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  bool get isAuthenticated => true; // Always authenticated
  String? get authToken => 'fake-auth-token-for-testing';

  void _setupFakeAuth() {
    // Create fake company
    _currentCompany = Company(
      id: fakeCompanyId,
      companyName: 'Test Company Ltd.',
      tinNumber: 'TEST123456',
      phoneNumber1: '+251911223344',
      emailAddress1: 'test@company.com',
    );

    // Create fake user
    _currentUser = UserModel(
      id: fakeUserId,
      userName: 'testuser',
      userEmail: 'testuser@company.com',
      company: _currentCompany,
      superUser: '1', // Super user for full access
      status: 'Active',
      password: 'password',
    );

    if (kDebugMode) {
      print('FAKE AUTH: User ${_currentUser?.userName} authenticated');
      print('FAKE AUTH: Company ${_currentCompany?.companyName} loaded');
    }
  }

  // Mock login - always succeeds instantly
  Future<UserModel> login(String email, String password) async {
    return _currentUser!;
  }

  // Mock logout - does nothing for testing
  Future<void> logout() async {
    if (kDebugMode) {
      print('FAKE AUTH: Logout called (ignored for testing)');
    }
  }

  Future<String> getAuthToken() async {
    return 'fake-auth-token-for-testing';
  }
}
