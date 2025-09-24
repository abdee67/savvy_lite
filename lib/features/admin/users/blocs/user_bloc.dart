// features/user/blocs/user_bloc.dart
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/role/models/role_model.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:argon2/argon2.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final LocalDatabaseService databaseService;

  UserBloc({required this.databaseService})
    : super(UserState(status: UserStatus.initial)) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<AssignRolesToUser>(_onAssignRolesToUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserState(status: UserStatus.loading));
    try {
      final db = await databaseService.database;
      final users = await db.query('user_table');

      final userList = await Future.wait(
        users.map((u) async => await _getUserWithRoles(u, db)),
      );

      emit(UserState(status: UserStatus.success, users: userList));
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to load users: $e',
        ),
      );
    }
  }

  Future<UserWithRole> _getUserWithRoles(
    Map<String, dynamic> userData,
    Database db,
  ) async {
    final user = UserModel.fromMap(userData);

    // Get user roles
    final roleResults = await db.rawQuery(
      '''
      SELECT r.* FROM role_table r
      INNER JOIN user_role ur ON ur.role_table_id = r.id
      WHERE ur.user_id = ?
    ''',
      [user.id],
    );

    final roles = roleResults.map((r) => Role.fromMap(r)).toList();

    return UserWithRole(user: user, roles: roles);
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UserState> emit) async {
    try {
      final db = await databaseService.database;

      // Hash password (defensive: ensure not null)
      final rawPassword = event.user.password ?? '';
      final hashedPassword = await generateArgon2Hash(rawPassword);

      // Create user
      final userId = await db.insert('user_table', {
        'user_name': event.user.userName,
        'password': hashedPassword,
        'company_id': event.user.company,
        'created_by': event.createdBy,
      });

      // Assign roles if any
      if (event.roleIds.isNotEmpty) {
        for (final roleId in event.roleIds) {
          await db.insert('user_role', {
            'user_id': userId,
            'role_table_id': roleId,
            'created_by': event.createdBy,
            'date_created': DateTime.now().toIso8601String(),
          });
        }
      }

      add(LoadUsers(event.user.company!)); // Reload the list
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to create user: $e',
        ),
      );
    }
  }

  Future<void> _onAssignRolesToUser(
    AssignRolesToUser event,
    Emitter<UserState> emit,
  ) async {
    try {
      final db = await databaseService.database;

      // Remove existing roles
      await db.delete(
        'user_role',
        where: 'user_id = ?',
        whereArgs: [event.userId],
      );

      // Add new roles
      for (final roleId in event.roleIds) {
        await db.insert('user_role', {
          'user_id': event.userId,
          'role_table_id': roleId,
          'created_by': event.createdBy,
          'date_created': DateTime.now().toIso8601String(),
        });
      }

      add(LoadUsers(event.companyId)); // Reload the list
    } catch (e) {
      emit(
        UserState(
          status: UserStatus.failure,
          message: 'Failed to assign roles: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {}

  // Argon2 password hashing helper
  Future<String> generateArgon2Hash(password) async {
    final salt = 'somesalt'.toBytesLatin1();
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_i,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_10,
      iterations: 2,
      memoryPowerOf2: 16,
    );

    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);
    final passwordBytes = parameters.converter.convert(password);
    final result = Uint8List(32);
    argon2.generateBytes(passwordBytes, result, 0, result.length);
    return result.toHexString();
  }
}
