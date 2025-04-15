import 'package:flutter/material.dart';
import 'package:performance_analzer2/providers/auth_service.dart';
import 'package:performance_analzer2/screens/login.dart';
import 'package:performance_analzer2/screens/onboarding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'providers/certificate_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check initial route
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  final authService = CertificateAuthenticationService();
  final userProvider = UserProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(
          create: (_) => CertificateProvider(authService),
        ),
      ],
      child: MyApp(
        initialRoute: determineInitialRoute(
          isLoggedIn, 
          onboardingComplete, 
          userProvider.currentUser != null
        ),
      ),
    ),
  );
}

Widget determineInitialRoute(bool isLoggedIn, bool onboardingComplete, bool hasCurrentUser) {
  if (!onboardingComplete) return const OnboardingScreen();
  if (isLoggedIn ) return const MainScreen();
  return const LoginScreen();
}

class MyApp extends StatelessWidget {
  final Widget initialRoute;

  const MyApp({super.key, required this.initialRoute});

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
      home: initialRoute,
    );
  }
}