import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      appBar: AppBar(
        title: const Text('License Information'),
        backgroundColor: Colors.blue[800],
      ),
      body: SafeArea(
        child: BlocBuilder<LicenseBloc, LicenseState>(
          builder: (context, state) {
            if (state.status == LicenseStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.licensePayload == null) {
              return _buildErrorView();
            }

            return _buildLicenseDetails(context, state.licensePayload!);
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

  Widget _buildLicenseDetails(BuildContext context, LicensePayload payload) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildLicenseInfo(payload),
              const SizedBox(height: 24),
              _buildFeatures(payload),
              const SizedBox(height: 32),
              _buildLimits(payload),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current License Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This page displays the details of your currently active software license.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLicenseInfo(LicensePayload payload) {
    return Column(
      children: [
        _buildInfoRow('Licensed To:', payload.issuedTo),
        const SizedBox(height: 16),
        _buildInfoRow('License Valid From:', '${payload.validFrom.toLocal()}'),
        const SizedBox(height: 16),
        _buildInfoRow('License Valid Until:', '${payload.validTo.toLocal()}'),
        const SizedBox(height: 16),
        _buildInfoRow('Machine ID:', payload.machineId, isMonospace: true),
        const SizedBox(height: 16),
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

  Widget _buildLimits(LicensePayload payload) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLimitCard(
          Icons.people,
          'User Limit',
          '${payload.userLimit} users',
          Colors.blue[700]!,
        ),
        _buildLimitCard(
          Icons.business,
          'Branch Limit',
          '${payload.branchLimit} branches',
          Colors.green[700]!,
        ),
        _buildLimitCard(
          Icons.calendar_today,
          'Status',
          payload.validTo.isAfter(DateTime.now()) ? 'Active' : 'Expired',
          payload.validTo.isAfter(DateTime.now())
              ? Colors.green[700]!
              : Colors.red[700]!,
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
