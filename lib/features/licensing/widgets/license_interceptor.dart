import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/licensing/bloc/license_bloc.dart';
import 'package:savvy_stock/features/licensing/bloc/license_state.dart';
import 'package:savvy_stock/features/licensing/screens/license_activation_page.dart';

class LicenseInterceptor extends StatelessWidget {
  final Widget child;
  final bool checkOnStartup;

  const LicenseInterceptor({
    super.key,
    required this.child,
    this.checkOnStartup = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<LicenseBloc, LicenseState>(
      listener: (context, state) {
        if (checkOnStartup && state.status == LicenseStatus.loaded) {
          _handleLicenseState(context, state);
        }
      },
      child: child,
    );
  }

  void _handleLicenseState(BuildContext context, LicenseState state) {
    if (!state.isLicenseValid) {
      // Navigate to license activation page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LicenseActivationPage(),
          ),
          (route) => false,
        );
      });
    }
  }
}
