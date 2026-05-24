import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../bookings/data/booking_repository.dart';

class DatabaseExplorerScreen extends HookConsumerWidget {
  const DatabaseExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseClientProvider);
    final sqlController = useTextEditingController(text: 'SELECT * FROM vehicles LIMIT 10');
    final isExecuting = useState(false);
    final results = useState<List<Map<String, dynamic>>?>(null);
    final successMessage = useState<String?>(null);
    final errorMessage = useState<String?>(null);
    final columns = useState<List<String>>([]);

    // Query templates
    final templates = [
      {'label': 'Fetch Vehicles', 'sql': 'SELECT * FROM vehicles ORDER BY created_at DESC LIMIT 10'},
      {'label': 'Fetch Bookings', 'sql': 'SELECT * FROM bookings ORDER BY created_at DESC LIMIT 10'},
      {'label': 'Fetch Partners', 'sql': 'SELECT * FROM partners ORDER BY created_at DESC LIMIT 10'},
      {'label': 'Fetch Profiles', 'sql': 'SELECT * FROM profiles LIMIT 10'},
      {'label': 'Fetch Payments', 'sql': 'SELECT * FROM payments ORDER BY created_at DESC LIMIT 10'},
      {'label': 'Add Custom Column example', 'sql': 'ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS test_badge VARCHAR(50)'},
    ];

    Future<void> runQuery() async {
      final query = sqlController.text.trim();
      if (query.isEmpty) return;

      isExecuting.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      results.value = null;
      columns.value = [];

      try {
        final response = await supabase.rpc('exec_sql', params: {'query_text': query});
        
        final dataMap = response as Map<String, dynamic>?;
        if (dataMap == null) {
          successMessage.value = 'Command executed successfully (no returned data).';
        } else if (dataMap.containsKey('error')) {
          errorMessage.value = dataMap['error'].toString();
        } else if (dataMap.containsKey('message')) {
          successMessage.value = dataMap['message'].toString();
        } else if (dataMap.containsKey('data')) {
          final rawData = dataMap['data'];
          if (rawData is List) {
            final list = rawData.cast<Map<String, dynamic>>();
            results.value = list;
            if (list.isNotEmpty) {
              columns.value = list.first.keys.toList();
            } else {
              successMessage.value = 'Query returned 0 rows.';
            }
          } else {
            successMessage.value = 'Query executed successfully.';
          }
        } else {
          successMessage.value = 'Query finished: $response';
        }
      } catch (e) {
        errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      } finally {
        isExecuting.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Database Explorer & Console',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header instructions
            const Text(
              'SpaceRent Kosovo Hub Controls',
              style: TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            const Text(
              'Execute direct DDL/DML statements or browse database tables.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Templates Row
            const Text(
              'SQL Templates:',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: templates.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF16162B),
                      labelStyle: const TextStyle(color: Color(0xFF00CEC9), fontSize: 11, fontWeight: FontWeight.bold),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                      label: Text(t['label']!),
                      onPressed: () {
                        sqlController.text = t['sql']!;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Query Input Box
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16162B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: sqlController,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'Courier', color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter SQL Query...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isExecuting.value ? null : runQuery,
                        icon: isExecuting.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Execute Query', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Console outputs & Results
            const Text(
              'Execution Output:',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF16162B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.all(16),
                child: () {
                  if (isExecuting.value) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
                  }
                  if (errorMessage.value != null) {
                    return SingleChildScrollView(
                      child: Text(
                        'SQL Error:\n${errorMessage.value}',
                        style: const TextStyle(color: Colors.redAccent, fontFamily: 'Courier', fontSize: 13),
                      ),
                    );
                  }
                  if (successMessage.value != null) {
                    return Text(
                      successMessage.value!,
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 13),
                    );
                  }
                  if (results.value != null) {
                    final data = results.value!;
                    final cols = columns.value;

                    return Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 12),
                            columns: cols.map((col) => DataColumn(label: Text(col))).toList(),
                            rows: data.map((row) {
                              return DataRow(
                                cells: cols.map((col) {
                                  final val = row[col];
                                  return DataCell(Text(
                                    val?.toString() ?? 'NULL',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ));
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  }
                  return const Center(
                    child: Text(
                      'No query executed yet.',
                      style: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  );
                }(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
