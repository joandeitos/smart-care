import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color bgColor = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removendo o backgroundColor do Scaffold, pois o Container fará o preenchimento
      body: Container(
        // 1. Aplicando o Degradê (duas cores)
        decoration: const BoxDecoration(
          color: bgColor
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                color: bgColor,
                child: Image.asset(
                  'assets/images/smart_care.png',
                  width: MediaQuery.of(context).size.width * 0.6,  // 60% da largura da tela
                ),
              ),

              const SizedBox(height: 30),

              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
