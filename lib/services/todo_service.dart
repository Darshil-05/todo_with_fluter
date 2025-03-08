import 'dart:async';
import 'database_helper.dart';

//todo model
class Todo {
  final int id ;
  final String title;
  bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnTitle: title,
      DatabaseHelper.columnIsCompleted: isCompleted ? 1 : 0,
    };
  }

  // Create a Todo object from a database map
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map[DatabaseHelper.columnId] as int ,
      title: map[DatabaseHelper.columnTitle] as String,
      isCompleted: map[DatabaseHelper.columnIsCompleted] == 1,
    );
  }
}

//todo service
class TodoService {
  final dbHelper = DatabaseHelper.instance;
  final _todoController = StreamController<List<Todo>>.broadcast();

  TodoService() {
    // Load initial todos from database
    _loadTodos();
  }

  Stream<List<Todo>> get todos => _todoController.stream;

  Future<void> _loadTodos() async {
    try {
      final result = await dbHelper.performCRUD(DatabaseHelper.READ);
      // Explicit casting to handle the type
      final todoMaps = result as List<Map<String, dynamic>>;
      print('Todo maps: $todoMaps');
      final todos = todoMaps.map((map) => Todo.fromMap(map)).toList();
      _todoController.add(todos);
    } catch (e) {
      print('Error loading todos: $e');
      // Add empty list if there's an error
      _todoController.add([]);
    }
  }

  Future<void> addTodo(String title) async {
    try {
      // First insert and get the auto-generated ID
      final result = await dbHelper.performCRUD(
        DatabaseHelper.CREATE,
        data: {
          DatabaseHelper.columnTitle: title,
          DatabaseHelper.columnIsCompleted: 0,
        },
      );
      
      // Ensure we have an integer ID
      final id = result as int;
      
      // Update the stream with the new list
      await _loadTodos();
    } catch (e) {
      print('Error adding todo: $e');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      await dbHelper.performCRUD(
        DatabaseHelper.UPDATE,
        id: todo.id,
        data: todo.toMap(),
      );
      await _loadTodos();
    } catch (e) {
      print('Error updating todo: $e');
    }
  }

  Future<void> toggleTodo(int id) async {
    try {
      final result = await dbHelper.performCRUD(
        DatabaseHelper.READ,
        id: id,
      );
      
      if (result != null) {
        // Explicit casting
        final todoMap = result as Map<String, dynamic>;
        final todo = Todo.fromMap(todoMap);
        await dbHelper.performCRUD(
          DatabaseHelper.UPDATE,
          id: id,
          field: DatabaseHelper.columnIsCompleted,
          value: todo.isCompleted ? 0 : 1,
        );
        await _loadTodos();
      }
    } catch (e) {
      print('Error toggling todo: $e');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await dbHelper.performCRUD(
        DatabaseHelper.DELETE,
        id: id,
      );
      await _loadTodos();
    } catch (e) {
      print('Error deleting todo: $e');
    }
  }

  void dispose() {
    _todoController.close();
  }
}