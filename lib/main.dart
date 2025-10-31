import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_care/services/firebase_service.dart';
import 'package:smart_care/controllers/auth_controller.dart';
import 'package:smart_care/models/auth_state.dart';
import 'package:smart_care/theme/app_theme.dart';
import 'package:smart_care/views/Login/login_view.dart';
import 'package:smart_care/views/Home/home_view.dart';

import 'package:smart_care/views/SplashScreen/splash_screen.dart';
import 'package:smart_care/views/Patients/patient_register_view.dart';
import 'package:smart_care/views/Patients/patient_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.instance.initialize();
  runApp(const SmartCareApp());
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthController(),
      child: MaterialApp(
        title: 'Smart Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: Consumer<AuthController>(
          builder: (context, authController, child) {

            if (authController.state.status == AuthStatus.loading) {
              return const SplashScreen(); 
            }
            
            if (authController.isAuthenticated) {
              return const HomeView();
            } else {
              return const LoginView();
            }
          },
        ),
        routes: {
          '/login': (context) => const LoginView(),
          '/home': (context) => const HomeView(),
          '/patients/register': (context) => const PatientRegisterView(),
          '/patients': (context) => const PatientListView(),
        },
      ),
    );
  }
}

