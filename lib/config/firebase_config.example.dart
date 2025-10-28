import 'package:firebase_core/firebase_core.dart';

/// Arquivo de exemplo para configuração do Firebase
/// 
/// Para usar:
/// 1. Copie este arquivo e renomeie para 'firebase_config.dart'
/// 2. Preencha as credenciais do seu projeto Firebase
/// 3. O arquivo 'firebase_config.dart' está no .gitignore e não será versionado
/// 
/// Para obter suas credenciais:
/// 1. Acesse o Console do Firebase (https://console.firebase.google.com)
/// 2. Selecione seu projeto
/// 3. Vá em Configurações do Projeto > Suas aplicações
/// 4. Selecione sua aplicação web
/// 5. Copie os valores de configuração

class FirebaseConfig {
  static const firebaseConfig = {
    "apiKey": "SUA_API_KEY_AQUI",
    "authDomain": "SEU_PROJECT_ID.firebaseapp.com",
    "projectId": "SEU_PROJECT_ID",
    "storageBucket": "SEU_PROJECT_ID.appspot.com",
    "messagingSenderId": "SEU_MESSAGING_SENDER_ID",
    "appId": "SEU_APP_ID"
  };

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "SUA_API_KEY_AQUI",
        authDomain: "SEU_PROJECT_ID.firebaseapp.com",
        projectId: "SEU_PROJECT_ID",
        storageBucket: "SEU_PROJECT_ID.appspot.com",
        messagingSenderId: "SEU_MESSAGING_SENDER_ID",
        appId: "SEU_APP_ID",
      ),
    );
  }
}