import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/features/FSNMR/widgets/fsnmr_tab.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class FSNMRDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const FSNMRDashboard({super.key, required this.authBloc});

  @override
  State<FSNMRDashboard> createState() => _FSNMRDashboardState();
}

class _FSNMRDashboardState extends State<FSNMRDashboard> {
  final GlobalKey<FSNMRTabState> _tabKey = GlobalKey<FSNMRTabState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Fast SlowNon-Moving Rules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C4292),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: () => _tabKey.currentState?.navigateToCreateRule(),
            tooltip: 'Create Rule',
          ),
        ],
      ),
      body: SafeArea(
        child: FSNMRTab(
          key: _tabKey,
          authBloc: widget.authBloc,
        ),
      ),
    );
  }
}
