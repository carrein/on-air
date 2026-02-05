import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'device_uuid_provider.g.dart';

/// Provides a persistent device UUID stored in shared preferences.
@riverpod
Future<String> deviceUuid(DeviceUuidRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  var uuid = prefs.getString('deviceUuid');

  if (uuid == null) {
    uuid = const Uuid().v4();
    await prefs.setString('deviceUuid', uuid);
  }

  return uuid;
}
