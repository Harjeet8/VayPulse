class DiseaseCandidate {
  final String nameKey;
  final String categoryKey;
  final String reasonKey;
  final String inspectionKey;
  final int matchScore;

  const DiseaseCandidate({
    required this.nameKey,
    required this.categoryKey,
    required this.reasonKey,
    required this.inspectionKey,
    required this.matchScore,
  });
}

enum FieldObservation { yes, no, uncertain }

class DiseaseSymptomAnswers {
  final FieldObservation? concentricRings;
  final FieldObservation? waterSoakedLesions;
  final FieldObservation? yellowHalos;
  final FieldObservation? leafCurling;
  final FieldObservation? whitefliesPresent;

  const DiseaseSymptomAnswers({
    this.concentricRings,
    this.waterSoakedLesions,
    this.yellowHalos,
    this.leafCurling,
    this.whitefliesPresent,
  });

  bool get isComplete =>
      concentricRings != null &&
      waterSoakedLesions != null &&
      yellowHalos != null &&
      leafCurling != null &&
      whitefliesPresent != null;

  bool get hasAnswers =>
      concentricRings != null ||
      waterSoakedLesions != null ||
      yellowHalos != null ||
      leafCurling != null ||
      whitefliesPresent != null;

  DiseaseSymptomAnswers copyWith({
    FieldObservation? concentricRings,
    FieldObservation? waterSoakedLesions,
    FieldObservation? yellowHalos,
    FieldObservation? leafCurling,
    FieldObservation? whitefliesPresent,
  }) =>
      DiseaseSymptomAnswers(
        concentricRings: concentricRings ?? this.concentricRings,
        waterSoakedLesions: waterSoakedLesions ?? this.waterSoakedLesions,
        yellowHalos: yellowHalos ?? this.yellowHalos,
        leafCurling: leafCurling ?? this.leafCurling,
        whitefliesPresent: whitefliesPresent ?? this.whitefliesPresent,
      );
}

class DiseaseAssessment {
  final String crop;
  final List<DiseaseCandidate> candidates;
  final List<String> evidenceKeys;
  final bool usedSensorEvidence;
  final bool usedWeatherEvidence;
  final bool sensorTriggered;
  final bool isInconclusive;

  const DiseaseAssessment({
    required this.crop,
    required this.candidates,
    required this.evidenceKeys,
    required this.usedSensorEvidence,
    required this.usedWeatherEvidence,
    required this.sensorTriggered,
    this.isInconclusive = false,
  });
}

class DiseasePhotoPrompt {
  final bool shouldPrompt;
  final bool urgent;
  final List<String> reasonKeys;

  const DiseasePhotoPrompt({
    required this.shouldPrompt,
    required this.urgent,
    required this.reasonKeys,
  });

  static const none = DiseasePhotoPrompt(
    shouldPrompt: false,
    urgent: false,
    reasonKeys: [],
  );
}
