import 'package:flutter/material.dart';
import 'package:smart_care/components/custom_appbar.dart';
import 'package:smart_care/models/category_model.dart';
import 'package:smart_care/services/category_service.dart';
import 'package:smart_care/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final _categoryService = CategoryService.instance;
  final _authService = AuthService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  CategoryModel? _editingCategory;
  bool _isLoading = false;
  bool _isComment = false;
  bool _hasLoadedDefaults = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCategoriesIfNeeded(String userId) async {
    final hasCategories = await _categoryService.hasUserCategories(userId);
    if (!hasCategories) {
      await _categoryService.createDefaultCategories(userId);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
  }

  void _openCreateDialog() {
    _nameController.text = '';
    _descriptionController.text = '';
    _isComment = false;
    _editingCategory = null;
    _showCategoryDialog();
  }

  void _openEditDialog(CategoryModel category) {
    _editingCategory = category;
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';
    _isComment = category.isComment;
    _showCategoryDialog();
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingCategory != null ? 'Editar Categoria' : 'Nova Categoria'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome da Categoria',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome da categoria é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isComment,
                      onChanged: (value) {
                        setState(() {
                          _isComment = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Categoria de comentário'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nameController.text = '';
              _descriptionController.text = '';
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user?.uid == null) return;

    final now = DateTime.now();
    final userId = user!.uid;
    if (userId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      CategoryModel category;

      if (_editingCategory != null) {
        // Atualizar categoria existente
        category = _editingCategory!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          isComment: _isComment,
          updatedAt: now,
        );
      } else {
        // Criar nova categoria
        category = CategoryModel(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          userId: userId,
          isComment: _isComment,
          createdAt: now,
          updatedAt: now,
        );
      }

      await _categoryService.createOrUpdateCategory(category);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pop();
        _showSnackBar('Categoria salva com sucesso!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Erro ao salvar categoria: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a categoria "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _categoryService.deleteCategory(category.id);
        if (mounted) {
          _showSnackBar('Categoria excluída com sucesso!', Colors.green);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erro ao excluir categoria: ${e.toString()}', Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    if (user?.uid == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Categorias',
        ),
        body: const Center(
          child: Text('Usuário não autenticado'),
        ),
      );
    }

    final userId = user!.uid;
    if (userId == null) return Container();
    
    // Carregar categorias padrão se necessário (apenas uma vez)
    if (!_hasLoadedDefaults) {
      _loadDefaultCategoriesIfNeeded(userId).then((_) {
        if (mounted) {
          setState(() {
            _hasLoadedDefaults = true;
          });
        }
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Categorias',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openCreateDialog,
            tooltip: 'Adicionar categoria',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: StreamBuilder<List<CategoryModel>>(
          stream: _categoryService.getUserCategories(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar categorias'),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString()),
                  ],
                ),
              );
            }

            final categories = snapshot.data ?? [];
            final attendanceCategories = categories.where((c) => !c.isComment).toList();
            final commentCategories = categories.where((c) => c.isComment).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categorias de Atendimento
                  Text(
                    'Categorias de Atendimento (${attendanceCategories.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (attendanceCategories.isEmpty)
                    _buildEmptyState('Nenhuma categoria de atendimento cadastrada')
                  else
                    ...attendanceCategories.map((category) => _buildCategoryCard(category)).toList(),
                  
                  const SizedBox(height: 32),
                  
                  // Categorias de Comentário
                  Text(
                    'Categorias de Comentário (${commentCategories.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (commentCategories.isEmpty)
                    _buildEmptyState('Nenhuma categoria de comentário cadastrada')
                  else
                    ...commentCategories.map((category) => _buildCategoryCard(category)).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.isComment 
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            _getInitials(category.name),
            style: TextStyle(
              color: category.isComment 
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: category.description != null
            ? Text(category.description!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openEditDialog(category),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => _deleteCategory(category),
              tooltip: 'Excluir',
            ),
          ],
        ),
      ),
    );
  }
}
