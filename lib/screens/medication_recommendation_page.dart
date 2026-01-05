import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // -----------------------------
  // STATE VARIABLES
  // -----------------------------
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  List<Map<String, dynamic>> _prescribedMeds = [];
  bool _isVerifying = false;
  String? _verificationResult;

  String _selectedDoseUnit = 'mg';
  bool _useWhenRequired = false;
  String _selectedFrequency = 'Once a day';

  final SmartPharmaApi _api = SmartPharmaApi();

  @override
  void dispose() {
    _medicineController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  // -----------------------------
  // HELPER METHODS
  // -----------------------------
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

  Widget _buildDoseUnitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedDoseUnit,
        underline: const SizedBox(),
        items: const [
          'g',
          'mg',
          'mcg',
          'mL',
          'tsp',
          'tbsp',
          'IU',
          'units',
          'mg/kg',
          'mcg/kg',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) {
          setState(() => _selectedDoseUnit = val!);
        },
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selectedFrequency,
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          'Once a day',
          'Twice a day',
          'Three times a day',
          'Every 6 hours',
          'Every 8 hours',
        ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
        onChanged: (val) {
          setState(() => _selectedFrequency = val!);
        },
      ),
    );
  }

  Widget _buildEntryRow(String label, Widget input) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: input),
      ],
    );
  }

  // -----------------------------
  // PRESCRIBE & VERIFY METHODS
  // -----------------------------
  void _addPrescription() {
    if (_medicineController.text.isEmpty || _doseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill medicine name and dose')),
      );
      return;
    }

    setState(() {
      _prescribedMeds.add({
        'name': _medicineController.text.trim(),
        'dose': _doseController.text.trim(),
        'unit': _selectedDoseUnit,
        'frequency': _selectedFrequency,
        'prn': _useWhenRequired,
      });

      // Reset input fields
      _medicineController.clear();
      _doseController.clear();
      _selectedDoseUnit = 'mg';
      _selectedFrequency = 'Once a day';
      _useWhenRequired = false;
    });
  }

  Future<void> _verifyMedicine() async {
    if (_prescribedMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No prescribed drugs to verify')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    try {
      // Example: simulate API verification
      final medsToVerify = List<Map<String, dynamic>>.from(_prescribedMeds);

      // Replace this with your actual API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _verificationResult =
            "All ${medsToVerify.length} medicines have been verified successfully!";
      });
    } catch (e) {
      setState(() {
        _verificationResult = 'Verification failed: $e';
      });
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _confirmAndSave() {
    if (_prescribedMeds.isEmpty) return;

    for (var med in _prescribedMeds) {
      final rx = FinalPrescription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        wardRoomNo: widget.patient.wardRoomNo,
        date: widget.vitals.date,
        medicine: med['name'],
        doctorMedicine: med['name'],
        rationale: _verificationResult ?? '',
      );

      PatientDatabase.instance.enqueueForVerification(rx);
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PharmacistPage()),
      (route) => false,
    );
  }

  // -----------------------------
  // BUILD METHOD
  // -----------------------------
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
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
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
            const SizedBox(height: 12),
            const Text(
              'Medicine Required (typed by doctor):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // --- INPUT + PRESCRIBED BOX ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT PANEL: INPUT FORM
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _buildEntryRow(
                          'Drug Name :',
                          TextField(
                            controller: _medicineController,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEntryRow(
                          'Dose :',
                          Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  controller: _doseController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildDoseUnitDropdown(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEntryRow(
                          'Frequency :',
                          _buildFrequencyDropdown(),
                        ),
                        const SizedBox(height: 12),
                        _buildEntryRow(
                          'Use only when required :',
                          Checkbox(
                            value: _useWhenRequired,
                            onChanged: (val) =>
                                setState(() => _useWhenRequired = val ?? false),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _addPrescription,
                              child: const Text('Prescribe'),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () {
                                _medicineController.clear();
                                _doseController.clear();
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // RIGHT PANEL: Prescribed Drugs
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 280,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Prescribed drug(s)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _prescribedMeds.clear());
                              },
                              icon: const Icon(Icons.delete_outline, size: 20),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black, thickness: 1),
                        Expanded(
                          child: ListView(
                            children: _prescribedMeds.map((med) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  "${med['name']} ${med['dose']}${med['unit']} - ${med['frequency']}${med['prn'] ? ' (PRN)' : ''}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyMedicine,
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Verify'),
                        ),
                        if (_verificationResult != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _verificationResult!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
