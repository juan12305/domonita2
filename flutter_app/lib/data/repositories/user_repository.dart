import '../../domain/user.dart';
import 'package:hive/hive.dart';


class UserRepository {
  late Box<User> _box;

  Future<void> init() async {
    _box = await Hive.openBox<User>('userBox');
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      password: password,
      name: name,
      username: username,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _box.put(user.id, user);
  }

  User? getUserByEmail(String email) {
    return _box.values.firstWhere(
      (u) => u.email == email,
  orElse: () => throw Exception('No user found'),
    );
  }

  List<User> getAllUsers() {
    return _box.values.toList();
  }
}
