import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/licensing/bloc/license_bloc.dart';
import 'package:savvy_stock/features/licensing/bloc/license_state.dart';
import 'package:savvy_stock/features/licensing/model/license_payload_model.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';

class LicenseDetailsPage extends StatelessWidget {
  const LicenseDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LicenseBloc, LicenseState>(
          builder: (context, state) {
            if (state.status == LicenseStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.licensePayload == null) {
              return _buildErrorView();
            }

            return _buildLicenseDetails(
              context,
              state.licensePayload!,
              state.daysRemaining,
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Could not retrieve license information.',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact support or activate your license.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseDetails(
    BuildContext context,
    LicensePayload payload,
    int daysRemaining,
  ) {
    final authbloc = context.read<AuthBloc>().state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(payload),
              const SizedBox(height: 16),
              _buildLicenseInfo(payload),
              const SizedBox(height: 16),
              _buildFeatures(payload),
              const SizedBox(height: 16),
              _buildLimits(payload, daysRemaining),
              const SizedBox(height: 16),
              if (authbloc.isAuthenticated == false)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF145888),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue to Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LicensePayload payload) {
    bool isTrial = payload.licenseId == 'TRIAL';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isTrial ? 'Free Trial Details' : 'License Information',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF145888),
              ),
            ),
            if (isTrial) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text(
                  'TRIAL',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isTrial
              ? 'You are currently using the free trial version of Savvy Stock.'
              : 'This page displays the details of your currently active software license.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLicenseInfo(LicensePayload payload) {
    bool isTrial = payload.licenseId == 'TRIAL';
    return Column(
      children: [
        _buildInfoRow('Licensed To:', payload.issuedTo),
        const SizedBox(height: 16),
        _buildInfoRow(
          isTrial ? 'Trial Started:' : 'License Valid From:',
          '${payload.validFrom.toLocal()}',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          isTrial ? 'Trial Ends:' : 'License Valid Until:',
          '${payload.validTo.toLocal()}',
        ),
        const SizedBox(height: 16),
        if (!isTrial) ...[
          _buildInfoRow('Machine ID:', payload.machineId, isMonospace: true),
          const SizedBox(height: 16),
        ],
        _buildInfoRow('License ID:', payload.licenseId, isMonospace: true),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontFamily: isMonospace ? 'monospace' : null,
              color: isMonospace ? Colors.green[800] : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(LicensePayload payload) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enabled Features:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: SingleChildScrollView(
            child: Text(
              payload.features,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLimits(LicensePayload payload, int daysRemaining) {
    bool isTrial = payload.licenseId == 'TRIAL';

    // Calculate display status
    bool isActive = payload.validTo.isAfter(DateTime.now().toUtc());
    String statusText = isActive ? 'Active' : 'Expired';
    Color statusColor = isActive ? Colors.green[900]! : Colors.red[900]!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLimitCard(
          Icons.people,
          'User Limit',
          '${payload.userLimit} ',
          Colors.amber,
        ),
        _buildLimitCard(
          Icons.business,
          'Branch Limit',
          '${payload.branchLimit} ',
          const Color(0xFF145888),
        ),
        if (isTrial)
          _buildLimitCard(
            Icons.timer,
            'Days Left',
            '$daysRemaining',
            Colors.orange,
          )
        else
          _buildLimitCard(
            Icons.calendar_today,
            'Status',
            statusText,
            statusColor,
          ),
      ],
    );
  }

  Widget _buildLimitCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
