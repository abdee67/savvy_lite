// features/privilege/blocs/privilege_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_event.dart';
import 'package:savvy_stock/features/admin/privilege/blocs/privilege_state.dart';
import 'package:savvy_stock/features/admin/privilege/models/privilege_model.dart';
import 'package:savvy_stock/features/admin/privilege/repo/privilege_repo.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class PrivilegeBloc extends Bloc<PrivilegeEvent, PrivilegeState> {
  final PrivilegeRepository repository;
  final AuthBloc authBloc;

  PrivilegeBloc({required this.repository, required this.authBloc})
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
      final privilegeList = await repository.loadPrivileges();

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
      await repository.insertPrivilege(
        name: event.name,
        description: event.description,
        type: event.type,
        uri: event.uri,
        linkLabel: event.linkLabel!,
        buttonLabel: event.buttonLabel!,
        vendorOnly: event.vendorOnly,
        createdBy: authBloc.state.userId!.id!,
      );

      add(LoadPrivileges(authBloc.state.companyId!));
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
      await repository.updatePrivilege(event.privilege);

      add(LoadPrivileges(authBloc.state.companyId!));
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
      await repository.deletePrivilege(event.privilegeId);

      add(LoadPrivileges(authBloc.state.companyId!));
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
