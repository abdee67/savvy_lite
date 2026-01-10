import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/auth/model/subscription_management_model.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/company/models/company_model.dart';

/// Aggregates all data needed for registration process.
/// Mirrors the Java SignupData class.
class SignupData {
  final Company company;
  final Branch primaryBranch;
  final Employee employee;
  final UserModel adminUser;
  final SubscriptionManagement? initialSettings;
  final String? referralCode;

  const SignupData({
    required this.company,
    required this.primaryBranch,
    required this.employee,
    required this.adminUser,
    this.initialSettings,
    this.referralCode,
  });

  SignupData copyWith({
    Company? company,
    Branch? primaryBranch,
    Employee? employee,
    UserModel? adminUser,
    SubscriptionManagement? initialSettings,
    String? referralCode,
  }) {
    return SignupData(
      company: company ?? this.company,
      primaryBranch: primaryBranch ?? this.primaryBranch,
      employee: employee ?? this.employee,
      adminUser: adminUser ?? this.adminUser,
      initialSettings: initialSettings ?? this.initialSettings,
      referralCode: referralCode ?? this.referralCode,
    );
  }

  /// Creates an empty SignupData for initialization
  static SignupData empty() {
    return SignupData(
      company: Company.empty(),
      primaryBranch: Branch.empty(),
      employee: Employee.empty(),
      adminUser: const UserModel(id: 0, password: ''),
    );
  }
}
