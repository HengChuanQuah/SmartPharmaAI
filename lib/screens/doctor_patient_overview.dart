import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/patient_database.dart';
import 'current_condition_page.dart';
import 'doctor_history_page.dart';
import 'pharmacist_page.dart';

class PatientOverviewPage extends StatelessWidget {
  const PatientOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    void openPharmacist() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PharmacistPage()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Portal'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Patient Overview Page',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientListPage()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text('Select Patient', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddNewPatientPage()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text('Add New Patient', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: openPharmacist,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text('Pharmacist Page', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ====== Add New Patient ======
class AddNewPatientPage extends StatefulWidget {
  const AddNewPatientPage({super.key});

  @override
  State<AddNewPatientPage> createState() => _AddNewPatientPageState();
}

class _AddNewPatientPageState extends State<AddNewPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _wardRoom = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _blood = TextEditingController();

  @override
  void dispose() {
    _wardRoom.dispose();
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _blood.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final p = Patient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      wardRoomNo: _wardRoom.text.trim(),
      name: _name.text.trim(),
      age: _age.text.trim(),
      height: _height.text.trim(),
      weight: _weight.text.trim(),
      bloodType: _blood.text.trim(),
    );
    PatientDatabase.instance.addPatient(p);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient saved into database.')),
    );
    _wardRoom.clear();
    _name.clear();
    _age.clear();
    _height.clear();
    _weight.clear();
    _blood.clear();
  }

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Patient'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(children: [
                const Text(
                  'Add New Patient',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _field(_wardRoom, 'Ward Room No.'),
                _field(_name, 'Name'),
                _field(_age, 'Age', kb: TextInputType.number),
                _field(_height, 'Height (cm)', kb: TextInputType.number),
                _field(_weight, 'Weight (kg)', kb: TextInputType.number),
                _field(_blood, 'Blood Type (e.g. O+, A-)'),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Text('Submit', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _home,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Text('Home', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {TextInputType? kb}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: c,
        keyboardType: kb,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }
}

/// ====== Patient List / Actions ======
class PatientListPage extends StatelessWidget {
  const PatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final patients = PatientDatabase.instance.patients;
    return Scaffold(
      appBar: AppBar(title: const Text('Select Patient'), centerTitle: true),
      body: patients.isEmpty
          ? const Center(
              child: Text(
                'No patients found.\nPlease add a new patient first.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: patients.length,
              itemBuilder: (_, i) {
                final p = patients[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    title: Text(
                      p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Ward: ${p.wardRoomNo}\n'
                      'Age: ${p.age}   Height: ${p.height} cm   Weight: ${p.weight} kg\n'
                      'Blood Type: ${p.bloodType}',
                    ),
                    isThreeLine: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PatientActionsPage(patient: p)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PatientActionsPage extends StatelessWidget {
  final Patient patient;
  const PatientActionsPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    void home() => Navigator.of(context).popUntil((r) => r.isFirst);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Options'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(patient.name,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ward Room No.: ${patient.wardRoomNo}'),
          Text('Age: ${patient.age}'),
          Text('Height: ${patient.height} cm'),
          Text('Weight: ${patient.weight} kg'),
          Text('Blood Type: ${patient.bloodType}'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CurrentConditionPage(patient: patient)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text("Patient's Current Condition",
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        DoctorPatientHistoryPage(patient: patient)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child:
                    Text("Patient's History", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: home,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('Home', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
