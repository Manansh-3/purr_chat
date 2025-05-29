import 'package:chat_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  bool _chatSoundsEnabled = true;
  bool _isLoading = true;
  MaterialColor _selectedColor = Colors.blue;

  final Map<String, MaterialColor> _availableColors = {
    'Blue': Colors.blue,
    'Red': Colors.red,
    'Green': Colors.green,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatSoundsEnabled = prefs.getBool('chatSoundsEnabled') ?? true;

      final colorName = prefs.getString('primaryColor') ?? 'Blue';
      _selectedColor = _availableColors[colorName] ?? Colors.blue;

      _isLoading = false;
    });
  }

  Future<void> _savePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chatSoundsEnabled', value);
    print('preference saved');
  }

  Future<void> _saveColorPreference(String colorName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primaryColor', colorName);
    print('color preference saved $colorName');
  }

  Future<void> _onColorChange(String newColorName) async {
  setState(() {
    _isLoading = true;
  });

  // Wait a frame to allow loader to appear
  await Future.delayed(const Duration(milliseconds: 100));

  // Save new color and load the primary theme color
  _selectedColor = _availableColors[newColorName]!;
  await _saveColorPreference(newColorName);
  await loadPrimaryColor();

  setState(() {
    _isLoading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Preferences"),
        backgroundColor: _selectedColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text("Chat Sounds"),
                  subtitle: const Text("Enable or disable chat notification sounds"),
                  value: _chatSoundsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _chatSoundsEnabled = value;
                    });
                    _savePreference(value);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text("Primary Color"),
                  subtitle: const Text("Change the primary theme color"),
                  trailing: DropdownButton<String>(
                    value: _availableColors.keys.firstWhere(
                      (name) => _availableColors[name] == _selectedColor,
                      orElse: () => 'Blue',
                    ),
                    items: _availableColors.keys.map((String name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (String? newColorName) {
                      if (newColorName != null) {
                        _onColorChange(newColorName);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
