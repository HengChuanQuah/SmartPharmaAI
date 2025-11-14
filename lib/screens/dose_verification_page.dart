import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/patient_database.dart';
import '../services/ai_dose_calc.dart';

/// Detail page opened from "To be verified"
class DoseVerificationPage extends StatefulWidget {
  final FinalPrescription queueItem;
  final Patient patient;
  final PatientVitals? vitals; // optional (if you want to show vitals snapshot)

  const DoseVerificationPage({
    super.key,
    required this.queueItem,
    required this.patient,
    this.vitals,
  });

  @override
  State<DoseVerificationPage> createState() => _DoseVerificationPageState();
}

class _DoseVerificationPageState extends State<DoseVerificationPage> {
  late final DoseCalcResult _aiDose;
  final TextEditingController _manualDose = TextEditingController();
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _aiDose = calculateDemoDose(
      patient: widget.patient,
      vitals: widget.vitals ??
          PatientVitals(
            date: widget.queueItem.date,
            temperature: '-',
            bloodPressure: '-',
            heartRate: '-',
            oxygenSaturation: '-',
            urineOutput: '-',
            creatinine: '-',
            egfr: '-',
            lactate: '-',
            wbc: '-',
            condition: '-',
          ),
      medicineName: widget.queueItem.medicine,
    );
  }

  void _approvePlan() {
    final approved = VerifiedPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.queueItem.patientId,
      patientName: widget.queueItem.patientName,
      date: widget.queueItem.date,
      medicine: widget.queueItem.medicine,
      doseText: _aiDose.doseText,
      rationale: _aiDose.explanation,
    );

    final db = PatientDatabase.instance;
    db.addVerifiedPlan(approved);
    db.removeFromQueue(widget.queueItem.id);

    Navigator.pop(context, true); // back to Pharmacist main (refresh)
  }

  void _requestChange() {
    setState(() => _editMode = true);
  }

  void _saveManual() {
    final text = _manualDose.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the new dosage.')),
      );
      return;
    }

    final approved = VerifiedPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.queueItem.patientId,
      patientName: widget.queueItem.patientName,
      date: widget.queueItem.date,
      medicine: widget.queueItem.medicine,
      doseText: text,
      rationale:
          'Pharmacist-edited dose based on request to change. AI suggestion was "${_aiDose.doseText}".',
    );

    final db = PatientDatabase.instance;
    db.addVerifiedPlan(approved);
    db.removeFromQueue(widget.queueItem.id);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final v = widget.vitals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacist Dose Verification'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Patient + med summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Ward: ${p.wardRoomNo}   Age: ${p.age}   Wt: ${p.weight} kg'),
                      Text('Blood type: ${p.bloodType}'),
                      const Divider(height: 18),
                      Text(
                        'Medicine to verify: ${widget.queueItem.medicine}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Doctor originally typed: ${widget.queueItem.doctorMedicine}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        'Doctor AI rationale: ${widget.queueItem.rationale}',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ]),
              ),
            ),
            const SizedBox(height: 12),

            if (v != null)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Condition Snapshot',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Date: ${v.date}'),
                        Text(
                            'Temp: ${v.temperature} °C   BP: ${v.bloodPressure}   HR: ${v.heartRate}'),
                        Text(
                            'SpO₂: ${v.oxygenSaturation}%   Lactate: ${v.lactate} mmol/L'),
                        Text(
                            'WBC: ${v.wbc} ×10⁹/L   Cr: ${v.creatinine} mg/dL   eGFR: ${v.egfr}'),
                        const SizedBox(height: 4),
                        Text('Condition: ${v.condition}'),
                      ]),
                ),
              ),

            const SizedBox(height: 12),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Dose Calculation (Demo)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Suggested Dose: ${_aiDose.doseText}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _aiDose.explanation,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ]),
              ),
            ),
            const SizedBox(height: 20),

            if (!_editMode) ...[
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _requestChange,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Request for changing dosage'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _approvePlan,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Approve Plan'),
                    ),
                  ),
                ),
              ]),
            ] else ...[
              const Text('Enter new dosage:'),
              const SizedBox(height: 8),
              TextField(
                controller: _manualDose,
                decoration: const InputDecoration(
                  hintText: 'e.g. 1 g IV q8h',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveManual,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Save and Done'),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Prototype only — not medical advice.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
