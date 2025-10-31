import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_care/services/firebase_service.dart';
import 'package:smart_care/services/encryption_service.dart';
import 'package:uuid/uuid.dart';

class PatientService {
  PatientService._();
  static final PatientService instance = PatientService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  static const String _collection = 'patients';

  Future<String> createOrUpdatePatient(Map<String, dynamic> patientData, {String? patientId}) async {
    final String id = patientId ?? const Uuid().v4();
    final Map<String, dynamic> envelope = await EncryptionService.instance.encrypt(patientData);
    final Map<String, dynamic> doc = <String, dynamic>{
      'v': envelope['v'],
      'alg': envelope['alg'],
      'nonce': envelope['nonce'],
      'ciphertext': envelope['ciphertext'],
      'mac': envelope['mac'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection(_collection).doc(id).set(doc, SetOptions(merge: true));
    return id;
  }

  Future<Map<String, dynamic>?> readPatient(String patientId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection(_collection).doc(patientId).get();
    if (!doc.exists) return null;
    final Map<String, dynamic> data = doc.data()!;
    return EncryptionService.instance.decrypt(data);
  }

  Future<List<Map<String, dynamic>>> listPatients() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();
    final List<Map<String, dynamic>> patients = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs) {
      try {
        final Map<String, dynamic>? data = await EncryptionService.instance.decrypt(d.data());
        if (data != null) {
          patients.add(<String, dynamic>{'id': d.id, 'data': data});
        }
      } catch (_) {
        // ignore corrupted entry
      }
    }
    return patients;
  }

  Future<void> deletePatient(String patientId) async {
    await _firestore.collection(_collection).doc(patientId).delete();
  }

  // Dev/test utilities
  Future<bool> _hasAnyPatient() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection(_collection)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> seedDemoPatientsIfEmpty() async {
    if (await _hasAnyPatient()) return;
    final List<Map<String, dynamic>> demo = <Map<String, dynamic>>[
      {
        'name': 'João da Silva',
        'birthDate': '1985-03-12',
        'document': '123.456.789-01',
        'phone': '(11) 98765-4321',
        'address': 'Rua das Flores, 123 - São Paulo/SP',
        'notes': 'Hipertenso'
      },
      {
        'name': 'Maria Oliveira',
        'birthDate': '1990-07-25',
        'document': '987.654.321-00',
        'phone': '(21) 99876-5432',
        'address': 'Av. Atlântica, 500 - Rio de Janeiro/RJ',
        'notes': 'Alergia a penicilina'
      },
      {
        'name': 'Carlos Pereira',
        'birthDate': '1978-11-02',
        'document': '111.222.333-44',
        'phone': '(31) 91234-5678',
        'address': 'Rua Minas, 45 - Belo Horizonte/MG',
        'notes': ''
      },
      {
        'name': 'Ana Souza',
        'birthDate': '2000-01-15',
        'document': '555.666.777-88',
        'phone': '(41) 92345-6789',
        'address': 'Rua Curitiba, 89 - Curitiba/PR',
        'notes': 'Gestante'
      },
      {
        'name': 'Pedro Santos',
        'birthDate': '1995-05-30',
        'document': '222.333.444-55',
        'phone': '(51) 93456-7890',
        'address': 'Av. Ipiranga, 1000 - Porto Alegre/RS',
        'notes': 'Diabético'
      },
    ];
    // Adiciona mais 20 pacientes gerados
    final List<String> firstNames = <String>[
      'Lucas','Beatriz','Rafael','Camila','Gustavo','Larissa','Felipe','Aline','Bruno','Carolina',
      'Diego','Fernanda','Eduardo','Patrícia','Marcelo','Juliana','Leandro','Sabrina','André','Natália'
    ];
    final List<String> lastNames = <String>[
      'Almeida','Barbosa','Cardoso','Domingues','Esteves','Figueira','Gonçalves','Hernandes','Ibarra','Junqueira',
      'Klein','Lopes','Machado','Nascimento','Oliveira','Pereira','Queiroz','Ribeiro','Silva','Teixeira'
    ];
    for (int i = 0; i < 20; i++) {
      final String name = '${firstNames[i % firstNames.length]} ${lastNames[i % lastNames.length]}';
      final String cpf = '${100 + i}.${200 + i}.${300 + i}-${(10 + i).toString().padLeft(2, '0')}';
      demo.add(<String, dynamic>{
        'name': name,
        'birthDate': '199${i % 10}-0${(i % 9) + 1}-1${i % 9}',
        'document': cpf,
        'phone': '(11) 9${7000 + i}-${4000 + i}',
        'address': 'Rua Exemplo, ${i + 10} - Bairro ${String.fromCharCode(65 + (i % 26))}',
        'notes': i % 2 == 0 ? 'Paciente de retorno' : '',
      });
    }
    for (final Map<String, dynamic> p in demo) {
      await createOrUpdatePatient(p);
    }
  }

}


