import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/repo/udc_detail_repo.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class UdcDetailsBloc extends Bloc<UdcDetailsEvent, UdcDetailsState> {
  final UdcDetailRepo repository;
  final AuthBloc authBloc;

  UdcDetailsBloc({
    required this.repository,
    required this.authBloc,
  }) : super(const UdcDetailsState()) {
    on<LoadUdcDetailsByGroup>(_onLoadUdcDetailsByGroup);
    on<LoadAllUdcDetails>(_onLoadAllUdcDetails);
    on<DeleteSelectedUdcDetails>(_onDeleteSelectedUdcDetails);
    on<CreateUdcDetail>(_onCreateUdcDetail);
    on<UpdateUdcDetail>(_onUpdateUdcDetail);
  }

  Future<void> _onLoadUdcDetailsByGroup(
    LoadUdcDetailsByGroup event,
    Emitter<UdcDetailsState> emit,
  ) async {
    emit(state.copyWith(status: UdcDetailsStatus.loading));
    try {
      final details = await repository.findByGroup(event.groupCode);

      if (details.isEmpty) {
        emit(
          state.copyWith(
            status: UdcDetailsStatus.failure,
            message: 'UDC group not found: ${event.groupCode}',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UdcDetailsStatus.success,
          groupCode: event.groupCode,
          details: details,
          message: 'Loaded ${details.length} details',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UdcDetailsStatus.failure,
          message: 'Failed to load UDC details: $e',
        ),
      );
    }
  }

  Future<void> _onLoadAllUdcDetails(
    LoadAllUdcDetails event,
    Emitter<UdcDetailsState> emit,
  ) async {
    emit(state.copyWith(status: UdcDetailsStatus.loading));
    try {
      final details = await repository.findAll();
      
      if (details.isEmpty) {
        emit(
          state.copyWith(
            status: UdcDetailsStatus.failure,
            message: 'UDCs not found:',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: UdcDetailsStatus.success,
          groupCode: null,
          details: details,
          message: 'Loaded ${details.length} all details',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UdcDetailsStatus.failure,
          message: 'Failed to load UDC details: $e',
        ),
      );
    }
  }

  Future<void> _onCreateUdcDetail(
    CreateUdcDetail event,
    Emitter<UdcDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UdcDetailsStatus.creating,
        message: 'Creating detail...',
      ),
    );
    try {
      await repository.create(event.detail);

      // Invalidate list of items to trigger re-query
      if (state.groupCode != null) {
        add(LoadUdcDetailsByGroup(state.groupCode!));
      }

      emit(
        state.copyWith(
          status: UdcDetailsStatus.success,
          message: 'UDC detail created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UdcDetailsStatus.failure,
          message: 'Failed to create UDC detail: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateUdcDetail(
    UpdateUdcDetail event,
    Emitter<UdcDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UdcDetailsStatus.updating,
        message: 'Updating detail...',
      ),
    );
    try {
      await repository.update(event.detail);

      if (state.groupCode != null) {
        add(LoadUdcDetailsByGroup(state.groupCode!));
      }

      emit(
        state.copyWith(
          status: UdcDetailsStatus.success,
          message: 'UDC detail updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UdcDetailsStatus.failure,
          message: 'Failed to update UDC detail: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteSelectedUdcDetails(
    DeleteSelectedUdcDetails event,
    Emitter<UdcDetailsState> emit,
  ) async {
    if (event.ids.isEmpty) return; // Nothing to delete

    emit(
      state.copyWith(
        status: UdcDetailsStatus.deleting,
        message: 'Deleting details...',
      ),
    );
    try {
      await repository.deleteMultiple(event.ids);
      
      final remainingDetails = state.details
          .where((d) => !event.ids.contains(d.id))
          .toList();
          
      emit(
        state.copyWith(
          status: UdcDetailsStatus.success,
          details: remainingDetails,
          message: '${event.ids.length} UDC details deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UdcDetailsStatus.failure,
          message: 'Failed to delete UDC details: $e',
        ),
      );
    }
  }
}

