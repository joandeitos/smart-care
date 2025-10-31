import 'package:flutter/material.dart';
import 'package:smart_care/services/patient_service.dart';
import 'package:smart_care/theme/app_theme.dart';
import 'package:smart_care/components/custom_appbar.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PatientRegisterView extends StatefulWidget {
  final String? patientId;
  final Map<String, dynamic>? initialData; // {name, birthDate, document, phone, address, notes}

  const PatientRegisterView({super.key, this.patientId, this.initialData});

  @override
  State<PatientRegisterView> createState() => _PatientRegisterViewState();
}

class _PatientRegisterViewState extends State<PatientRegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  final MaskTextInputFormatter _dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: { '#': RegExp(r'[0-9]') },
  );

  final MaskTextInputFormatter _phoneMask = MaskTextInputFormatter(
    mask: '(##) #########',
    filter: { '#': RegExp(r'[0-9]') },
  );

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic>? data = widget.initialData;
    if (data != null) {
      _nameController.text = (data['name'] ?? '').toString();
      _birthController.text = (data['birthDate'] ?? '').toString();
      _documentController.text = (data['document'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();
      _addressController.text = (data['address'] ?? '').toString();
      _notesController.text = (data['notes'] ?? '').toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final Map<String, dynamic> json = <String, dynamic>{
      'name': _nameController.text.trim(),
      'birthDate': _birthController.text.trim(),
      'document': _documentController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    try {
      await PatientService.instance.createOrUpdatePatient(json, patientId: widget.patientId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.patientId == null ? 'Paciente cadastrado com sucesso' : 'Paciente atualizado com sucesso')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.patientId == null ? 'Cadastro de Paciente' : 'Editar Paciente',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  textInputAction: TextInputAction.next,
                  validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthController,
                  decoration: const InputDecoration(labelText: 'Data de nascimento (DD/MM/AAAA)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [_dateMask],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _documentController,
                  decoration: const InputDecoration(labelText: 'Documento (CPF/RG ou outro)'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone (00) 999999999'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [_phoneMask],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Observações (opcional)'),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        style: AppTheme.cancelButtonStyle,
                        onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

