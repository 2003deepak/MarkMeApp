import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:markmeapp/data/repositories/student_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';

class WeeklyBunkSafetyPage extends ConsumerStatefulWidget {
  const WeeklyBunkSafetyPage({super.key});

  @override
  ConsumerState<WeeklyBunkSafetyPage> createState() =>
      _WeeklyBunkSafetyPageState();
}

class _WeeklyBunkSafetyPageState extends ConsumerState<WeeklyBunkSafetyPage> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final repo = ref.read(studentRepositoryProvider);
      final response = await repo.fetchWeeklyBunkSafety();

      if (response['success'] == true) {
        setState(() {
          data = response['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['error'] ?? 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MarkMeAppBar(
        title: 'Weekly Bunk Monitor',
        onBackPressed: () => context.pop(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                _fetchData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final weekPlan = (data?['week_plan'] as List?) ?? [];

    if (weekPlan.isEmpty) {
      return const Center(child: Text('No data for this week'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: weekPlan.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildDayCard(weekPlan[index]);
      },
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayData) {
    final bool safeToBunk = dayData['safe_to_bunk'] ?? false;
    final String dateStr = dayData['date'] ?? '';
    final String weekday = dayData['weekday'] ?? '';
    final List subjects = dayData['subjects'] ?? [];
    final aggregate = dayData['aggregate'] ?? {};

    final color = safeToBunk ? Colors.green : Colors.orange;

    // Parse date for cleaner display if needed, but weekday is provided
    DateTime? date;
    String formattedDate = dateStr;
    try {
      date = DateTime.parse(dateStr);
      formattedDate = DateFormat('MMM d').format(date);
    } catch (_) {}

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              safeToBunk
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: color,
            ),
          ),
          title: Text(
            '$weekday, $formattedDate',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            safeToBunk ? 'Safe to Bunk' : 'Attend Recommended',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            if (subjects.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No classes scheduled',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...subjects.map((s) => _buildSubjectItem(s)).toList(),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Aggregate: ${(aggregate['current'] as num?)?.toStringAsFixed(2)}%',
                  ),
                  Text(
                    'If Bunk: ${(aggregate['if_bunk'] as num?)?.toStringAsFixed(2)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectItem(Map<String, dynamic> subject) {
    final name = subject['subject_name'] ?? 'Unknown';
    final component = subject['component'] ?? 'Lecture';
    var safe =
        subject['safe'] ??
        false; // Note: API might return string or boolean, prompt says boolean
    final attNow = (subject['attendance_now'] as num?)?.toDouble() ?? 0.0;
    final attIfBunk =
        (subject['attendance_if_bunk'] as num?)?.toDouble() ?? 0.0;

    final itemColor = safe ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: itemColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  component,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${attNow.toStringAsFixed(1)}% -> ${attIfBunk.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                safe ? 'Safe' : 'Risk',
                style: TextStyle(
                  fontSize: 10,
                  color: itemColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
