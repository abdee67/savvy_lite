import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_bloc.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_event.dart';
import 'package:savvy_stock/features/sales/customer/blocs/customer_state.dart';
import 'package:savvy_stock/features/sales/customer/widget/customer_details_field.dart';
import 'package:savvy_stock/features/sales/customer/widget/customer_section.dart';
import 'package:savvy_stock/features/sales/sales_item_entry/screens/sales_item_entry.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomerBloc()..add(LoadCustomers()),
      child: const CustomerScreenView(),
    );
  }
}

class CustomerScreenView extends StatelessWidget {
  const CustomerScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Customer Information',
          style: TextStyle(
            color: Color(0xFF155888),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
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
    context.push('/itemEntryScreen');
  }
}
