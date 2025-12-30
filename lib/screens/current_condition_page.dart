import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/patient_database.dart';
import 'medication_recommendation_page.dart';

class CurrentConditionPage extends StatefulWidget {
  final Patient patient;
  const CurrentConditionPage({super.key, required this.patient});

  @override
  State<CurrentConditionPage> createState() => _CurrentConditionPageState();
}

class _CurrentConditionPageState extends State<CurrentConditionPage> {
  final _formKey = GlobalKey<FormState>();

  final _date = TextEditingController();
  final _temp = TextEditingController();
  final _bp = TextEditingController();
  final _hr = TextEditingController();
  final _spo2 = TextEditingController();
  final _urine = TextEditingController();
  final _cr = TextEditingController();
  final _egfr = TextEditingController();

  // ✅ NEW: allergy + renal function
  final _allergy = TextEditingController();
  final _renalFn = TextEditingController();

  final _lact = TextEditingController();
  final _wbc = TextEditingController();
  final _cond = TextEditingController();

  @override
  void dispose() {
    _date.dispose();
    _temp.dispose();
    _bp.dispose();
    _hr.dispose();
    _spo2.dispose();
    _urine.dispose();
    _cr.dispose();
    _egfr.dispose();

    // ✅ NEW
    _allergy.dispose();
    _renalFn.dispose();

    _lact.dispose();
    _wbc.dispose();
    _cond.dispose();
    super.dispose();
  }

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final v = PatientVitals(
      date: _date.text.trim(),
      temperature: _temp.text.trim(),
      bloodPressure: _bp.text.trim(),
      heartRate: _hr.text.trim(),
      oxygenSaturation: _spo2.text.trim(),
      urineOutput: _urine.text.trim(),
      creatinine: _cr.text.trim(),
      egfr: _egfr.text.trim(),

      // ✅ NEW: these will be fed into AI prompt later
      allergy: _allergy.text.trim(),
      renalFunction: _renalFn.text.trim(),

      lactate: _lact.text.trim(),
      wbc: _wbc.text.trim(),
      condition: _cond.text.trim(),
    );

    PatientDatabase.instance.addConditionRecord(
      PatientConditionRecord(patientId: widget.patient.id, vitals: v),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationRecommendationPage(patient: widget.patient, vitals: v),
      ),
    );
  }

  Widget _vField(TextEditingController c, String label, {TextInputType? kb}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: kb,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient's Current Condition"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Center(
                  child: Text(
                    "Patient's Current Condition",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ${p.name}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Ward Room No.: ${p.wardRoomNo}'),
                        Text('Gender: ${p.gender}'),
                        Text('Age: ${p.age}'),
                        Text('Height: ${p.height} cm'),
                        Text('Weight: ${p.weight} kg'),
                        Text('Blood Type: ${p.bloodType}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _vField(_date, 'Date (e.g. 2025-11-10)'),
                _vField(_temp, 'Temperature (°C)', kb: TextInputType.number),
                _vField(_bp, 'Blood Pressure (e.g. 120/80 mmHg)'),
                _vField(_hr, 'Heart Rate (bpm)', kb: TextInputType.number),
                _vField(_spo2, 'Oxygen Saturation (SpO₂ %)', kb: TextInputType.number),
                _vField(_urine, 'Urine Output (mL/hr)', kb: TextInputType.number),
                _vField(_cr, 'Creatinine (mg/dL)', kb: TextInputType.number),
                _vField(_egfr, 'eGFR (mL/min/1.73m²)', kb: TextInputType.number),

                // ✅ NEW fields (critical for verification)
                _vField(_allergy, 'Allergy details'),
                _vField(_renalFn, 'Renal function'),

                _vField(_lact, 'Lactate (mmol/L)', kb: TextInputType.number),
                _vField(_wbc, 'WBC (10⁹/L)', kb: TextInputType.number),
                TextFormField(
                  controller: _cond,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Condition of the patient',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please describe the patient condition'
                      : null,
                ),
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
                    child: OutlinedButton(
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
}

