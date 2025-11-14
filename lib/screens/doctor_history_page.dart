import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/patient_database.dart';

class DoctorPatientHistoryPage extends StatelessWidget {
  final Patient patient;
  const DoctorPatientHistoryPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final records = PatientDatabase.instance.historyForPatient(patient.id);

    return Scaffold(
      appBar: AppBar(title: const Text("Patient's History"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: [
          Text(
            "History for ${patient.name}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Text('No history records yet for this patient.'),
                  )
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final v = records[i].vitals;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${v.date}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text('Temperature: ${v.temperature} °C'),
                                Text('Blood Pressure: ${v.bloodPressure}'),
                                Text('Heart Rate: ${v.heartRate} bpm'),
                                Text('SpO₂: ${v.oxygenSaturation} %'),
                                const SizedBox(height: 4),
                                Text(
                                  'Condition: ${v.condition}',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic),
                                ),
                              ]),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('Home', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
