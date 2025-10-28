import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_care/models/category_model.dart';
import 'package:smart_care/services/firebase_service.dart';

class CategoryService {
  static CategoryService? _instance;
  static CategoryService get instance => _instance ??= CategoryService._();
  
  CategoryService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final String _collection = 'categories';

  // Criar ou atualizar uma categoria
  Future<void> createOrUpdateCategory(CategoryModel category) async {
    try {
      await _firestore.collection(_collection).doc(category.id).set(
        category.toFirestore(),
      );
    } catch (e) {
      throw Exception('Erro ao criar/atualizar categoria: $e');
    }
  }

  // Buscar categoria por ID
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar categoria: $e');
    }
  }

  // Buscar todas as categorias de um usuário
  Stream<List<CategoryModel>> getUserCategories(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CategoryModel.fromFirestore(doc.id, doc.data());
        }).toList();
      });
    } catch (e) {
      throw Exception('Erro ao buscar categorias: $e');
    }
  }

  // Deletar uma categoria
  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar categoria: $e');
    }
  }

  // Criar categorias padrão para um usuário
  Future<void> createDefaultCategories(String userId) async {
    try {
      final defaultCategories = [
        CategoryModel(
          id: 'consulta',
          name: 'Consulta',
          description: 'Consulta médica inicial',
          userId: userId,
          isComment: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'reconsulta',
          name: 'Reconsulta',
          description: 'Retorno ou reconsulta médica',
          userId: userId,
          isComment: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'exame',
          name: 'Exame',
          description: 'Exame médico ou laboratorial',
          userId: userId,
          isComment: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'procedimento',
          name: 'Procedimento',
          description: 'Procedimento médico ou cirúrgico',
          userId: userId,
          isComment: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'emergencia',
          name: 'Emergência',
          description: 'Atendimento de emergência',
          userId: userId,
          isComment: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Categorias de Comentário
        CategoryModel(
          id: 'avaliacao',
          name: 'Avaliação',
          description: 'Avaliação do paciente',
          userId: userId,
          isComment: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'observacao',
          name: 'Observação',
          description: 'Observações sobre o paciente',
          userId: userId,
          isComment: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'evolucao',
          name: 'Evolução',
          description: 'Evolução do quadro do paciente',
          userId: userId,
          isComment: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'prescricao',
          name: 'Prescrição',
          description: 'Prescrição médica ou medicamentos',
          userId: userId,
          isComment: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'orientacoes',
          name: 'Orientações',
          description: 'Orientações gerais para o paciente',
          userId: userId,
          isComment: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final category in defaultCategories) {
        await createOrUpdateCategory(category);
      }
    } catch (e) {
      throw Exception('Erro ao criar categorias padrão: $e');
    }
  }

  // Verificar se o usuário já tem categorias
  Future<bool> hasUserCategories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

