import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/data/repositories/teacher_repository.dart';
import 'package:markmeapp/presentation/widgets/ui/alert_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/app_bar.dart';
import 'package:markmeapp/presentation/widgets/ui/calendar.dart';
import 'package:markmeapp/presentation/widgets/ui/dropdown.dart';
import 'package:markmeapp/presentation/widgets/ui/input_field.dart';
import 'package:intl/intl.dart';

class RaiseExceptionPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? sessionData;

  const RaiseExceptionPage({super.key, this.sessionData});

  @override
  ConsumerState<RaiseExceptionPage> createState() => _RaiseExceptionPageState();
}

class _RaiseExceptionPageState extends ConsumerState<RaiseExceptionPage> {
  // Form State
  String _selectedAction = 'Cancel';
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  // Data State
  List<dynamic> _availableClasses = [];
  List<dynamic> _availableSessions = [];
  Map<String, dynamic> _timetableData = {};
  List<int> _activeWeekdays = [];

  String? _selectedSessionId;
  String? _selectedClassId;

  // UI State
  bool _isLoading = false;
  bool _isInitializing = false;
  Map<String, dynamic>? _overlapData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Only pre-fill date if coming from a specific session
    if (widget.sessionData != null) {
      _selectedSessionId = widget.sessionData!['session_id'];
      final sessionDate = widget.sessionData!['date'];
      if (sessionDate != null && sessionDate.isNotEmpty) {
        _selectedDate = DateTime.tryParse(sessionDate);
        if (_selectedDate != null) {
          _dateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(_selectedDate!);
        }
      }
    }

    _initializeData();
  }

  void _initializeData() async {
    if (mounted) {
      setState(() => _isInitializing = true);
    }

    try {
      if (widget.sessionData == null) {
        await Future.wait([_fetchTimetable(), _fetchClasses()]);
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // Parse timetable data
  void _parseTimetableWeekdays(Map<String, dynamic> data) {
    final Map<String, int> dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };

    final activeWeekdays = <int>{};
    data.forEach((key, value) {
      if (dayMap.containsKey(key) && (value as List).isNotEmpty) {
        activeWeekdays.add(dayMap[key]!);
      }
    });

    setState(() {
      _activeWeekdays = activeWeekdays.toList()..sort();
    });
  }

  // Fetch timetable data
  Future<void> _fetchTimetable() async {
    try {
      final repo = ref.read(teacherRepositoryProvider);
      final result = await repo.fetchTimeTable();

      if (mounted && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;

        setState(() {
          _timetableData = data;
          _parseTimetableWeekdays(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
    }
  }

  Future<void> _fetchClasses() async {
    try {
      final repo = ref.read(teacherRepositoryProvider);
      final result = await repo.fetchClassForNotification();

      if (mounted && result['success'] == true) {
        setState(() {
          _availableClasses = result['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  void _updateAvailableSessions() {
    if (_selectedDate == null || _timetableData.isEmpty) {
      setState(() {
        _availableSessions = [];
        _selectedSessionId = null;
      });
      return;
    }

    final dayName = DateFormat('EEEE').format(_selectedDate!);
    final sessions = (_timetableData[dayName] as List<dynamic>?) ?? [];

    setState(() {
      _availableSessions = sessions;
      if (_selectedSessionId != null &&
          !_availableSessions.any(
            (s) => s['session_id'].toString() == _selectedSessionId,
          )) {
        _selectedSessionId = null;
      }
    });
  }

  // --- Actions ---

  Future<void> _handleDateSelection(DateTime? picked) async {
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _overlapData = null;
        _selectedSessionId = null;
      });

      if (widget.sessionData == null) {
        _updateAvailableSessions();
      }
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart ? _selectedStartTime : _selectedEndTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _selectedEndTime = picked;
          _endTimeController.text = picked.format(context);
        }
        _overlapData = null;
      });
    }
  }

  // Check if form is valid
  bool get _isFormValid {
    if (_reasonController.text.trim().isEmpty) return false;

    switch (_selectedAction) {
      case 'Add':
        return _selectedDate != null &&
            _selectedClassId != null &&
            _selectedStartTime != null &&
            _selectedEndTime != null &&
            _selectedEndTime!.hour * 60 + _selectedEndTime!.minute >
                _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;

      case 'Cancel':
        return _selectedSessionId != null;

      case 'Reschedule':
        return _selectedSessionId != null &&
            _selectedDate != null &&
            _selectedStartTime != null &&
            _selectedEndTime != null &&
            _selectedEndTime!.hour * 60 + _selectedEndTime!.minute >
                _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;

      default:
        return false;
    }
  }

  void _handleSubmit({bool confirmSwap = false}) async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (!confirmSwap) _overlapData = null;
    });

    try {
      final repo = ref.read(teacherRepositoryProvider);

      String? startTimeStr;
      String? endTimeStr;

      if (_selectedAction != 'Cancel') {
        startTimeStr =
            '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:'
            '${_selectedStartTime!.minute.toString().padLeft(2, '0')}';
        endTimeStr =
            '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:'
            '${_selectedEndTime!.minute.toString().padLeft(2, '0')}';
      }

      final effectiveSessionId = _selectedAction == 'Add'
          ? _selectedClassId!
          : _selectedSessionId!;

      final result = await repo.raiseSessionException(
        sessionId: effectiveSessionId,
        date: _dateController.text,
        action: _selectedAction,
        reason: _reasonController.text.trim(),
        newStartTime: startTimeStr,
        newEndTime: endTimeStr,
        confirmSwap: confirmSwap,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccess(result['message']);
          context.pop(true);
        } else if (result['code'] == 'OVERLAP_FOUND') {
          setState(() {
            _overlapData = result['data'];
            _isLoading = false;
          });
          _showConflictDialog();
        } else {
          _showError(result['message'] ?? 'Failed to submit request');
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted && _overlapData == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConflictDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict Detected'),
        content: Text(
          'This session overlaps with ${_overlapData?['conflicting_teacher']} (${_overlapData?['time']}). Do you want to apply for a swap?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _overlapData = null);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSubmit(confirmSwap: true);
            },
            child: const Text('Apply for Swap'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    setState(() {
      _errorMessage = msg;
      _isLoading = false;
    });
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: MarkMeAppBar(
          title: 'Raise Exception',
          onBackPressed: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: MarkMeAppBar(
        title: 'Raise Exception',
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                AlertBar(
                  type: AlertType.error,
                  title: 'Error',
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),

              _buildActionSelector(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: ['Cancel', 'Add Extra', 'Reschedule'].map((action) {
          final mapValues = {
            'Cancel': 'Cancel',
            'Add Extra': 'Add',
            'Reschedule': 'Reschedule',
          };
          final apiValue = mapValues[action]!;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAction = apiValue;
                  _overlapData = null;
                  _errorMessage = null;
                  if (_selectedAction == 'Cancel') {
                    _selectedStartTime = null;
                    _selectedEndTime = null;
                    _startTimeController.clear();
                    _endTimeController.clear();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedAction == apiValue
                      ? const Color(0xFF2563EB)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedAction == apiValue
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForm() {
    final requiresTime = _selectedAction != 'Cancel';
    final isAddMode = _selectedAction == 'Add';
    final isStandalone = widget.sessionData == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Date Picker
        _buildDatePicker(),
        const SizedBox(height: 20),

        // 2. Session/Class Selector (Standalone only)
        if (isStandalone) ...[
          if (isAddMode) _buildClassSelector() else _buildSessionSelector(),
          const SizedBox(height: 20),
        ],

        // 3. Time Fields
        if (requiresTime) ...[_buildTimePickers(), const SizedBox(height: 20)],

        // 4. Reason Input
        InputField(
          controller: _reasonController,
          hintText: 'Reason for exception',
          label: 'Reason',
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Calendar(
      controller: _dateController,
      label: 'Date',
      hintText: 'Select Date',
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      onDateSelected: _handleDateSelection,
      selectableDayPredicate: (date) {
        if (_selectedAction == 'Add') return true;
        if (_activeWeekdays.isEmpty) return true;
        return _activeWeekdays.contains(date.weekday);
      },
    );
  }

  Widget _buildTimePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(true),
                child: AbsorbPointer(
                  child: InputField(
                    controller: _startTimeController,
                    hintText: 'HH:mm',
                    label: 'Start Time',
                    suffixIcon: const Icon(Icons.access_time),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(false),
                child: AbsorbPointer(
                  child: InputField(
                    controller: _endTimeController,
                    hintText: 'HH:mm',
                    label: 'End Time',
                    suffixIcon: const Icon(Icons.access_time_filled),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedStartTime != null && _selectedEndTime != null)
          _buildTimeValidationMessage(),
      ],
    );
  }

  Widget _buildTimeValidationMessage() {
    final startMin = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMin = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;

    if (endMin <= startMin) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(
          'End time must be after start time',
          style: TextStyle(color: Colors.red.shade600, fontSize: 12),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSessionSelector() {
    String getSessionDisplay(String id) {
      final session = _availableSessions.firstWhere(
        (s) => s['session_id'].toString() == id,
        orElse: () => {},
      );
      if (session.isEmpty) return id;
      final subject = session['subject_name'] ?? 'Unknown Subject';
      final time = '${session['start_time']} - ${session['end_time']}';
      return '$subject ($time)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Dropdown<String>(
          label: 'Select Session',
          hint: 'Select a session',
          items: _availableSessions
              .map<String>((s) => s['session_id'].toString())
              .toList(),
          value: _selectedSessionId,
          onChanged: (val) {
            setState(() {
              _selectedSessionId = val;
            });
          },
          displayText: getSessionDisplay,
        ),
        if (_availableSessions.isEmpty && _selectedDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'No sessions found for selected date',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildClassSelector() {
    // Flatten subjects for easier lookup and display
    final List<Map<String, dynamic>> flatSubjects = [];
    for (var cls in _availableClasses) {
      final subjects = cls['subjects'] as List<dynamic>? ?? [];
      final className = cls['class_name'] ?? '';
      for (var sub in subjects) {
        flatSubjects.add({
          'id': sub['subject_id'].toString(),
          'display':
              '${sub['subject_name']} (${sub['component']}) - $className',
        });
      }
    }

    String getClassDisplay(String id) {
      final found = flatSubjects.firstWhere(
        (element) => element['id'] == id,
        orElse: () => {'display': id},
      );
      return found['display'];
    }

    return Dropdown<String>(
      label: 'Select Subject/Class',
      hint: 'Select a class',
      items: flatSubjects.map<String>((e) => e['id'] as String).toList(),
      value: _selectedClassId,
      onChanged: (val) => setState(() => _selectedClassId = val),
      displayText: getClassDisplay,
    );
  }

  Widget _buildSubmitButton() {
    final isFormValid = _isFormValid;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || !isFormValid
            ? null
            : () => _handleSubmit(confirmSwap: false),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid
              ? const Color(0xFF2563EB)
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Submit Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isFormValid ? Colors.white : Colors.grey.shade200,
                ),
              ),
      ),
    );
  }
}
