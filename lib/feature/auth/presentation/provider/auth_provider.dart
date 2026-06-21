import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveUserState extends StateNotifier<Map<String, dynamic>?> {
  ActiveUserState() : super(null);

  void setUser(Map<String, dynamic> user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}

final activeUserProvider = StateNotifierProvider<ActiveUserState, Map<String, dynamic>?>((ref) {
  return ActiveUserState();
});
