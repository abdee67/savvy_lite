import 'dart:async';
import 'package:savvy_stock/core/repositories/base_repo.dart';
import 'package:savvy_stock/core/services/database/database_service.dart';
import 'package:savvy_stock/features/admin/employees/models/employee_model.dart';
import 'package:sqflite/sqflite.dart';

class EmployeeRepository extends BaseRepository {
  @override
  final LocalDatabaseService databaseService;

  EmployeeRepository({required this.databaseService});

  // Load all employees for a company
  Future<List<Employee>> loadEmployees(int companyId) async {
    final db = await databaseService.database;
    final employees = await db.query(
      'employees',
      where: 'company = ?',
      whereArgs: [companyId],
      orderBy: 'name_first ASC, name_last ASC',
    );
    return employees.map((p) => Employee.fromMap(p)).toList();
  }

  // Create new employee
  Future<int> insertEmployee(Employee employee, int companyId) async {
    final db = await databaseService.database;
    final employeeMap = employee.toMap();
    employeeMap.remove('id');
    employeeMap['company'] = companyId;
    
    final id = await db.insert('employees', employeeMap);
    employeeMap['id'] = id;
    captureSync(
      tableName: 'employees',
      entityMap: employeeMap,
      entityId: id.toString(),
      operation: 'INSERT',
      company: companyId.toString(),
    );
    return id;
  }

  // Update existing employee
  Future<int> updateEmployee(Employee employee, int companyId) async {
    final db = await databaseService.database;
    final result = await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ? AND company = ?',
      whereArgs: [employee.id, companyId],
    );
    captureSync(
      tableName: 'employees',
      entityMap: employee.toMap(),
      entityId: employee.id.toString(),
      operation: 'UPDATE',
      company: companyId.toString(),
    );
    return result;
  }

  // Delete single employee
  Future<int> deleteEmployee(int employeeId, int companyId) async {
    final db = await databaseService.database;
    final result = await db.delete(
      'employees',
      where: 'id = ? AND company = ?',
      whereArgs: [employeeId, companyId],
    );
    captureSync(
      tableName: 'employees',
      entityMap: {'id': employeeId, 'company': companyId},
      entityId: employeeId.toString(),
      operation: 'DELETE',
      company: companyId.toString(),
    );
    return result;
  }

  // Delete multiple employees
  Future<void> deleteMultipleEmployees(List<int> employeeIds, int companyId) async {
    final db = await databaseService.database;
    final placeholders = List.filled(employeeIds.length, '?').join(',');
    final whereArgs = [...employeeIds, companyId];
    
    await db.delete(
      'employees',
      where: 'id IN ($placeholders) AND company = ?',
      whereArgs: whereArgs,
    );
  }

  // Check if employee has user account
  Future<bool> checkIfEmployeeHasUserAccount(int employeeId) async {
    try {
      final db = await databaseService.database;
      final users = await db.query(
        'user_table',
        where: 'employees_id = ?',
        whereArgs: [employeeId],
      );
      return users.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get employee by ID
  Future<Employee?> getEmployeeById(int employeeId, int companyId) async {
    try {
      final db = await databaseService.database;
      final results = await db.query(
        'employees',
        where: 'id = ? AND company = ?',
        whereArgs: [employeeId, companyId],
      );
      
      if (results.isNotEmpty) {
        return Employee.fromMap(results.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search employees by query
  Future<List<Employee>> searchEmployees(String query, int companyId) async {
    try {
      final db = await databaseService.database;
      final employees = await db.rawQuery('''
        SELECT * FROM employees 
        WHERE company = ? 
        AND (
          name_first LIKE ? OR 
          name_last LIKE ? OR 
          phone LIKE ? OR 
          email LIKE ?
        )
        ORDER BY name_first ASC, name_last ASC
      ''', [
        companyId,
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%'
      ]);
      
      return employees.map((p) => Employee.fromMap(p)).toList();
    } catch (e) {
      return [];
    }
  }

  // Batch insert employees (for undo operations)
  Future<void> batchInsertEmployees(List<Employee> employees) async {
    final db = await databaseService.database;
    final batch = db.batch();
    
    for (final employee in employees) {
      batch.insert(
        'employees',
        employee.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  // Get employees by IDs
  Future<List<Employee>> getEmployeesByIds(List<int> employeeIds, int companyId) async {
    try {
      if (employeeIds.isEmpty) return [];
      
      final db = await databaseService.database;
      final placeholders = List.filled(employeeIds.length, '?').join(',');
      final whereArgs = [...employeeIds, companyId];
      
      final results = await db.query(
        'employees',
        where: 'id IN ($placeholders) AND company = ?',
        whereArgs: whereArgs,
      );
      
      return results.map((p) => Employee.fromMap(p)).toList();
    } catch (e) {
      return [];
    }
  }
}