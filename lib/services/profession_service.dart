import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_care/models/profession_model.dart';
import 'package:smart_care/services/firebase_service.dart';

class ProfessionService {
  static ProfessionService? _instance;
  static ProfessionService get instance => _instance ??= ProfessionService._();
  
  ProfessionService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final String _collection = 'professions';

  // Criar ou atualizar uma profissão
  Future<void> createOrUpdateProfession(ProfessionModel profession) async {
    try {
      await _firestore.collection(_collection).doc(profession.id).set(
        profession.toFirestore(),
      );
    } catch (e) {
      throw Exception('Erro ao criar profissão: $e');
    }
  }

  // Buscar profissão por ID
  Future<ProfessionModel?> getProfessionById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ProfessionModel.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar profissão: $e');
    }
  }

  // Buscar todas as profissões ativas
  Stream<List<ProfessionModel>> getActiveProfessions() {
    try {
      return _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ProfessionModel.fromFirestore(doc.id, doc.data());
        }).toList();
      });
    } catch (e) {
      throw Exception('Erro ao buscar profissões: $e');
    }
  }

  // Buscar todas as profissões (ativas e inativas)
  Future<List<ProfessionModel>> getAllProfessions() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) {
        return ProfessionModel.fromFirestore(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar profissões: $e');
    }
  }

  // Desativar uma profissão
  Future<void> deactivateProfession(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao desativar profissão: $e');
    }
  }

  // Ativar uma profissão
  Future<void> activateProfession(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao ativar profissão: $e');
    }
  }

  // Deletar uma profissão
  Future<void> deleteProfession(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar profissão: $e');
    }
  }

  // Criar múltiplas profissões em lote
  Future<void> createMultipleProfessions(List<ProfessionModel> professions) async {
    try {
      final batch = _firestore.batch();
      
      for (final profession in professions) {
        final docRef = _firestore.collection(_collection).doc(profession.id);
        batch.set(docRef, profession.toFirestore());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao criar profissões em lote: $e');
    }
  }
}
