import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static SharedPreferences? _instance;

  static SharedPreferences get instance {
    if (_instance == null) {
      throw StateError('SharedPref.instance accessed before init()');
    }
    return _instance!;
  }

  static set instance(SharedPreferences val) => _instance = val;

  static bool get isInitialized => _instance != null;

  static Future<SharedPreferences> init() async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }
}
