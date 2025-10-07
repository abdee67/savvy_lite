import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_event.dart';
import 'package:savvy_stock/features/udc_detail/blocs/udc_detail_state.dart';
import 'package:savvy_stock/features/udc_detail/models/udc_details.dart';

class UdcDetailsBloc extends Bloc<UdcDetailsEvent, UdcDetailsState> {
  final LocalDatabaseService databaseService;
  final AuthBloc authBloc;

  UdcDetailsBloc({required this.databaseService, required this.authBloc})
    : super(const UdcDetailsState()) {
    on<LoadUdcDetails>(_onLoadUdcDetails);
    on<CreateUdcDetail>(_onCreateUdcDetail);
    on<UpdateUdcDetail>(_onUpdateUdcDetail);
  }

  Future<void> _onLoadUdcDetails(
    LoadUdcDetails event,
    Emitter<UdcDetailsState> emit,
  ) async {
    emit(state.copyWith(status: UdcDetailsStatus.loading));
    try {
      final db = await databaseService.database;

      final header = await db.query(
        'udc_header',
        where: 'header_code = ?',
        whereArgs: [event.groupCode],
      );

      if (header.isEmpty) {
        emit(
          state.copyWith(
            status: UdcDetailsStatus.failure,
            message: 'UDC group not found: ${event.groupCode}',
          ),
        );
        return;
      }

      final headerId = header.first['id'] as int;
      final result = await db.query(
        'udc_details',
        where: 'record_header = ?',
        whereArgs: [headerId],
      );

      final details = result.map((r) => UdcDetails.fromJson(r)).toList();

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
      final db = await databaseService.database;
      final map = event.detail.toJson();
      map.remove('id'); // Ensure auto increment

      await db.insert('udc_details', map);
      if (state.groupCode != null) add(LoadUdcDetails(state.groupCode!));

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
      final db = await databaseService.database;
      await db.update(
        'udc_details',
        event.detail.toJson(),
        where: 'id = ?',
        whereArgs: [event.detail.id],
      );

      if (state.groupCode != null) add(LoadUdcDetails(state.groupCode!));

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
}
