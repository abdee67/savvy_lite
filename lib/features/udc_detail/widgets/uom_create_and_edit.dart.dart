import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_bloc.dart';
import 'package:savvy_stock/features/system_constant/bloc/system_constant_event.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class UomCreateAndEdit extends StatefulWidget {
  final UdcDetails? item;
  final AuthBloc authBloc;

  const UomCreateAndEdit({super.key, this.item, required this.authBloc});

  @override
  State<UomCreateAndEdit> createState() => _UomCreateAndEditState();
}

class _UomCreateAndEditState extends State<UomCreateAndEdit> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _detailCodeController = TextEditingController();
  final TextEditingController _description1Controller = TextEditingController();
  final TextEditingController _description2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    context.read<SystemConstantBloc>().add(
      LoadSystemConstantsForCompany(widget.authBloc.state.companyId!),
    );
  }

  void _initializeControllers() {
    final item = widget.item ?? UdcDetails.empty();

    _detailCodeController.text = item.detailCode ?? '';
    _description1Controller.text = item.description1 ?? '';
    _description2Controller.text = item.description2 ?? '';
  }

  @override
  void dispose() {
    _detailCodeController.dispose();
    _description1Controller.dispose();
    _description2Controller.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final item = UdcDetails(
        id: widget.item?.id ?? 0,
        detailCode: _detailCodeController.text.trim(),
        description1: _description1Controller.text.trim(),
        description2: _description2Controller.text.trim(),
        recordHeader: widget.item?.recordHeader,
        udcGroup: widget.item?.udcGroup,
      );

      if (widget.item == null) {
        context.read<UdcDetailsBloc>().add(CreateUdcDetail(item));
      } else {
        context.read<UdcDetailsBloc>().add(UpdateUdcDetail(item));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Create UOM' : 'Edit UOM'),
        backgroundColor: const Color(0xFF1C4292),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocListener<UdcDetailsBloc, UdcDetailsState>(
          listener: (context, state) {
            if (state.status == UdcDetailsStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message ?? 'An error occurred'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state.status == UdcDetailsStatus.success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.item == null
                        ? 'UOM created successfully'
                        : 'UOM updated successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(child: _buildForm()),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(
              labelText: 'Detail Code *',
              controller: _detailCodeController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Detail Code is required';
                }
                return null;
              },
              prefixIcon: const Icon(Icons.code),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Description 1 *',
              controller: _description1Controller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description 1 is required';
                }
                return null;
              },
              prefixIcon: const Icon(Icons.description),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Description 2',
              controller: _description2Controller,
              prefixIcon: const Icon(Icons.info_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C4292),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
