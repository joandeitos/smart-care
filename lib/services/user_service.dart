import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_care/services/firebase_service.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  
  UserService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final String _collection = 'users';

  // Salvar ou atualizar dados do usuário
  Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(uid).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Erro ao salvar dados do usuário: $e');
    }
  }

  // Buscar dados do usuário
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar dados do usuário: $e');
    }
  }

  // Atualizar a profissão do usuário
  Future<void> updateUserProfession(String uid, String? professionId) async {
    try {
      await _firestore.collection(_collection).doc(uid).set(
        {
          'professionId': professionId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Erro ao atualizar profissão do usuário: $e');
    }
  }

  // Buscar a profissão do usuário
  Future<String?> getUserProfessionId(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return doc.data()?['professionId'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar profissão do usuário: $e');
    }
  }
}

