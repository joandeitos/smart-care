import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_care/controllers/auth_controller.dart';
import 'package:smart_care/models/profession_model.dart';
import 'package:smart_care/services/profession_service.dart';
import 'package:smart_care/services/user_service.dart';
import 'package:smart_care/utils/validators.dart';
import 'package:smart_care/views/Profile/security_view.dart';
import 'package:smart_care/components/custom_appbar.dart';
import 'package:uuid/uuid.dart';

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
  List<ProfessionModel> _professions = [];
  bool _professionsLoaded = false;

  final _professionService = ProfessionService.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfessions();
  }

  Future<void> _loadProfessions() async {
    if (!_professionsLoaded) {
      try {
        final professions = await _professionService.getAllProfessions();
        if (mounted) {
          setState(() {
            _professions = professions.where((p) => p.isActive).toList();
            _professions.sort((a, b) => a.name.compareTo(b.name));
            _professionsLoaded = true;
          });
        }
      } catch (e) {
        print('Erro ao carregar profissões: $e');
        if (mounted) {
          setState(() {
            _professionsLoaded = true;
          });
        }
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<AuthController>(context, listen: false).currentUser;

    debugPrint('User: $user');

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
      final String professionText = _professionController.text.trim();
      String? professionId = _selectedProfession?.id;
      
      // Se o usuário digitou uma profissão que não existe na lista, criar ou buscar
      if (professionText.isNotEmpty) {
        if (professionId == null) {
          // Buscar se existe uma profissão com o mesmo nome
          try {
            final allProfessions = await _professionService.getAllProfessions();
            ProfessionModel? existing;
            try {
              existing = allProfessions.firstWhere(
                (p) => p.name.toLowerCase() == professionText.toLowerCase(),
              );
            } catch (e) {
              existing = null;
            }
            
            if (existing != null) {
              final existingProfession = existing; // Promovido para non-null pelo if
              if (existingProfession.id.isNotEmpty) {
                professionId = existingProfession.id;
                // Ativar se estiver inativa
                if (!existingProfession.isActive) {
                  await _professionService.activateProfession(existingProfession.id);
                  // Adiciona à lista cacheada se não estiver lá
                  if (mounted && !_professions.any((p) => p.id == existingProfession.id)) {
                    setState(() {
                      final activated = ProfessionModel(
                        id: existingProfession.id,
                        name: existingProfession.name,
                        description: existingProfession.description,
                        isActive: true,
                        createdAt: existingProfession.createdAt,
                        updatedAt: DateTime.now(),
                      );
                      _professions.add(activated);
                      _professions.sort((a, b) => a.name.compareTo(b.name));
                    });
                  }
                }
              }
            } else {
              // Criar nova profissão com UUID
              final now = DateTime.now();
              final professionIdNew = const Uuid().v4();
              final newProfession = ProfessionModel(
                id: professionIdNew,
                name: professionText,
                isActive: true,
                createdAt: now,
                updatedAt: now,
              );
              await _professionService.createOrUpdateProfession(newProfession);
              professionId = professionIdNew;
              // Adiciona a nova profissão à lista cacheada
              if (mounted) {
                setState(() {
                  _professions.add(newProfession);
                  _professions.sort((a, b) => a.name.compareTo(b.name));
                });
              }
            }
          } catch (e) {
            // Se falhar ao criar/buscar profissão, continua com null
            print('Erro ao processar profissão: $e');
          }
        }
      }
      
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.updateProfile(
        displayName: _nameController.text.trim(),
        professionId: professionId,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        
        if (success) {
          // Recarregar dados do usuário para atualizar a profissão selecionada
          await _loadUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar perfil: ${authController.errorMessage ?? 'Erro desconhecido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          appBar: const CustomAppBar(
            title: 'Meu Perfil',
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
                                  if (!_professionsLoaded)
                                    const LinearProgressIndicator()
                                  else
                                    Autocomplete<String>(
                                      key: ValueKey<String>('profession_${_professions.length}'),
                                      initialValue: TextEditingValue(text: _professionController.text),
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text.isEmpty) {
                                          return _professions.map((p) => p.name).toList();
                                        }
                                        final query = textEditingValue.text.toLowerCase();
                                        return _professions
                                            .where((p) => p.name.toLowerCase().contains(query))
                                            .map((p) => p.name)
                                            .toList();
                                      },
                                      onSelected: (String selected) {
                                        _professionController.text = selected;
                                        try {
                                          final found = _professions.firstWhere(
                                            (p) => p.name == selected,
                                          );
                                          _selectedProfession = found;
                                        } catch (e) {
                                          _selectedProfession = null;
                                        }
                                      },
                                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                        // Sincroniza valor inicial apenas quando o campo não está em foco
                                        if (controller.text != _professionController.text && !focusNode.hasFocus) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (!focusNode.hasFocus && controller.text != _professionController.text) {
                                              controller.text = _professionController.text;
                                            }
                                          });
                                        }
                                        
                                        return TextFormField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: InputDecoration(
                                            labelText: 'Profissão',
                                            prefixIcon: const Icon(Icons.work),
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
                                          onChanged: (value) {
                                            // Atualiza apenas os valores internos, SEM setState para manter o foco
                                            _professionController.text = value;
                                            // Atualiza profissão selecionada sem rebuild
                                            try {
                                              final found = _professions.firstWhere(
                                                (p) => p.name == value,
                                              );
                                              _selectedProfession = found;
                                            } catch (e) {
                                              _selectedProfession = null;
                                            }
                                          },
                                          onFieldSubmitted: (value) => onFieldSubmitted(),
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

