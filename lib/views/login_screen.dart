import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/livestream_provider.dart';
import 'livestream_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.VIEWER;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.live_tv, size: 100, color: Colors.pink),
            const SizedBox(height: 40),
            const Text(
              'TikTok Livestream Clone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Role:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<UserRole>(
                    title: const Text(
                      'Host',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: UserRole.HOST,
                    groupValue: _selectedRole,
                    activeColor: Colors.pink,
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<UserRole>(
                    title: const Text(
                      'Viewer',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: UserRole.VIEWER,
                    groupValue: _selectedRole,
                    activeColor: Colors.pink,
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final user = UserModel(
                    name: _nameController.text,
                    role: _selectedRole,
                  );
                  context.read<LivestreamProvider>().setUser(user);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LivestreamScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'LOGIN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
