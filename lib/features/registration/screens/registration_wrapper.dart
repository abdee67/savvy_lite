import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/registration/blocs/registration_bloc.dart';
import 'package:savvy_stock/features/registration/screens/company_form.dart';
import 'package:savvy_stock/features/registration/services/registration_service.dart';

/// Wrapper that provides RegistrationBloc to the registration flow
class RegistrationWrapper extends StatelessWidget {
  const RegistrationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegistrationBloc(
        registrationService: RegistrationService(
          databaseService: LocalDatabaseService(),
        ),
        secureStorage: const FlutterSecureStorage(),
      )..add(const InitializeRegistration()),
      child: const CompanyForm(),
    );
  }
}
