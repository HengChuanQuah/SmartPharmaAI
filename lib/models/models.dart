/// Core patient info
class Patient {
  final String id;
  final String wardRoomNo;
  final String name;
  final String age;
  final String height;
  final String weight;
  final String bloodType;
  final String gender;

  Patient({
    required this.id,
    required this.wardRoomNo,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.bloodType,
    required this.gender,
  });

  // Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'wardRoomNo': wardRoomNo,
    'name': name,
    'age': age,
    'height': height,
    'weight': weight,
    'bloodType': bloodType,
    'Gender': gender,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] ?? '',
    wardRoomNo: json['wardRoomNo'] ?? '',
    name: json['name'] ?? '',
    age: json['age'] ?? '',
    height: json['height'] ?? '',
    weight: json['weight'] ?? '',
    bloodType: json['bloodType'] ?? '',
    gender: json['Gender'] ?? 'Unknown',
  );
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
  final String allergy;
  final String renalFunction; 
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
    this.allergy = '',
    required this.renalFunction,
    required this.lactate,
    required this.wbc,
    required this.condition,
  });

  // Serialization
  Map<String, dynamic> toJson() => {
    'date': date,
    'temperature': temperature,
    'bloodPressure': bloodPressure,
    'heartRate': heartRate,
    'oxygenSaturation': oxygenSaturation,
    'urineOutput': urineOutput,
    'creatinine': creatinine,
    'egfr': egfr,
    'allergy': allergy,
    'renalFunction': renalFunction,
    'lactate': lactate,
    'wbc': wbc,
    'condition': condition,
  };

  factory PatientVitals.fromJson(Map<String, dynamic> json) => PatientVitals(
    date: json['date'] ?? '',
    temperature: json['temperature'] ?? '',
    bloodPressure: json['bloodPressure'] ?? '',
    heartRate: json['heartRate'] ?? '',
    oxygenSaturation: json['oxygenSaturation'] ?? '',
    urineOutput: json['urineOutput'] ?? '',
    creatinine: json['creatinine'] ?? '',
    egfr: json['egfr'] ?? '',
    allergy: json['allergy'] ?? '',
    renalFunction: json['renalFunction'] ?? '',
    lactate: json['lactate'] ?? '',
    wbc: json['wbc'] ?? '',
    condition: json['condition'] ?? '',
  );
}

/// Record linking a patient to one vitals snapshot
class PatientConditionRecord {
  final String patientId;
  final PatientVitals vitals;

  PatientConditionRecord({
    required this.patientId,
    required this.vitals,
  });

  // Serialization
  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'vitals': vitals.toJson(),
  };

  factory PatientConditionRecord.fromJson(Map<String, dynamic> json) => PatientConditionRecord(
    patientId: json['patientId'] ?? '',
    vitals: PatientVitals.fromJson(json['vitals'] ?? {}),
  );
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

  // Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'date': date,
    'medicine': medicine,
    'doseText': doseText,
    'rationale': rationale,
  };

  factory VerifiedPlan.fromJson(Map<String, dynamic> json) => VerifiedPlan(
    id: json['id'] ?? '',
    patientId: json['patientId'] ?? '',
    patientName: json['patientName'] ?? '',
    date: json['date'] ?? '',
    medicine: json['medicine'] ?? '',
    doseText: json['doseText'] ?? '',
    rationale: json['rationale'] ?? '',
  );
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
