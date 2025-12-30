// dose_verification_page.dart
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
  final TextEditingController _pharmacistDose = TextEditingController();
  DoseCalcResult? _doseSuggestion;

  @override
  void initState() {
    super.initState();

    // Use existing vitals if available, otherwise create a simple placeholder
    final PatientVitals vitalsForCalc = widget.vitals ??
        PatientVitals(
          date: widget.queueItem.date,
          temperature: '-',
          bloodPressure: '-',
          heartRate: '-',
          oxygenSaturation: '-',
          urineOutput: '-',
          creatinine: '-',
          egfr: '-',
          allergy: '-',
          renalFunction: '-',
          lactate: '-',
          wbc: '-',
          condition: '-',
        );

    // AI suggests a dose ONLY for the medicine to verify (no alternative medicines)
    _doseSuggestion = calculateDemoDose(
      patient: widget.patient,
      vitals: vitalsForCalc,
      medicineName: widget.queueItem.medicine,
    );

    // Pre-fill pharmacist text with AI suggestion so they can edit
    _pharmacistDose.text = _doseSuggestion?.doseText ?? '';
  }

  @override
  void dispose() {
    _pharmacistDose.dispose();
    super.dispose();
  }

  void _approvePlan() {
    final doseToUse = _pharmacistDose.text.trim();

    if (doseToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a dosage before saving.')),
      );
      return;
    }

    final approved = VerifiedPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.queueItem.patientId,
      patientName: widget.queueItem.patientName,
      date: widget.queueItem.date,
      medicine: widget.queueItem.medicine, // always the same medicine
      doseText: doseToUse,
      rationale: _doseSuggestion == null
          ? 'Pharmacist verified dose: "$doseToUse".'
          : 'AI suggested dose: "${_doseSuggestion!.doseText}". '
            'Pharmacist final dose: "$doseToUse". '
            '${_doseSuggestion!.explanation}',
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
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Patient + med summary
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            'Ward: ${p.wardRoomNo}   Age: ${p.age}   Wt: ${p.weight} kg',
                            style: const TextStyle(color: Colors.black54)),
                        Text('Blood type: ${p.bloodType}',
                            style: const TextStyle(color: Colors.black54)),
                        const Divider(height: 18),
                        Text(
                          'Medicine to verify: ${widget.queueItem.medicine}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        Text(
                          'Doctor originally typed: ${widget.queueItem.doctorMedicine}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          'Doctor AI rationale: ${widget.queueItem.rationale}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54),
                        ),
                      ]),
                ),
              ),
              const SizedBox(height: 12),

              // (REMOVED AI suggested alternative medicines section)

              // Condition snapshot (if available)
              if (v != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Condition Snapshot',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                          const SizedBox(height: 6),
                          Text('Date: ${v.date}',
                              style: const TextStyle(color: Colors.black54)),
                          Text(
                              'Temp: ${v.temperature} °C   BP: ${v.bloodPressure}   HR: ${v.heartRate}',
                              style: const TextStyle(color: Colors.black54)),
                          Text(
                              'SpO₂: ${v.oxygenSaturation}%   Lactate: ${v.lactate} mmol/L',
                              style: const TextStyle(color: Colors.black54)),
                          Text(
                              'WBC: ${v.wbc} ×10⁹/L   Cr: ${v.creatinine} mg/dL   eGFR: ${v.egfr}',
                              style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('Condition: ${v.condition}',
                              style: const TextStyle(color: Colors.black54)),
                        ]),
                  ),
                ),

              const SizedBox(height: 12),

              // Pharmacist Dosage Input + AI suggestion
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Suggested Dose (for this medicine)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _doseSuggestion?.doseText ?? 'No rule available.',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue),
                        ),
                        const SizedBox(height: 6),
                        if (_doseSuggestion != null)
                          Text(
                            _doseSuggestion!.explanation,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pharmacist can edit the final dose:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pharmacistDose,
                          decoration: InputDecoration(
                            labelText: 'Final dose to prescribe',
                            hintText: 'e.g. 1 g IV q8h',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.blue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: const Icon(Icons.edit),
                          ),
                        ),
                      ]),
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _pharmacistDose.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.black87,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Clear',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _approvePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Confirm & Save',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 16),
              const Text(
                'Prototype only — not medical advice.',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
