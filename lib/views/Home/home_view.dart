import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_care/controllers/auth_controller.dart';
import 'package:smart_care/views/Profile/profile_view.dart';
import 'package:smart_care/views/Patients/patient_list_view.dart';
import 'package:smart_care/components/custom_appbar.dart';

import '../Login/login_view.dart';
import '../Profile/account_info_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _signOut(BuildContext context) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.signOut();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authController.errorMessage ?? 'Erro ao fazer logout',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;

        return Scaffold(
          appBar: const CustomAppBar(
            title: 'Smart Care',
            /*actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _signOut(context),
                tooltip: 'Sair',
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
                  Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;

                  return Padding(
                    padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Boas-vindas
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: isTablet ? 35 : 30,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  child: Text(
                                    user?.displayName?.isNotEmpty == true
                                        ? user!.displayName![0].toUpperCase()
                                        : user?.email?[0].toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 28 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 20 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bem-vindo!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              fontSize: isTablet ? 28 : 24,
                                            ),
                                      ),
                                      SizedBox(height: isTablet ? 8 : 4),
                                      Text(
                                        user?.displayName?.isNotEmpty == true
                                            ? user!.displayName!.toUpperCase()
                                            : user?.email ?? 'Usuário',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                              fontSize: isTablet ? 16 : 14,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.account_circle,
                                    size: isTablet ? 40 : 35,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfileView(),
                                      ),
                                    );
                                  },
                                  tooltip: 'Ver perfil',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),


                        Text(
                          'Menu',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: isTablet ? 28 : 24,
                              ),
                        ),
                        const SizedBox(height: 16),

                        // Grid de funcionalidades
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Determina o número de colunas baseado na largura disponível
                              int crossAxisCount = 2;
                              if (constraints.maxWidth > 600) {
                                crossAxisCount = 3;
                              }
                              if (constraints.maxWidth > 900) {
                                crossAxisCount = 4;
                              }

                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: constraints.maxWidth > 600
                                    ? 1.1
                                    : 1.0,
                                children: [
                                  _buildFeatureCard(
                                    context,
                                    icon: Icons.calendar_month,
                                    title: 'Agenda',
                                    description: 'Verificar consultas',
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Funcionalidade em desenvolvimento',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildFeatureCard(
                                    context,
                                    icon: Icons.person,
                                    title: 'Pacientes',
                                    description: 'Gerenciar pacientes',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const PatientListView(),
                                        ),
                                      );
                                    },
                                  ),

                                  _buildFeatureCard(
                                    context,
                                    icon: Icons.history,
                                    title: 'Histórico',
                                    description:
                                        'Verificar histórico de consulta',
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Funcionalidade em desenvolvimento',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildFeatureCard(
                                    context,
                                    icon: Icons.settings,
                                    title: 'Configurações',
                                    description: 'Configurar conta',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const AccountInfoView(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajusta o tamanho do ícone baseado no espaço disponível
        final iconSize = constraints.maxWidth > 100 ? 24.0 : 20.0;
        final containerSize = constraints.maxWidth > 100 ? 50.0 : 40.0;
        final padding = constraints.maxWidth > 100 ? 16.0 : 12.0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.08),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: constraints.maxWidth > 100 ? 14 : 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  Flexible(
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: constraints.maxWidth > 100 ? 11 : 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
