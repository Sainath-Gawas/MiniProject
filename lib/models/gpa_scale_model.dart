class GPAScale {
  final List<GPARange> ranges;

  GPAScale({required this.ranges});

  // Default GPA scale (10-point system)
  factory GPAScale.defaultScale() {
    return GPAScale(
      ranges: [
        GPARange(minPercentage: 85.0, maxPercentage: 100.0, gpa: 10.0),
        GPARange(minPercentage: 75.0, maxPercentage: 84.99, gpa: 9.0),
        GPARange(minPercentage: 65.0, maxPercentage: 74.99, gpa: 8.0),
        GPARange(minPercentage: 55.0, maxPercentage: 64.99, gpa: 7.0),
        GPARange(minPercentage: 45.0, maxPercentage: 54.99, gpa: 6.0),
        GPARange(minPercentage: 35.0, maxPercentage: 44.99, gpa: 5.0),
        GPARange(minPercentage: 0.0, maxPercentage: 34.99, gpa: 0.0),
      ],
    );
  }

  double getGPA(double percentage) {
    for (var range in ranges) {
      if (percentage >= range.minPercentage && percentage <= range.maxPercentage) {
        return range.gpa;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'ranges': ranges.map((r) => r.toMap()).toList(),
    };
  }

  factory GPAScale.fromMap(Map<String, dynamic> data) {
    final rangesData = (data['ranges'] as List<dynamic>?) ?? [];
    return GPAScale(
      ranges: rangesData.map((r) => GPARange.fromMap(r)).toList(),
    );
  }
}

class GPARange {
  final double minPercentage;
  final double maxPercentage;
  final double gpa;

  GPARange({
    required this.minPercentage,
    required this.maxPercentage,
    required this.gpa,
  });

  Map<String, dynamic> toMap() {
    return {
      'minPercentage': minPercentage,
      'maxPercentage': maxPercentage,
      'gpa': gpa,
    };
  }

  factory GPARange.fromMap(Map<String, dynamic> data) {
    return GPARange(
      minPercentage: (data['minPercentage'] ?? 0.0).toDouble(),
      maxPercentage: (data['maxPercentage'] ?? 100.0).toDouble(),
      gpa: (data['gpa'] ?? 0.0).toDouble(),
    );
  }
}






