import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_services.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email}'),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Logout'),
              onPressed: () async {
                await authService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            )
          ],
        ),
      ),
    );
  }
}