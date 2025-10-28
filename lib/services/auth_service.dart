import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_care/models/user_model.dart';
import 'package:smart_care/models/login_request.dart';
import 'package:smart_care/models/register_request.dart';
import 'package:smart_care/services/firebase_service.dart';
import 'package:smart_care/services/user_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();

  final FirebaseAuth _auth = FirebaseService.instance.auth;

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  Future<UserModel?> signInWithEmailAndPassword(LoginRequest request) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );
      
      return credential.user != null 
          ? UserModel.fromFirebaseUser(credential.user!)
          : null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<UserModel?> createUserWithEmailAndPassword(RegisterRequest request) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      if (credential.user != null) {
        // Atualizar o perfil do usuário com o nome
        await credential.user!.updateDisplayName(request.name);
        await credential.user!.reload();
        
        return UserModel.fromFirebaseUser(credential.user!);
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? professionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();

        // Salvar profissão no Firestore
        if (professionId != null) {
          await UserService.instance.updateUserProfession(user.uid, professionId);
        }
      }
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      if (user.email == null) {
        throw Exception('Email do usuário não encontrado');
      }

      // Reautenticar o usuário com a senha atual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Atualizar a senha
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erro ao alterar senha: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'weak-password':
        return 'A senha é muito fraca';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'invalid-credential':
        return 'Credenciais inválidas';
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este email usando um método de login diferente';
      case 'requires-recent-login':
        return 'Esta operação requer login recente';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
