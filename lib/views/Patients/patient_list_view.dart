import 'package:flutter/material.dart';
import 'package:smart_care/services/patient_service.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_care/views/Patients/patient_register_view.dart';
import 'package:smart_care/components/custom_appbar.dart';

class PatientListView extends StatefulWidget {
  const PatientListView({super.key});

  @override
  State<PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends State<PatientListView> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _patients =
      <Map<String, dynamic>>[]; // [{id, data}]

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> all = await PatientService.instance
          .listPatients();
      if (!mounted) return;
      if (all.isEmpty && kDebugMode) {
        //await PatientService.instance.seedDemoPatientsIfEmpty();
        final List<Map<String, dynamic>> seeded = await PatientService.instance
            .listPatients();
        if (!mounted) return;
        setState(() {
          _patients = seeded;
        });
      } else {
        setState(() {
          _patients = all;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patients = <Map<String, dynamic>>[];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar os pacientes: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9á-úà-ùâ-ûãõç ]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _sortPatientsAlphabetically(List<Map<String, dynamic>> list) {
    list.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final String an = _normalize(((a['data'] as Map<String, dynamic>)['name'] ?? '').toString());
      final String bn = _normalize(((b['data'] as Map<String, dynamic>)['name'] ?? '').toString());
      return an.compareTo(bn);
    });
  }

  List<Map<String, dynamic>> get _filteredPatients {
    final String q = _normalize(_searchController.text);
    if (q.isEmpty) {
      final List<Map<String, dynamic>> sorted = List<Map<String, dynamic>>.from(_patients);
      _sortPatientsAlphabetically(sorted);

      return sorted;
    }
    final List<String> tokens = q
        .split(' ')
        .where((String t) => t.isNotEmpty)
        .toList();
    final List<Map<String, dynamic>> result = _patients.where((Map<String, dynamic> item) {
      final Map<String, dynamic> data = (item['data'] as Map<String, dynamic>);
      final String name = _normalize((data['name'] ?? '').toString());
      final String document = _normalize((data['document'] ?? '').toString());
      final String address = _normalize((data['address'] ?? '').toString());
      final String hay = [
        name,
        document,
        address,
      ].where((e) => e.isNotEmpty).join(' ');
      // Todos os tokens precisam existir no conjunto (AND)
      return tokens.every((String t) => hay.contains(t));
    }).toList();
    _sortPatientsAlphabetically(result);
    return result;
  }

  Future<void> _goToCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PatientRegisterView()),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> visible = _filteredPatients;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pacientes',
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar paciente',
            onPressed: _goToCreate,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por nome, documento ou endereço',
                  hintText: 'Nome, Documento ou Endereço',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: visible.isEmpty
                          ? ListView(
                              children: const <Widget>[
                                SizedBox(height: 120),
                                Center(
                                  child: Text('Nenhum paciente encontrado'),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final Map<String, dynamic> item =
                                    visible[index];
                                final String id = (item['id'] ?? '').toString();
                                final Map<String, dynamic> data =
                                    (item['data'] as Map<String, dynamic>);
                                final String name = (data['name'] ?? 'Sem nome')
                                    .toString();
                                final String document = (data['document'] ?? '')
                                    .toString();
                                final String address = (data['address'] ?? '')
                                    .toString();

                                String initials(String fullName) {
                                  final List<String> parts = fullName
                                      .trim()
                                      .split(RegExp(r'\s+'));
                                  if (parts.isEmpty || parts.first.isEmpty)
                                    return '?';
                                  final String first = parts.first[0]
                                      .toUpperCase();
                                  final String last = parts.length > 1
                                      ? parts.last[0].toUpperCase()
                                      : '';
                                  return (first + last).trim();
                                }

                                return Dismissible(
                                  key: ValueKey<String>(id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Theme.of(context).colorScheme.error,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (DismissDirection dir) async {
                                    return await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext ctx) =>
                                              AlertDialog(
                                                title: const Text(
                                                  'Excluir paciente',
                                                ),
                                                content: Text(
                                                  'Deseja excluir "$name"?',
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                    child: const Text(
                                                      'Cancelar',
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                    child: const Text(
                                                      'Excluir',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        ) ??
                                        false;
                                  },
                                  onDismissed: (DismissDirection dir) async {
                                    final Map<String, dynamic> removedItem =
                                        <String, dynamic>{
                                          'id': id,
                                          'data': data,
                                        };
                                    final int removedIndex = _patients
                                        .indexWhere(
                                          (Map<String, dynamic> it) =>
                                              it['id'] == id,
                                        );
                                    try {
                                      await PatientService.instance
                                          .deletePatient(id);
                                      if (!mounted) return;
                                      setState(() {
                                        _patients.removeWhere(
                                          (Map<String, dynamic> it) =>
                                              it['id'] == id,
                                        );
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Paciente excluído',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Desfazer',
                                            onPressed: () async {
                                              try {
                                                await PatientService.instance
                                                    .createOrUpdatePatient(
                                                      removedItem['data']
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >,
                                                      patientId:
                                                          removedItem['id']
                                                              as String,
                                                    );
                                                if (!mounted) return;
                                                setState(() {
                                                  _patients.insert(
                                                    removedIndex.clamp(
                                                      0,
                                                      _patients.length,
                                                    ),
                                                    removedItem,
                                                  );
                                                });
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Falha ao desfazer: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      // Reinsere visualmente se falhar a exclusão
                                      setState(() {
                                        if (!_patients.any(
                                          (Map<String, dynamic> it) =>
                                              it['id'] == id,
                                        )) {
                                          _patients.insert(
                                            removedIndex.clamp(
                                              0,
                                              _patients.length,
                                            ),
                                            removedItem,
                                          );
                                        }
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao excluir: $e'),
                                        ),
                                      );
                                    }
                                  },
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(initials(name)),
                                    ),
                                    title: Text(name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (document.isNotEmpty)
                                          Text(
                                            'Doc: $document',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        if (document.isNotEmpty &&
                                            address.isNotEmpty)
                                          SizedBox(height: 4),
                                        if (address.isNotEmpty)
                                          Text(
                                            address,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                      ],
                                    ),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PatientRegisterView(
                                                patientId: id,
                                                initialData: data,
                                              ),
                                        ),
                                      );
                                      if (!mounted) return;
                                      await _load();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
