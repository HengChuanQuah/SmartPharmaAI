import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/patient_database.dart';
import '../services/medicine_rules.dart';
import '../services/smartpharma_api.dart';
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
  final TextEditingController _medicineController = TextEditingController();
  MedicineCheckResult? _checkResult;
  String? _selectedAiMedicine;

  // SmartPharma backend client + state
  final SmartPharmaApi _api = SmartPharmaApi();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  // -----------------------------
  // Small helpers (minimal changes)
  // -----------------------------

  /// ✅ NEW: parse patient age into int for backend section selection (NAG A/B).
  /// Your Patient.age might be stored as String, so we safely parse it.
  int? _patientAgeAsInt() {
    final raw = widget.patient.age.toString().trim();
    return int.tryParse(raw);
  }

  /// Removes common markdown bold markers like **Verification:**
  String _stripMarkdownLabels(String text) {
    return text.replaceAll('**', '').trim();
  }

  /// Extract the LAST occurrence of a field like "Verification:" or "Confidence Score:"
  /// This helps if the backend accidentally returns multiple Verification lines.
  String? _extractLastField(String label, String text) {
    final normalized = _stripMarkdownLabels(text);
    final lines = normalized.split('\n');
    String? last;
    final lowerLabel = label.toLowerCase();

    for (final line in lines) {
      final l = line.trim();
      final idx = l.indexOf(':');
      if (idx <= 0) continue;

      final key = l.substring(0, idx).trim().toLowerCase();
      if (key == lowerLabel) {
        last = l.substring(idx + 1).trim();
      }
    }
    return (last != null && last.isNotEmpty) ? last : null;
  }

  /// Turns the AI response into a short 4-line block if possible.
  String _formatShortAiAnswer(String rawAnswer) {
    final normalized = _stripMarkdownLabels(rawAnswer);

    final verification = _extractLastField('Verification', normalized);
    final confidence = _extractLastField('Confidence Score', normalized);
    final explanation = _extractLastField('Explanation', normalized);
    final citation = _extractLastField('Citation', normalized);

    // If we can extract the required fields, show a clean short format.
    if (verification != null ||
        confidence != null ||
        explanation != null ||
        citation != null) {
      return [
        'Verification: ${verification ?? 'Please review diagnosis to ensure its intended'}',
        'Confidence Score: ${confidence ?? '—'}',
        'Explanation: ${explanation ?? '—'}',
        'Citation: ${citation ?? '—'}',
      ].join('\n');
    }

    // Otherwise, show whatever we got (still stripped of **).
    return normalized;
  }

  /// Decide "isCorrect" from your NEW required Verification phrasing.
  bool _isDiagnosisAccurateFromAnswer(String rawAnswer) {
    final v = _extractLastField('Verification', rawAnswer) ??
        _extractLastField('Verification', _stripMarkdownLabels(rawAnswer)) ??
        '';

    final vv = v.toLowerCase();
    // Only treat "Diagnosis is accurate" as correct.
    return vv.contains('diagnosis is accurate');
  }

  /// Build the natural-language prompt that gets sent to smartpharmAI.py
  String _buildSmartPharmaPrompt(String doctorMedicine) {
    final p = widget.patient;
    final v = widget.vitals;

    return '''
Medication verification request.

Patient Summary:
- ID: ${p.id}
- Name: ${p.name}
- Gender: ${p.gender}
- Age: ${p.age} years
- Ward/Room: ${p.wardRoomNo}
- Height: ${p.height} cm
- Weight: ${p.weight} kg
- Blood Type: ${p.bloodType}

Clinical Data (${v.date}):
- Condition/Diagnosis: ${v.condition}
- Temperature: ${v.temperature} °C
- Blood Pressure: ${v.bloodPressure}
- Heart Rate: ${v.heartRate} bpm
- Oxygen Saturation: ${v.oxygenSaturation} %
- Urine Output: ${v.urineOutput} mL/hr
- Creatinine: ${v.creatinine} mg/dL
- eGFR: ${v.egfr} mL/min/1.73m²
- Allergy: ${v.allergy}
- Renal function: ${v.renalFunction}
- Lactate: ${v.lactate} mmol/L
- WBC: ${v.wbc} ×10⁹/L

Doctor Intended Prescription:
$doctorMedicine

Verify according to Malaysian National Antimicrobial Guideline (NAG).
Output MUST be short and STRICTLY in this exact 4-line format only (no extra text, no headings, no bullet points, no markdown):

Verification: Diagnosis is accurate / Diagnosis is not fully accurate / Please review diagnosis to ensure its that its intended
Confidence Score: <0-100%>
Explanation: <3-4 short sentences backed with citations like [1][2]>
Citation: <[1] source, [2] source>
''';
  }

  Future<void> _verifyMedicine() async {
    final text = _medicineController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the medicine required.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _checkResult = null;
      _selectedAiMedicine = null;
    });

    final prompt = _buildSmartPharmaPrompt(text);

    // ✅ NEW: send structured age to backend so Python can select NAG A/B correctly
    final ageInt = _patientAgeAsInt();

    try {
      // Call Python SmartPharma backend
      // ✅ IMPORTANT: update smartpharma_api.dart so verifyPrescription accepts age
      final resp = await _api.verifyPrescription(prompt, age: ageInt);

      final shortAnswer = _formatShortAiAnswer(resp.answer);

      final result = MedicineCheckResult(
        isCorrect: _isDiagnosisAccurateFromAnswer(resp.answer),
        explanation: shortAnswer,
        suggestedMedicines: const [],
      );

      setState(() {
        _checkResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to contact SmartPharma AI backend.\nUsing local demo rules instead.\nError: $e';
        _checkResult = checkMedicine(widget.patient, widget.vitals, text);
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _confirmAndSave() {
    if (_checkResult == null) return;

    if (!_checkResult!.isCorrect &&
        _checkResult!.suggestedMedicines.isNotEmpty &&
        _selectedAiMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tick one AI-suggested medicine or verify again.'),
        ),
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

    PatientDatabase.instance.enqueueForVerification(rx);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PharmacistPage()),
      (route) => false,
    );
  }

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  Widget _info(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                '$k:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(flex: 6, child: Text(v)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final v = widget.vitals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Recommendation Page'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text(
              'Medication Recommendation Page',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Patient Information:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _info('Name', p.name),
            _info('Ward Room No.', p.wardRoomNo),
            _info('Gender', p.gender),
            _info('Age', p.age),
            _info('Height', '${p.height} cm'),
            _info('Weight', '${p.weight} kg'),
            _info('Blood Type', p.bloodType),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Entered ICU Data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _info('Date', v.date),
            _info('Temperature', '${v.temperature} °C'),
            _info('Blood Pressure', v.bloodPressure),
            _info('Heart Rate', '${v.heartRate} bpm'),
            _info('Oxygen Saturation', '${v.oxygenSaturation} %'),
            _info('Urine Output', '${v.urineOutput} mL/hr'),
            _info('Creatinine', '${v.creatinine} mg/dL'),
            _info('eGFR', '${v.egfr} mL/min/1.73m²'),
            _info('Allergy', v.allergy),
            _info('Renal function', v.renalFunction),
            _info('Lactate', '${v.lactate} mmol/L'),
            _info('WBC', '${v.wbc} ×10⁹/L'),
            const SizedBox(height: 12),
            const Text(
              'Condition of the patient:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              v.condition,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Medicine Required (typed by doctor):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _medicineController,
              decoration: const InputDecoration(
                labelText: 'Medicine Required',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyMedicine,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        'Verify Medicine',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _home,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        'Home',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isVerifying) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            if (_checkResult != null) ...[
              const Text(
                'AI Assessment:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(_checkResult!.explanation),
              if (!_checkResult!.isCorrect &&
                  _checkResult!.suggestedMedicines.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'AI Suggested Medicine(s): (Tick one if you agree)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ..._checkResult!.suggestedMedicines.map(
                  (m) => CheckboxListTile(
                    value: _selectedAiMedicine == m,
                    onChanged: (b) {
                      setState(() {
                        _selectedAiMedicine = (b ?? false) ? m : null;
                      });
                    },
                    title: Text(m),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _confirmAndSave,
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Confirm & Save',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
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
