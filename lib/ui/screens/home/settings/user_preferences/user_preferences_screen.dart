import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  bool _chatSoundsEnabled = true;
  bool _isLoading = true; // NEW: Loading flag

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatSoundsEnabled = prefs.getBool('chatSoundsEnabled') ?? true;
      _isLoading = false; // Loading done
    });
  }

  Future<void> _savePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chatSoundsEnabled', value);
    print('preference saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Preferences"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Show loader
            )
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text("Chat Sounds"),
                  subtitle:
                      const Text("Enable or disable chat notification sounds"),
                  value: _chatSoundsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _chatSoundsEnabled = value;
                    });
                    print(_chatSoundsEnabled);
                    _savePreference(value);
                  },
                ),
              ],
            ),
    );
  }
}
