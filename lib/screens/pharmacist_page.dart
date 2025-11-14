import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/patient_database.dart';
import 'dose_verification_page.dart';
import 'verified_history_page.dart';
import 'feedback_page.dart';

class PharmacistPage extends StatefulWidget {
  const PharmacistPage({super.key});

  @override
  State<PharmacistPage> createState() => _PharmacistPageState();
}

class _PharmacistPageState extends State<PharmacistPage> {
  String searchToBeVerified = '';
  String searchVerified = '';

  @override
  Widget build(BuildContext context) {
    final db = PatientDatabase.instance;

    final queue = db.toVerifyQueue;
    final verified = db.verifiedPlans;

    // Group verified by patient for the "Verified" tab
    final Map<String, List<VerifiedPlan>> verifiedByPatient = {};
    for (final vp in verified) {
      verifiedByPatient.putIfAbsent(vp.patientId, () => []).add(vp);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Pharmacist Console",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue.shade700,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "To be verified"),
              Tab(text: "Verified"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ======== TAB 1: To be verified ========
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (v) => setState(() => searchToBeVerified = v),
                    decoration: InputDecoration(
                      labelText: "Search by patient name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Type a name...",
                    ),
                  ),
                ),
                Expanded(
                  child: queue.isEmpty
                      ? const Center(child: Text('No items to verify yet.'))
                      : ListView.builder(
                          itemCount: queue.length,
                          itemBuilder: (_, i) {
                            final item = queue[i];
                            if (!item.patientName
                                .toLowerCase()
                                .contains(searchToBeVerified.toLowerCase())) {
                              return const SizedBox.shrink();
                            }
                            final patient = db.patientById(item.patientId);
                            // attempt to get the latest vitals of same date
                            final vitals = db
                                .historyForPatient(item.patientId)
                                .where((r) => r.vitals.date == item.date)
                                .map((r) => r.vitals)
                                .cast<PatientVitals?>()
                                .firstWhere((v) => v != null, orElse: () => null);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.pending_actions,
                                    color: Colors.orange),
                                title: Text(
                                  item.patientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                    'Medicine: ${item.medicine}\nDate: ${item.date}'),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                                onTap: () {
                                  if (patient == null) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DoseVerificationPage(
                                        queueItem: item,
                                        patient: patient,
                                        vitals: vitals,
                                      ),
                                    ),
                                  ).then((changed) {
                                    if (changed == true) setState(() {});
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // ======== TAB 2: Verified ========
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (v) => setState(() => searchVerified = v),
                    decoration: InputDecoration(
                      labelText: "Search by patient name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Type a name...",
                    ),
                  ),
                ),
                Expanded(
                  child: verifiedByPatient.isEmpty
                      ? const Center(child: Text('No verified plans yet.'))
                      : ListView(
                          children: verifiedByPatient.entries
                              .where((e) => e.value.first.patientName
                                  .toLowerCase()
                                  .contains(searchVerified.toLowerCase()))
                              .map((e) {
                            final patientId = e.key;
                            final name = e.value.first.patientName;
                            final entries = e.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.verified,
                                    color: Colors.green),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                    'Verified entries: ${entries.length}'),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VerifiedHistoryPage(
                                        patientId: patientId,
                                        patientName: name,
                                        entries: entries,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackPage()),
            );
          },
          backgroundColor: Colors.orange.shade700,
          tooltip: 'Send Feedback',
          child: const Icon(Icons.flag, color: Colors.white),
        ),
      ),
    );
  }
}
