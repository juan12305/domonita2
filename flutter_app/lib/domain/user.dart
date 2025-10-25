import 'package:hive/hive.dart';
part 'user.g.dart';

@HiveType(typeId: 2)
class User extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String email;
  @HiveField(2)
  String password;
  @HiveField(3)
  String name;
  @HiveField(4)
  String username;
  @HiveField(5)
  String createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.username,
    required this.createdAt,
  });
}
