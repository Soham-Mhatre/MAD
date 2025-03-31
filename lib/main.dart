import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:madproject/screens/dashboard_screen.dart';
import 'package:madproject/screens/login_screen.dart';
import 'package:madproject/screens/signup_screen.dart';
import 'package:madproject/screens/ticker_detail_screen.dart';
import 'package:madproject/services/stock_service.dart';
import 'package:provider/provider.dart';
import 'auth/auth_services.dart';
import 'services/watchlist_service.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<WatchlistService>(create: (_) => WatchlistService()),
        Provider<StockService>(create: (_) => StockService()),// Add this line
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Stock App',
        initialRoute: '/',
      routes: {
          '/': (context) => AuthWrapper(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(), // Add this line
          '/dashboard': (context) => DashboardScreen(),
          '/ticker': (context) => TickerDetailScreen(
          symbol: ModalRoute.of(context)!.settings.arguments as String,
          ),},
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();
    return user == null ? LoginScreen() : DashboardScreen();
  }
}