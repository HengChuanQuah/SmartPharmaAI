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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_doctor.png'), // background image
            fit: BoxFit.cover,
            opacity: 0.30,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Doctor Portal",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Patient Overview Page',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 50),

              // ---------- 3 BIGGER SQUARE BUTTONS ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _squareButton(
                      icon: Icons.people,
                      label: "Select\nPatient",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PatientListPage()),
                      ),
                    ),
                    _squareButton(
                      icon: Icons.person_add,
                      label: "Add New\nPatient",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddNewPatientPage()),
                      ),
                    ),
                    _squareButton(
                      icon: Icons.medical_services,
                      label: "Pharmacist\nPage",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PharmacistPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⭐ Bigger square button widget
  Widget _squareButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 140,
      height: 140,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// Add New Patient Page (UPDATED: add Gender field)
// ===================================================================

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

  
  String? _gender;

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
      gender: _gender!.trim(), 
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

    // Optional reset (kept minimal)
    //setState(() => _gender = 'Male');
  }

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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

                
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  hint: const Text('Select gender'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (val) => setState(() => _gender = val),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Please select Gender' : null,
                ),

                const SizedBox(height: 16),

                _field(_age, 'Age', kb: TextInputType.number),
                _field(_height, 'Height (cm)', kb: TextInputType.number),
                _field(_weight, 'Weight (kg)', kb: TextInputType.number),
                _field(_blood, 'Blood Type'),
                const SizedBox(height: 24),

                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Submit', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _home,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: kb,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }
}

// ===================================================================
// Patient List Page (search bar + UI) (UPDATED: show Gender)
// ===================================================================

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allPatients = PatientDatabase.instance.patients;

    final patients = allPatients.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.wardRoomNo.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Patient')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  labelText: 'Search Patient',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: patients.isEmpty
                  ? const Center(
                      child: Text(
                        "No patient found.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: patients.length,
                      itemBuilder: (_, i) {
                        final p = patients[i];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.person, color: Colors.blue.shade700),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Ward: ${p.wardRoomNo}\n'
                              'Gender: ${p.gender}\n'
                              'Age: ${p.age} | ${p.height} cm | ${p.weight} kg\n'
                              'Blood Type: ${p.bloodType}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            isThreeLine: true,
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: Colors.blue.shade600),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientActionsPage(patient: p),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// Patient Actions Page (UPDATED: show Gender)
// ===================================================================

class PatientActionsPage extends StatelessWidget {
  final Patient patient;
  const PatientActionsPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    void home() => Navigator.of(context).popUntil((r) => r.isFirst);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Options')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade100,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Ward Room No.: ${patient.wardRoomNo}'),
                        Text('Gender: ${patient.gender}'),
                        Text('Age: ${patient.age}'),
                        Text('Height: ${patient.height} cm'),
                        Text('Weight: ${patient.weight} kg'),
                        Text('Blood Type: ${patient.bloodType}'),
                      ]),
                ),
              ),
              const SizedBox(height: 32),
              _optionBtn(
                context,
                "Patient's Current Condition",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CurrentConditionPage(patient: patient)),
                ),
              ),
              const SizedBox(height: 16),
              _optionBtn(
                context,
                "Patient's History",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DoctorPatientHistoryPage(patient: patient)),
                ),
              ),
              const Spacer(),
              _optionBtn(context, "Home", home),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionBtn(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

