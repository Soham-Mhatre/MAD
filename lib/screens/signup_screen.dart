import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_services.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.contains('@') ? null : 'Invalid email',
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length >= 6 ? null : 'Minimum 6 characters',
              ),
              ElevatedButton(
                child: Text('Create Account'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await authService.signUp(
                      _emailController.text,
                      _passwordController.text,
                      _nameController.text,
                    );
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                },
              ),
              TextButton(
                child: Text('Already have an account? Login'),
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              )
            ],
          ),
        ),
      ),
    );
  }
}