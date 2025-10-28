import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_care/controllers/auth_controller.dart';
import 'package:smart_care/models/profession_model.dart';
import 'package:smart_care/services/auth_service.dart';
import 'package:smart_care/services/profession_service.dart';
import 'package:smart_care/services/user_service.dart';
import 'package:smart_care/utils/validators.dart';
import 'package:smart_care/views/Profile/account_info_view.dart';
import 'package:smart_care/views/Profile/security_view.dart';

import '../../theme/app_theme.dart';
import '../Login/login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  ProfessionModel? _selectedProfession;

  final _professionService = ProfessionService.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<AuthController>(context, listen: false).currentUser;
    if (user != null && user.uid != null) {
      _nameController.text = user.displayName ?? '';
      
      // Carregar a profissão do usuário
      try {
        final professionId = await UserService.instance.getUserProfessionId(user.uid!);
        if (professionId != null && professionId.isNotEmpty) {
          final profession = await ProfessionService.instance.getProfessionById(professionId);
          if (profession != null && mounted) {
            setState(() {
              _selectedProfession = profession;
              _professionController.text = profession.name;
            });
          }
        }
      } catch (e) {
        // Silenciosamente ignora erros ao carregar profissão
        print('Erro ao carregar profissão: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.updateProfile(
        displayName: _nameController.text.trim(),
        professionId: _selectedProfession?.id,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, AuthController authController) async {
    final success = await authController.signOut();
    
    if (context.mounted) {
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? 'Erro ao fazer logout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleLogout(context, authController);
              },
              child: const Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Meu Perfil'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            /*actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  tooltip: 'Editar perfil',
                )
              else
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _nameController.text = user?.displayName ?? '';
                    });
                  },
                  tooltip: 'Cancelar',
                ),
            ],*/
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
            child: user == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName![0].toUpperCase()
                                  : user.email?[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Formulário
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Campo Nome
                                  TextFormField(
                                    controller: _nameController,
                                    enabled: _isEditing,
                                    decoration: InputDecoration(
                                      labelText: 'Nome',
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ),
                                    validator: Validators.validateName,
                                  ),
                                  const SizedBox(height: 24),

                                  // Campo Profissão
                                  if(_isEditing) ...[
                                  StreamBuilder<List<ProfessionModel>>(
                                    stream: _professionService.getActiveProfessions(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const LinearProgressIndicator();
                                      }
                                      
                                      if (snapshot.hasError) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.orange),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Erro ao carregar profissões',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      
                                      final professions = snapshot.data ?? [];
                                      
                                      if (professions.isEmpty) {
                                        return DropdownButtonFormField<ProfessionModel>(
                                          value: null,
                                          isExpanded: true,
                                          isDense: true,

                                          decoration: InputDecoration(
                                            labelText: 'Profissão',

                                            prefixIcon: Icon(
                                              Icons.work,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),

                                          ),
                                          items: [],
                                          onChanged: null,
                                        );
                                      }
                                      
                                      // Encontrar o valor selecionado na lista atual
                                      ProfessionModel? currentSelection;
                                      if (_selectedProfession != null) {
                                        try {
                                          currentSelection = professions.firstWhere(
                                            (p) => p.id == _selectedProfession!.id,
                                          );
                                        } catch (e) {
                                          currentSelection = null;
                                        }
                                      } else {
                                        currentSelection = null;
                                      }
                                      
                                      return DropdownButtonFormField<ProfessionModel>(
                                        initialValue: currentSelection,
                                        isExpanded: true,
                                        isDense: true,

                                        decoration: InputDecoration(
                                          labelText: 'Profissão',

                                          prefixIcon: Icon(
                                            Icons.work,
                                            ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),

                                        ),
                                        items: professions.map((profession) {
                                          return DropdownMenuItem<ProfessionModel>(
                                            value: profession,
                                            child: Text(profession.name),
                                          );
                                        }).toList(),
                                        onChanged: _isEditing ? (value) {
                                          setState(() {
                                            _selectedProfession = value;
                                            _professionController.text = value?.name ?? '';
                                          });
                                        } : null,
                                      );
                                    },
                                  ),
                                  ] else ...[
                                    TextFormField(
                                      enabled: false,
                                      controller: _professionController,
                                      decoration: InputDecoration(
                                        labelText: 'Profissão',
                                        prefixIcon: const Icon(Icons.work),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),

                                  // Email (somente leitura)
                                  TextFormField(
                                    initialValue: user.email,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: const Icon(Icons.email),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Informações do usuário
                                  _buildInfoRow(
                                    context,
                                    icon: Icons.date_range,
                                    label: 'Membro desde',
                                    value: _formatDate(user.createdAt),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    context,
                                    icon: Icons.calendar_today,
                                    label: 'Último login',
                                    value: _formatDate(user.lastLoginAt),
                                  ),

                                  const SizedBox(height: 16),

                                  if (!_isEditing) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = true;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme
                                              .of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                12),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<
                                                Color>(Colors.white),
                                          ),
                                        )
                                            : const Text(
                                          'Editar Nome',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  if (_isEditing) ...[
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _updateProfile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Salvar Alterações',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],

                                  if (_isEditing) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = false;
                                            _nameController.text = user.displayName ?? '';
                                            _professionController.text = _selectedProfession?.name ?? '';
                                          });
                                        },
                                        style: AppTheme.cancelButtonStyle,
                                        child: _isLoading
                                            ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                            : const Text(
                                          'Cancelar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Ações
                        /*_buildActionCard(
                          context,
                          icon: Icons.info_outline,
                          title: 'Informações da Conta',
                          subtitle: 'Gerencie suas configurações de conta',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AccountInfoView(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),*/
                        _buildActionCard(
                          context,
                          icon: Icons.security,
                          title: 'Segurança',
                          subtitle: 'Alterar senha e configurações de segurança',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SecurityView(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          icon: Icons.logout,
                          title: 'Sair',
                          subtitle: 'Fazer logout da sua conta',
                          color: Colors.red,
                          onTap: () => _showLogoutDialog(context, authController),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: cardColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color ?? Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}

