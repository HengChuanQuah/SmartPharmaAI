import '../models/models.dart';

/// In-memory database (replace with sqflite/Firebase later).
class PatientDatabase {
  PatientDatabase._();
  static final PatientDatabase instance = PatientDatabase._();

  // Core patient + condition history
  final List<Patient> _patients = [];
  final List<PatientConditionRecord> _conditionHistory = [];

  // Doctor-accepted prescriptions queued for PHARMACIST verification
  final List<FinalPrescription> _toVerifyQueue = [];

  // Pharmacist-verified plans (approved or edited doses)
  final List<VerifiedPlan> _verifiedPlans = [];

  // ---------- Patients ----------
  List<Patient> get patients => List.unmodifiable(_patients);
  void addPatient(Patient p) => _patients.add(p);

  // Helper: fetch patient by id
  Patient? patientById(String id) =>
      _patients.cast<Patient?>().firstWhere((p) => p?.id == id, orElse: () => null);

  // ---------- Condition history ----------
  void addConditionRecord(PatientConditionRecord r) => _conditionHistory.add(r);

  List<PatientConditionRecord> historyForPatient(String id) =>
      _conditionHistory.where((r) => r.patientId == id).toList();

  // ---------- Pharmacist queues ----------
  List<FinalPrescription> get toVerifyQueue => List.unmodifiable(_toVerifyQueue);

  void enqueueForVerification(FinalPrescription rx) => _toVerifyQueue.add(rx);

  void removeFromQueue(String id) =>
      _toVerifyQueue.removeWhere((e) => e.id == id);

  // ---------- Verified plans ----------
  List<VerifiedPlan> get verifiedPlans => List.unmodifiable(_verifiedPlans);

  void addVerifiedPlan(VerifiedPlan vp) => _verifiedPlans.add(vp);
}
