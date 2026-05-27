import 'package:web/web.dart' as web;

class SessionStorage {
  const SessionStorage._();

  static String? read(String key) => web.window.localStorage.getItem(key);

  static void write(String key, String value) {
    web.window.localStorage.setItem(key, value);
  }

  static void remove(String key) {
    web.window.localStorage.removeItem(key);
  }
}
