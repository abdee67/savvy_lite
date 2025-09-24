// features/privilege/blocs/privilege_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_event.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_state.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';

class PrivilegeBloc extends Bloc<PrivilegeEvent, PrivilegeState> {
  final LocalDatabaseService databaseService;

  PrivilegeBloc({required this.databaseService})
    : super(PrivilegeState(status: PrivilegeStatus.initial)) {
    on<LoadPrivileges>(_onLoadPrivileges);
    on<CreatePrivilege>(_onCreatePrivilege);
    on<UpdatePrivilege>(_onUpdatePrivilege);
    on<DeletePrivilege>(_onDeletePrivilege);
  }

  Future<void> _onLoadPrivileges(
    LoadPrivileges event,
    Emitter<PrivilegeState> emit,
  ) async {
    emit(PrivilegeState(status: PrivilegeStatus.loading));
    try {
      final db = await databaseService.database;
      final privileges = await db.query('privilege_table');

      final privilegeList = privileges
          .map((p) => Privilege.fromMap(p))
          .toList();

      emit(
        PrivilegeState(
          status: PrivilegeStatus.success,
          privileges: privilegeList,
        ),
      );
    } catch (e) {
      emit(
        PrivilegeState(
          status: PrivilegeStatus.failure,
          message: 'Failed to load privileges: $e',
        ),
      );
    }
  }

  Future<void> _onCreatePrivilege(
    CreatePrivilege event,
    Emitter<PrivilegeState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      await db.insert('privilege_table', event.privilege.toMap());

      add(LoadPrivileges()); // Reload the list
    } catch (e) {
      emit(
        PrivilegeState(
          status: PrivilegeStatus.failure,
          message: 'Failed to create privilege: $e',
        ),
      );
    }
  }

  Future<void> _onUpdatePrivilege(
    UpdatePrivilege event,
    Emitter<PrivilegeState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      await db.update(
        'privilege_table',
        event.privilege.toMap(),
        where: 'id = ?',
        whereArgs: [event.privilege.id],
      );

      add(LoadPrivileges()); // Reload the list
    } catch (e) {
      emit(
        PrivilegeState(
          status: PrivilegeStatus.failure,
          message: 'Failed to update privilege: $e',
        ),
      );
    }
  }

  Future<void> _onDeletePrivilege(
    DeletePrivilege event,
    Emitter<PrivilegeState> emit,
  ) async {
    try {
      final db = await databaseService.database;
      await db.delete(
        'privilege_table',
        where: 'id = ?',
        whereArgs: [event.privilegeId],
      );

      add(LoadPrivileges()); // Reload the list
    } catch (e) {
      emit(
        PrivilegeState(
          status: PrivilegeStatus.failure,
          message: 'Failed to delete privilege: $e',
        ),
      );
    }
  }
}
