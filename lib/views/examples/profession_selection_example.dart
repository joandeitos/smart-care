import 'package:flutter/material.dart';
import 'package:smart_care/models/profession_model.dart';
import 'package:smart_care/services/profession_service.dart';

/// Exemplo de como usar o serviço de profissões em uma view
/// 
/// Esta é uma tela de exemplo mostrando como:
/// 1. Buscar profissões do Firestore
/// 2. Exibir em um dropdown
/// 3. Permitir seleção de profissão pelo usuário

class ProfessionSelectionExample extends StatefulWidget {
  const ProfessionSelectionExample({super.key});

  @override
  State<ProfessionSelectionExample> createState() => _ProfessionSelectionExampleState();
}

class _ProfessionSelectionExampleState extends State<ProfessionSelectionExample> {
  ProfessionModel? _selectedProfession;
  final _professionService = ProfessionService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione sua Profissão'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ProfessionModel>>(
        stream: _professionService.getActiveProfessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar profissões',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma profissão cadastrada'),
            );
          }

          final professions = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecione sua profissão:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ProfessionModel>(
                        value: _selectedProfession,
                        decoration: InputDecoration(
                          labelText: 'Profissão',
                          prefixIcon: const Icon(Icons.work),
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
                        onChanged: (value) {
                          setState(() {
                            _selectedProfession = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Exibir detalhes da profissão selecionada
              if (_selectedProfession != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedProfession!.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        if (_selectedProfession!.description != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _selectedProfession!.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            'ID: ${_selectedProfession!.id}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Lista completa de profissões
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todas as Profissões (${professions.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...professions.map((profession) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              profession.name[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(profession.name),
                          subtitle: profession.description != null
                              ? Text(profession.description!)
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedProfession = profession;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

