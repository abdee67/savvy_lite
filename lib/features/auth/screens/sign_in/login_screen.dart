import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_event.dart';
import 'package:savvy_stock/features/auth/blocs/auth_state.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    // Delay initial auth check to avoid immediate loading state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AuthBloc>().add(const CheckAuthStatus());
      }
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter username and password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Unfocus to hide keyboard
    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      LoginRequested(username: username, password: password),
    );
  }

  void _handleSignUp() {
    if (mounted) {
      context.push(AppRoutes.signup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!mounted) return;
        if (state.status == AuthStatus.authenticated) {
          context.go(AppRoutes.homePage);
        }
        if (state.status == AuthStatus.failure && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final isSyncing = state.status == AuthStatus.initialSyncInProgress;
        final isInitialCheck =
            state.status == AuthStatus.loading &&
            state.message?.contains('Checking') == true;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                // Main content
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 70,
                      left: 50,
                      right: 50,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            kToolbarHeight -
                            200,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildLoginForm(state, isLoading),
                        ],
                      ),
                    ),
                  ),
                ),

                // Loading overlay for login action (not initial check)
                if (isLoading && !isInitialCheck) _buildLoadingOverlay(),

                // Full-screen blocking sync overlay
                if (isSyncing) _buildSyncOverlay(state),

                // Subtle indicator for initial auth check
                if (isLoading && isInitialCheck) _buildInitialCheckIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Welcome!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color.fromARGB(255, 21, 88, 136),
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'to your daily companion',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: const Color.fromARGB(255, 15, 90, 143),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthState state, bool isLoading) {
    return IgnorePointer(
      ignoring: isLoading,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            CustomTextField(
              controller: usernameController,
              labelText: 'Username',
              suffixIcon: const Icon(
                Icons.person,
                color: Color.fromARGB(255, 12, 71, 114),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Password',
              obscureText: _obscureText,
              controller: passwordController,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color.fromARGB(255, 12, 71, 114),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 12, 71, 114),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 4,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _buildForgotPasswordButton(isLoading),
            const SizedBox(height: 32),

            //if there is company in the device dont render sign up button
            if (!state.hasExistingCompany) _buildSignUpButton(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(bool isLoading) {
    return TextButton(
      onPressed: isLoading
          ? null
          : () {
              context.push(AppRoutes.forgotPassword);
            },
      style: TextButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 12, 71, 114),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: isLoading
                ? Colors.grey
                : const Color.fromARGB(255, 12, 71, 114),
            fontSize: 16,
          ),
          children: const [
            TextSpan(text: 'Forgot Password?'),
            TextSpan(
              text: ' Reset',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 12, 71, 114),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          'Sign Up',
          style: TextStyle(
            color: isLoading ? Colors.grey : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: 280,
          height: 180,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: SpinKitDoubleBounce(
                  size: 100,
                  color: const Color.fromARGB(255, 12, 71, 114),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Securing Your Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maintaining your data Please wait...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialCheckIndicator() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: SpinKitDoubleBounce(
                color: const Color.fromARGB(255, 12, 71, 114),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Checking session...',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-screen blocking overlay showing initial data sync progress.
  /// Cannot be dismissed — user must wait for sync to complete.
  Widget _buildSyncOverlay(AuthState state) {
    final progress = state.syncProgress ?? 0;
    final message = state.message ?? 'Setting up your data...';
    final syncTable = state.syncTable ?? '';

    return PopScope(
      canPop: false,
      child: Container(
        color: const Color(0xFF0C4772).withOpacity(0.95),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                SpinKitDoubleBounce(
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Setting Up Your Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Status message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Percentage text
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 8),

                // Current table being synced
                if (syncTable.isNotEmpty)
                  Text(
                    syncTable,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                const SizedBox(height: 24),

                // Warning text
                Text(
                  'Please do not close the app',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
