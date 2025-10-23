import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/task_model.dart';

class AppwriteService {
  final Client _client = Client();
  late Databases _db;
  late Realtime _realtime;
  late Account _account;

  final String databaseId = '68ee9a9f001a1fbc26a4';
  final String tasksCollectionId = 'tasks';
  final String usersCollectionId = 'users';

  AppwriteService() {
    _client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('68ee9a7200051509b730');

    _db = Databases(_client);
    _realtime = Realtime(_client);
    _account = Account(_client);
  }

  Future<User> createAccount(String email, String password, String name) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      await ensureUserExists(name);
      return user;
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  Future<Session> login(String email, String password) async {
    try {
      // Check if a session already exists and delete it
      try {
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          print('Session already exists, logging out first...');
          await logout();
        }
      } catch (_) {
        // No current session, proceed to create one
      }

      final session = await _account.createEmailSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      print('Error logging out: $e');
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<void> ensureUserExists(String userName) async {
    try {
      final response = await _db.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [Query.equal('name', userName.toLowerCase())],
      );

      if (response.documents.isEmpty) {
        await _db.createDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: ID.unique(),
          data: {'name': userName.toLowerCase()},
        );
        print('User $userName added to users collection.');
      } else {
        print('User $userName already exists.');
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
      rethrow;
    }
  }

  Future<List<String>> getAllUsers() async {
    try {
      final response = await _db.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [
          Query.orderAsc('name'),
          Query.limit(100),
        ],
      );
      return response.documents
          .map((d) => d.data['name'] as String)
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<List<String>> getAllUsersIncludingAdmin() async {
    try {
      final response = await _db.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [
          Query.orderAsc('name'),
          Query.limit(100),
        ],
      );
      return response.documents
          .map((d) => d.data['name'] as String)
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<List<Task>> getTasks(String userName, bool isAdmin) async {
    try {
      final response = await _db.listDocuments(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
      );
      
      // Filter tasks based on user role
      List<Task> allTasks = response.documents
          .map((d) => Task.fromMap(d.data))
          .toList();
      
      if (!isAdmin) {
        // Filter tasks where user is in the assignedTo list (comma-separated)
        allTasks = allTasks.where((task) {
          final assignedUsers = task.assignedTo.toLowerCase().split(',').map((e) => e.trim()).toList();
          return assignedUsers.contains(userName.toLowerCase());
        }).toList();
      }
      
      return allTasks;
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _db.createDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: ID.unique(),
        data: task.toMap(),
      );
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> createTaskWithId(Task task) async {
    try {
      await _db.createDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: task.id,
        data: task.toMap(),
      );
    } catch (e) {
      print('Error creating task with id: $e');
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String id, String status) async {
    try {
      await _db.updateDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: id,
        data: {'status': status},
      );
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> updateTask({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.updateDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: id,
        data: data,
      );
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _db.deleteDocument(
        databaseId: databaseId,
        collectionId: tasksCollectionId,
        documentId: id,
      );
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  Stream<RealtimeMessage> getRealtimeUpdates() {
    return _realtime
        .subscribe(['databases.$databaseId.collections.$tasksCollectionId.documents'])
        .stream;
  }
}