import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.contains('@') ? null : 'Invalid email',
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length >= 6 ? null : 'Password too short',
              ),
              ElevatedButton(
                child: Text('Login'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await authService.signIn(
                      _emailController.text,
                      _passwordController.text,
                    );
                  }
                },
              ),
              TextButton(
                child: Text('Create Account'),
                onPressed: () => Navigator.pushNamed(context, '/signup'),
              )
            ],
          ),
        ),
      ),
    );
  }
}