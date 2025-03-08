import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "todo.db";
  static const _databaseVersion = 1;
  static const table = 'todos';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnIsCompleted = 'isCompleted';

  // CRUD operation types
  static const String CREATE = 'create';
  static const String READ = 'read';
  static const String UPDATE = 'update';
  static const String DELETE = 'delete';

  // Singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnIsCompleted INTEGER NOT NULL
      )
    ''');
  }

  // Single CRUD operation method with fixed type handling
  Future<dynamic> performCRUD(
      String operation, {
      Map<String, dynamic>? data,
      int? id,
      String? field,
      dynamic value,
      String? orderBy,
      }) async {
    Database db = await instance.database;

    switch (operation) {
      case CREATE:
        if (data == null) throw Exception('Data required for CREATE operation');
        print('Inserting row: $data');
        // Return the inserted ID as int
        return await db.insert(table, data);

      case READ:
        if (id != null) {
          // Read single row
          List<Map<String, dynamic>> results = await db.query(
            table,
            where: '$columnId = ?',
            whereArgs: [id],
            limit: 1,
          );
          return results.isNotEmpty ? results.first : null;
        } else {
          // Explicitly cast the result to List<Map<String, dynamic>>
          final result = await db.query(table, orderBy: orderBy ?? '$columnId ASC');
          return result; // This is already List<Map<String, dynamic>>
        }

      case UPDATE:
        if (id == null) throw Exception('ID required for UPDATE operation');
        
        if (data != null) {
          // Update entire row
          return await db.update(
            table,
            data,
            where: '$columnId = ?',
            whereArgs: [id],
          );
        } else if (field != null) {
          // Update single field
          return await db.update(
            table,
            {field: value},
            where: '$columnId = ?',
            whereArgs: [id],
          );
        } else {
          throw Exception('Either data or field+value required for UPDATE operation');
        }

      case DELETE:
        if (id == null) throw Exception('ID required for DELETE operation');
        return await db.delete(
          table,
          where: '$columnId = ?',
          whereArgs: [id],
        );

      default:
        throw Exception('Invalid operation: $operation');
    }
  }
}