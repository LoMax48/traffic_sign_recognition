import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> setString(String key, String data) async {
    if (prefs == null) {
      await init();
    }
    await prefs!.setString(key, data);
  }

  Future<String?> getString(String key) async {
    if (prefs == null) {
      await init();
    }
    return prefs!.getString(key);
  }
}
