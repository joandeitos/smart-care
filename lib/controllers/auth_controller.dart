import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_care/models/user_model.dart';
import 'package:smart_care/models/auth_state.dart';
import 'package:smart_care/models/login_request.dart';
import 'package:smart_care/models/register_request.dart';
import 'package:smart_care/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  UserModel? get currentUser => _state.user;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;

  AuthController() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) {
      _updateState(
        user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
        isLoading: false,
      );
    });
  }

  void _updateState(
      AuthStatus status, {
        UserModel? user,
        String? errorMessage,
        bool? isLoading,
      }) {
    _state = _state.copyWith(
      status: status,
      user: user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? false, // Garante que nunca fique travado
    );
    notifyListeners();
  }

  Future<bool> signIn(LoginRequest request) async {
    try {
      _updateState(AuthStatus.loading, isLoading: true);

      final user = await _authService.signInWithEmailAndPassword(request);

      if (user != null) {
        _updateState(AuthStatus.authenticated, user: user, isLoading: false);
        return true;
      } else {
        _updateState(AuthStatus.error, errorMessage: 'Falha no login', isLoading: false);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'E-mail inválido. Verifique o endereço e tente novamente.';
          break;
        case 'user-disabled':
          message = 'Esta conta foi desativada.';
          break;
        case 'user-not-found':
          message = 'Usuário não encontrado. Verifique o e-mail digitado.';
          break;
        case 'wrong-password':
          message = 'Senha incorreta. Tente novamente.';
          break;
        default:
          message = 'Erro inesperado: ${e.message ?? 'tente novamente mais tarde.'}';
      }
      _updateState(AuthStatus.error, errorMessage: message, isLoading: false);
      return false;
    } catch (e) {
      _updateState(AuthStatus.error, errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }


  Future<bool> signUp(RegisterRequest request) async {
    try {
      _updateState(AuthStatus.loading, isLoading: true);

      final user = await _authService.createUserWithEmailAndPassword(request);

      if (user != null) {
        _updateState(AuthStatus.authenticated, user: user, isLoading: false);
        return true;
      } else {
        _updateState(AuthStatus.error,
            errorMessage: 'Falha no cadastro', isLoading: false);
        return false;
      }
    } catch (e) {
      _updateState(AuthStatus.error,
          errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      _updateState(AuthStatus.loading, isLoading: true);
      await _authService.signOut();
      _updateState(AuthStatus.unauthenticated, isLoading: false);
      return true;
    } catch (e) {
      _updateState(AuthStatus.error,
          errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _updateState(AuthStatus.loading, isLoading: true);
      await _authService.sendPasswordResetEmail(email);
      _updateState(AuthStatus.unauthenticated, isLoading: false);
      return true;
    } catch (e) {
      _updateState(AuthStatus.error,
          errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _updateState(AuthStatus.loading, isLoading: true);

      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _updateState(AuthStatus.authenticated, user: currentUser, isLoading: false);
        return true;
      } else {
        _updateState(AuthStatus.error,
            errorMessage: 'Falha ao atualizar perfil', isLoading: false);
        return false;
      }
    } catch (e) {
      _updateState(AuthStatus.error,
          errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  void clearError() {
    if (_state.hasError) {
      _updateState(
        _state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: null,
        isLoading: false,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
