import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/core/repositories/udc_repository.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class UdcDetailsBloc extends Bloc<UdcDetailsEvent, UdcDetailsState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;
  final UdcRepository udcRepository;

  UdcDetailsBloc({
    required this.databaseService,
    required this.authBloc,
    required this.udcRepository,
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
      final db = await databaseService.database;

      final results = await db.rawQuery(
        '''
      SELECT d.* FROM udc_details d
      INNER JOIN udc_header h ON d.record_header = h.id
      WHERE h.udc_code = ?
    ''',
        [event.groupCode],
      );

      if (results.isEmpty) {
        emit(
          state.copyWith(
            status: UdcDetailsStatus.failure,
            message: 'UDC group not found: ${event.groupCode}',
          ),
        );
        return;
      }

      final details = results.map((r) => UdcDetails.fromJson(r)).toList();

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
      final db = await databaseService.database;

      final results = await db.query('udc_details');
      if (results.isEmpty) {
        emit(
          state.copyWith(
            status: UdcDetailsStatus.failure,
            message: 'UDCs not found:',
          ),
        );
        return;
      }

      final details = results.map((r) => UdcDetails.fromJson(r)).toList();

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
      await udcRepository.saveUomEntry(event.detail);

      // Invalidate list of items to trigger re-query (matching Java setEditItems(null))
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
      await udcRepository.saveUomEntry(event.detail);

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
      final db = await databaseService.database;
      int deletedRows = 0;

      // A transaction ensures atomicity: either all deletions succeed, or none do.
      await db.transaction((txn) async {
        // Building a WHERE IN clause with placeholders
        final placeholders = List.filled(event.ids.length, '?').join(',');
        deletedRows = await txn.delete(
          'udc_details',
          where: 'id IN ($placeholders)',
          whereArgs: event.ids,
        );
      });
      final remainingDetails = state.details
          .where((d) => !event.ids.contains(d.id))
          .toList();
      emit(
        state.copyWith(
          status: UdcDetailsStatus.success,
          details: remainingDetails,
          message: '$deletedRows UDC details deleted successfully',
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
