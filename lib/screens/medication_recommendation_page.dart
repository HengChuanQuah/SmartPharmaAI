import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/patient_database.dart';
import '../services/medicine_rules.dart';
import 'pharmacist_page.dart';

class MedicationRecommendationPage extends StatefulWidget {
  final Patient patient;
  final PatientVitals vitals;
  const MedicationRecommendationPage({
    super.key,
    required this.patient,
    required this.vitals,
  });

  @override
  State<MedicationRecommendationPage> createState() =>
      _MedicationRecommendationPageState();
}

class _MedicationRecommendationPageState
    extends State<MedicationRecommendationPage> {
  final _medicineController = TextEditingController();
  MedicineCheckResult? _checkResult;
  String? _selectedAiMedicine;

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  void _verifyMedicine() {
    final text = _medicineController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the medicine required.')),
      );
      return;
    }
    setState(() {
      _checkResult = checkMedicine(widget.patient, widget.vitals, text);
      _selectedAiMedicine = null;
    });
  }

  void _confirmAndSave() {
    if (_checkResult == null) return;

    if (!_checkResult!.isCorrect &&
        _checkResult!.suggestedMedicines.isNotEmpty &&
        _selectedAiMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please tick one AI-suggested medicine or verify again.')),
      );
      return;
    }

    final accepted = (!_checkResult!.isCorrect && _selectedAiMedicine != null)
        ? _selectedAiMedicine!
        : _medicineController.text.trim();

    final rx = FinalPrescription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patient.id,
      patientName: widget.patient.name,
      wardRoomNo: widget.patient.wardRoomNo,
      date: widget.vitals.date,
      medicine: accepted,
      doctorMedicine: _medicineController.text.trim(),
      rationale: _checkResult!.explanation,
    );

    // Put into pharmacist queue
    PatientDatabase.instance.enqueueForVerification(rx);

    // Immediately go to PharmacistPage as new root
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PharmacistPage()),
      (route) => false,
    );
  }

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 4,
            child:
                Text('$k:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(flex: 6, child: Text(v)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final v = widget.vitals;

    return Scaffold(
      appBar:
          AppBar(title: const Text('Medication Recommendation Page'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(children: [
          const Text(
            'Medication Recommendation Page',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Patient Information:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _info('Name', p.name),
          _info('Ward Room No.', p.wardRoomNo),
          _info('Age', p.age),
          _info('Height', '${p.height} cm'),
          _info('Weight', '${p.weight} kg'),
          _info('Blood Type', p.bloodType),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Entered ICU Data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _info('Date', v.date),
          _info('Temperature', '${v.temperature} °C'),
          _info('Blood Pressure', v.bloodPressure),
          _info('Heart Rate', '${v.heartRate} bpm'),
          _info('Oxygen Saturation', '${v.oxygenSaturation} %'),
          _info('Urine Output', '${v.urineOutput} mL/hr'),
          _info('Creatinine', '${v.creatinine} mg/dL'),
          _info('eGFR', '${v.egfr} mL/min/1.73m²'),
          _info('Lactate', '${v.lactate} mmol/L'),
          _info('WBC', '${v.wbc} ×10⁹/L'),
          const SizedBox(height: 12),
          const Text('Condition of the patient:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(v.condition, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Medicine Required (typed by doctor):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _medicineController,
            decoration: const InputDecoration(
              labelText: 'Medicine Required',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _verifyMedicine,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('Verify Medicine', style: TextStyle(fontSize: 18)),
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
          const SizedBox(height: 24),

          if (_checkResult != null) ...[
            const Text('AI Assessment (Demo Only):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_checkResult!.explanation),
            if (!_checkResult!.isCorrect &&
                _checkResult!.suggestedMedicines.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('AI Suggested Medicine(s): (Tick one if you agree)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ..._checkResult!.suggestedMedicines.map(
                (m) => CheckboxListTile(
                  value: _selectedAiMedicine == m,
                  onChanged: (b) => setState(() {
                    _selectedAiMedicine = (b ?? false) ? m : null;
                  }),
                  title: Text(m),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _confirmAndSave,
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Confirm & Save', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Prototype only — not medical advice.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ]),
      ),
    );
  }
}
