import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';
import 'package:savvy_stock/features/stock/item_entry/models/item_entry_model.dart';
import 'package:sqflite/sqflite.dart';

class ItemRepository {
  final Database db;
  final AuthBloc authBloc;

  ItemRepository({required this.db, required this.authBloc});

  Future<List<ItemEntryModel>> getAllItems() async {
    try {
      final results = await db.query('items_table');
      return results.map((json) => ItemEntryModel.fromMap(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ItemEntryModel> getItem(int id) async {
    try {
      final result = await db.query(
        'items_table',
        where: 'id = ?',
        whereArgs: [id],
      );

      return ItemEntryModel.fromMap(result.first);
    } catch (e) {
      rethrow;
    }
  }
}
