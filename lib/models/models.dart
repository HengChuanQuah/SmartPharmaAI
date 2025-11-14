import 'package:flutter/foundation.dart';

/// Core patient info
class Patient {
  final String id;
  final String wardRoomNo;
  final String name;
  final String age;
  final String height;
  final String weight;
  final String bloodType;

  Patient({
    required this.id,
    required this.wardRoomNo,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.bloodType,
  });
}

/// One snapshot of patient's condition / vitals
class PatientVitals {
  final String date;
  final String temperature;
  final String bloodPressure;
  final String heartRate;
  final String oxygenSaturation;
  final String urineOutput;
  final String creatinine;
  final String egfr;
  final String lactate;
  final String wbc;
  final String condition;

  PatientVitals({
    required this.date,
    required this.temperature,
    required this.bloodPressure,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.urineOutput,
    required this.creatinine,
    required this.egfr,
    required this.lactate,
    required this.wbc,
    required this.condition,
  });
}

/// Record linking a patient to one vitals snapshot
class PatientConditionRecord {
  final String patientId;
  final PatientVitals vitals;

  PatientConditionRecord({
    required this.patientId,
    required this.vitals,
  });
}

/// Doctor-accepted prescription queued for pharmacist verification
class FinalPrescription {
  final String id;
  final String patientId;
  final String patientName;
  final String wardRoomNo;
  final String date;
  final String medicine;        // final chosen medicine (doctor or AI)
  final String doctorMedicine;  // what doctor originally typed
  final String rationale;       // AI explanation from doctor screen

  FinalPrescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.wardRoomNo,
    required this.date,
    required this.medicine,
    required this.doctorMedicine,
    required this.rationale,
  });
}

/// Pharmacist-verified plan (approved or pharmacist-edited dose)
class VerifiedPlan {
  final String id;
  final String patientId;
  final String patientName;
  final String date;
  final String medicine;
  final String doseText;
  final String rationale;

  VerifiedPlan({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.medicine,
    required this.doseText,
    required this.rationale,
  });
}

/// AI rule check result for doctor's medicine
class MedicineCheckResult {
  final bool isCorrect;
  final String explanation;
  final List<String> suggestedMedicines;

  MedicineCheckResult({
    required this.isCorrect,
    required this.explanation,
    required this.suggestedMedicines,
  });
}

/// AI dose calculation result (for pharmacist demo)
class DoseCalcResult {
  final String doseText;
  final String explanation;

  DoseCalcResult({
    required this.doseText,
    required this.explanation,
  });
}
