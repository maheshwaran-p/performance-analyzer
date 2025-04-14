import 'package:flutter/material.dart';
import 'package:performance_analzer2/providers/auth_service.dart';
import 'package:performance_analzer2/screens/login.dart';
import 'package:provider/provider.dart';
import 'providers/certificate_provider.dart';
import 'providers/user_provider.dart';

void main() {
  final authService = CertificateAuthenticationService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CertificateProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certificate Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}