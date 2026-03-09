import 'package:fabri_sync/Model/userModel.dart';

class UserSingleton {
  static final UserSingleton _instance = UserSingleton._internal();
  factory UserSingleton() => _instance;

  UserSingleton._internal();

  UserModel? userModel;

  void clear() {
    userModel = null;
  }
}
