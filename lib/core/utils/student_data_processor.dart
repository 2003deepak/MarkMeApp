class StudentDataProcessor {
  final Map<String, dynamic>? rawData;
  final Map<String, Map<String, dynamic>> subjectData;
  final Map<String, Map<String, dynamic>> componentData;

  StudentDataProcessor({
    this.rawData,
    this.subjectData = const {},
    this.componentData = const {},
  });

  Map<String, Map<String, dynamic>> processSubjectData() {
    if (rawData == null) return {};

    final List<dynamic> attendances = rawData!['attendances'] ?? [];
    final Map<String, Map<String, dynamic>> processedData = {};

    for (var attendance in attendances) {
      final attendanceMap = Map<String, dynamic>.from(attendance);
      final subjectName = attendanceMap['subject_name'] as String;
      final totalClasses = attendanceMap['total_classes'] as int;
      final attended = attendanceMap['attended'] as int;

      if (!processedData.containsKey(subjectName)) {
        processedData[subjectName] = {
          'totalLectures': 0,
          'attendedLectures': 0,
          'percentage': 0.0,
        };
      }

      final currentData = processedData[subjectName]!;
      processedData[subjectName] = {
        'totalLectures': currentData['totalLectures'] + totalClasses,
        'attendedLectures': currentData['attendedLectures'] + attended,
        'percentage': 0.0,
      };
    }

    // Calculate percentages
    for (var subject in processedData.keys) {
      final data = processedData[subject]!;
      final total = data['totalLectures'] as int;
      final attended = data['attendedLectures'] as int;
      final percentage = total > 0 ? (attended / total) * 100 : 0.0;

      processedData[subject] = {
        'totalLectures': total,
        'attendedLectures': attended,
        'percentage': double.parse(percentage.toStringAsFixed(2)),
      };
    }

    return processedData;
  }

  Map<String, Map<String, dynamic>> processComponentData() {
    if (rawData == null) return {};

    final List<dynamic> attendances = rawData!['attendances'] ?? [];
    final Map<String, Map<String, dynamic>> processedData = {};

    for (var attendance in attendances) {
      final attendanceMap = Map<String, dynamic>.from(attendance);
      final subjectName = attendanceMap['subject_name'] as String;
      final component = attendanceMap['component'] as String;
      final totalClasses = attendanceMap['total_classes'] as int;
      final attended = attendanceMap['attended'] as int;
      final percentage = attendanceMap['percentage'] as double;

      final componentKey = "$subjectName - $component";

      processedData[componentKey] = {
        'totalLectures': totalClasses,
        'attendedLectures': attended,
        'percentage': percentage,
        'component': component,
        'subjectName': subjectName,
      };
    }

    return processedData;
  }

  Map<String, dynamic>? getSelectedData(String? selectedSubject) {
    if (selectedSubject == null) {
      return _getAllSubjectsData();
    } else if (selectedSubject == 'all-lectures') {
      return _getAllLecturesData();
    } else if (selectedSubject == 'all-labs') {
      return _getAllLabsData();
    } else if (componentData.containsKey(selectedSubject)) {
      return componentData[selectedSubject];
    } else if (subjectData.containsKey(selectedSubject)) {
      return subjectData[selectedSubject];
    }
    return null;
  }

  Map<String, dynamic> _getAllSubjectsData() {
    int totalLectures = 0;
    int totalAttended = 0;

    for (var subject in subjectData.values) {
      totalLectures += subject['totalLectures'] as int;
      totalAttended += subject['attendedLectures'] as int;
    }

    final percentage = totalLectures > 0
        ? (totalAttended / totalLectures) * 100
        : 0.0;

    return {
      'totalLectures': totalLectures,
      'attendedLectures': totalAttended,
      'percentage': double.parse(percentage.toStringAsFixed(2)),
      'type': 'all_subjects',
    };
  }

  Map<String, dynamic> _getAllLecturesData() {
    int totalLectures = 0;
    int totalAttended = 0;

    for (var componentKey in componentData.keys) {
      final data = componentData[componentKey]!;
      if (data['component'] == 'Lecture') {
        totalLectures += data['totalLectures'] as int;
        totalAttended += data['attendedLectures'] as int;
      }
    }

    final percentage = totalLectures > 0
        ? (totalAttended / totalLectures) * 100
        : 0.0;

    return {
      'totalLectures': totalLectures,
      'attendedLectures': totalAttended,
      'percentage': double.parse(percentage.toStringAsFixed(2)),
      'type': 'all_lectures',
    };
  }

  Map<String, dynamic> _getAllLabsData() {
    int totalLectures = 0;
    int totalAttended = 0;

    for (var componentKey in componentData.keys) {
      final data = componentData[componentKey]!;
      if (data['component'] == 'Lab') {
        totalLectures += data['totalLectures'] as int;
        totalAttended += data['attendedLectures'] as int;
      }
    }

    final percentage = totalLectures > 0
        ? (totalAttended / totalLectures) * 100
        : 0.0;

    return {
      'totalLectures': totalLectures,
      'attendedLectures': totalAttended,
      'percentage': double.parse(percentage.toStringAsFixed(2)),
      'type': 'all_labs',
    };
  }
}
