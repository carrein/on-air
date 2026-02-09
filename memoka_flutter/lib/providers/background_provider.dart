import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'background_provider.g.dart';

/// Available background options
enum BackgroundType {
  flower('flower', 'Flower'),
  food('food', 'Food'),
  gift('gift', 'Gift'),
  leaves('leaves', 'Leaves'),
  light('light', 'Light'),
  memphis('memphis', 'Memphis'),
  morocco('morocco', 'Morocco'),
  pentagon('pentagon', 'Pentagon'),
  sakura('sakura', 'Sakura'),
  sun('sun', 'Sun'),
  terrazzo('terrazzo', 'Terrazzo'),
  tree('tree', 'Tree'),
  wheat('wheat', 'Wheat'),
  wormz('wormz', 'Wormz');

  const BackgroundType(this.filename, this.displayName);

  final String filename;
  final String displayName;

  String get assetPath => 'assets/images/backgrounds/$filename.png';
}

/// Provider for managing background selection
@riverpod
class BackgroundPreference extends _$BackgroundPreference {
  static const _key = 'selected_background';

  @override
  BackgroundType build() {
    _loadPreference();
    return BackgroundType.memphis; // Default
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      try {
        state = BackgroundType.values.firstWhere((e) => e.filename == saved);
      } catch (_) {
        state = BackgroundType.memphis;
      }
    }
  }

  Future<void> setBackground(BackgroundType background) async {
    state = background;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, background.filename);
  }
}
