import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/widget/customer_details_field.dart';
import 'package:savvy_stock/features/sales/customer/widget/customer_section.dart';

class CustomerInfoScreen extends StatelessWidget {
  final AuthBloc authBloc;
  const CustomerInfoScreen({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    context.read<CustomerBloc>().add(LoadCustomers(authBloc.state.companyId!));
    return const CustomerInfoScreenView();
  }
}

class CustomerInfoScreenView extends StatelessWidget {
  const CustomerInfoScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Customer Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF155888),
        elevation: 0,
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state.status == CustomerStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Bill To section
                CustomerSection(
                  authBloc: context.read<AuthBloc>(),
                  title: 'Customer Bill To:',
                  selectedCustomer: state.selectedBillToCustomer,
                  customers: state.customers,
                  onCustomerSelected: (customer) {
                    context.read<CustomerBloc>().add(
                      SelectBillToCustomer(customer),
                    );
                  },
                  showAddButton: true,
                ),

                const SizedBox(height: 16),

                // Customer details fields
                CustomerDetailsField(
                  tin: state.tin,
                  phone: state.phone,
                  country: state.country,
                  onDetailsChanged: (tin, phone, country) {
                    context.read<CustomerBloc>().add(
                      UpdateCustomerDetails(
                        tin: tin,
                        phone: phone,
                        country: country,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Customer Ship To section
                CustomerSection(
                  authBloc: context.read<AuthBloc>(),
                  title: 'Customer Ship To:',
                  selectedCustomer: state.selectedShipToCustomer,
                  customers: state.customers,
                  onCustomerSelected: (customer) {
                    context.read<CustomerBloc>().add(
                      SelectShipToCustomer(customer),
                    );
                  },
                  showAddButton: false,
                ),

                const SizedBox(height: 20),

                // Next button
                _buildNextButton(context, state.isValid),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, bool isValid) {
    return Container(
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: isValid ? () => _goToNextPage(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155888),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _goToNextPage(BuildContext context) {
    final customerBloc = context.read<CustomerBloc>();
    final selectedCustomer = customerBloc.state.selectedBillToCustomer;

    if (selectedCustomer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }
    print(
      'Selected customer:${selectedCustomer.id} - ${selectedCustomer.customerName} - ${selectedCustomer.country}',
    );
    if (context.read<AuthBloc>().state.hasAccessToPrivilege(
      AppRoutes.salesItemEntry,
    )) {
      context.push(AppRoutes.salesItemEntry, extra: selectedCustomer);
    }
  }
}
