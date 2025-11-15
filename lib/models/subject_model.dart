class Subject {
  final String? id;
  final String name;
  final double targetAttendancePercentage;
  final int totalClassesConducted;
  final int classesAttended;
  
  // Marks Configuration
  final double targetOverallPercentage; // Target overall marks %
  final int numberOfITs; // Y - Number of Internal Test Attempts
  final int bestITsToConsider; // X - Number of Best Internal Tests to Consider
  final double maxMarksPerIT; // Max Marks for Single Internal Test (also cap for IT Average)
  final double maxMarksPerAssignment; // Max Marks for Single Assignment
  final double maxInternalComponent; // Max Marks for Internal Component Final
  final double maxSemesterEndExam; // Max Marks for Semester End Exam Component
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Subject({
    required this.id,
    required this.name,
    this.targetAttendancePercentage = 75.0,
    this.totalClassesConducted = 0,
    this.classesAttended = 0,
    this.targetOverallPercentage = 80.0,
    this.numberOfITs = 0,
    this.bestITsToConsider = 0,
    this.maxMarksPerIT = 0.0,
    this.maxMarksPerAssignment = 0.0,
    this.maxInternalComponent = 0.0,
    this.maxSemesterEndExam = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory Subject.fromMap(String id, Map<String, dynamic> data) {
    return Subject(
      id: id,
      name: data['name'] ?? '',
      targetAttendancePercentage: (data['targetAttendancePercentage'] ?? 75.0).toDouble(),
      totalClassesConducted: data['totalClassesConducted'] ?? 0,
      classesAttended: data['classesAttended'] ?? 0,
      targetOverallPercentage: (data['targetOverallPercentage'] ?? 80.0).toDouble(),
      numberOfITs: data['numberOfITs'] ?? 0,
      bestITsToConsider: data['bestITsToConsider'] ?? 0,
      maxMarksPerIT: (data['maxMarksPerIT'] ?? 0.0).toDouble(),
      maxMarksPerAssignment: (data['maxMarksPerAssignment'] ?? 0.0).toDouble(),
      maxInternalComponent: (data['maxInternalComponent'] ?? 0.0).toDouble(),
      maxSemesterEndExam: (data['maxSemesterEndExam'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAttendancePercentage': targetAttendancePercentage,
      'totalClassesConducted': totalClassesConducted,
      'classesAttended': classesAttended,
      'targetOverallPercentage': targetOverallPercentage,
      'numberOfITs': numberOfITs,
      'bestITsToConsider': bestITsToConsider,
      'maxMarksPerIT': maxMarksPerIT,
      'maxMarksPerAssignment': maxMarksPerAssignment,
      'maxInternalComponent': maxInternalComponent,
      'maxSemesterEndExam': maxSemesterEndExam,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  double get currentAttendancePercentage {
    if (totalClassesConducted == 0) return 0.0;
    return (classesAttended / totalClassesConducted) * 100;
  }

  bool get isOnTrack =>
      currentAttendancePercentage >= targetAttendancePercentage;

  int get classesMissed => totalClassesConducted - classesAttended;

  // ============= MARKS CALCULATION METHODS =============
  // These methods take a list of exams and calculate marks according to the rules
  // Note: Import Exam model where these are used

  /// Step 1: Calculate Raw IT Average (Best X of Y)
  double calculateRawITAverage(List exams) {
    final itExams = exams
        .where((e) {
          final typeStr = e.type.toString().split('.').last;
          return typeStr == 'internal' && e.marksObtained > 0;
        })
        .toList();
    
    if (itExams.isEmpty || bestITsToConsider == 0) return 0.0;

    // Sort by marks obtained descending
    itExams.sort((a, b) => b.marksObtained.compareTo(a.marksObtained));

    // Take best X
    final bestITs = itExams.take(bestITsToConsider).toList();
    if (bestITs.isEmpty) return 0.0;

    // Calculate average
    final sum = bestITs.fold<double>(0.0, (prev, e) => prev + e.marksObtained);
    return sum / bestITs.length;
  }

  /// Step 2: Apply CEIL Rounding and Cap to IT Average
  double calculateFinalCappedITAverage(List exams) {
    final rawAvg = calculateRawITAverage(exams);
    final rounded = rawAvg.ceilToDouble();
    return rounded > maxMarksPerIT ? maxMarksPerIT : rounded;
  }

  /// Step 3: Calculate Raw Assignment Marks (Sum of all assignments)
  double calculateRawAssignmentMarks(List exams) {
    final assignmentExams = exams
        .where((e) {
          final typeStr = e.type.toString().split('.').last;
          return typeStr == 'assignment' && e.marksObtained > 0;
        })
        .toList();
    
    return assignmentExams.fold<double>(
      0.0,
      (prev, e) => prev + e.marksObtained,
    );
  }

  /// Step 4: Calculate Total Internal Raw Score
  double calculateTotalInternalRawScore(List exams) {
    return calculateFinalCappedITAverage(exams) + calculateRawAssignmentMarks(exams);
  }

  /// Step 5: Determine Max Possible Total Internal Raw Score
  double get maxPossibleTotalInternalRawScore {
    return maxMarksPerIT + maxMarksPerAssignment;
  }

  /// Step 6: Calculate Final Internal Component Score (Scaled)
  double calculateFinalInternalComponentScore(List exams) {
    if (maxPossibleTotalInternalRawScore == 0) return 0.0;
    final totalRaw = calculateTotalInternalRawScore(exams);
    return (totalRaw / maxPossibleTotalInternalRawScore) * maxInternalComponent;
  }

  /// Step 7: Calculate Semester End Exam Score
  double calculateSemesterEndExamScore(List exams) {
    try {
      final semExam = exams.firstWhere(
        (e) {
          final typeStr = e.type.toString().split('.').last;
          return typeStr == 'semester' && e.marksObtained > 0;
        },
      );
      return semExam.marksObtained;
    } catch (e) {
      return 0.0;
    }
  }

  /// Step 8: Calculate Overall Subject Marks
  double calculateOverallSubjectMarks(List exams) {
    return calculateFinalInternalComponentScore(exams) + calculateSemesterEndExamScore(exams);
  }

  /// Step 9: Calculate Overall Subject Percentage
  double calculateOverallSubjectPercentage(List exams) {
    final totalPossible = maxInternalComponent + maxSemesterEndExam;
    if (totalPossible == 0) return 0.0;
    final overallMarks = calculateOverallSubjectMarks(exams);
    return (overallMarks / totalPossible) * 100;
  }

  /// Step 10: Calculate Subject GPA (requires GPAScale)
  double calculateSubjectGPA(List exams, dynamic gpaScale) {
    final percentage = calculateOverallSubjectPercentage(exams);
    return gpaScale?.getGPA(percentage) ?? 0.0;
  }
}



