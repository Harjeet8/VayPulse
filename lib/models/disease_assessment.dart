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
  final FieldObservation? mealybugsPresent;
  final FieldObservation? aphidsPresent;
  final FieldObservation? visibleSpotting;
  final FieldObservation? surfaceDamage;

  const DiseaseSymptomAnswers({
    this.concentricRings,
    this.waterSoakedLesions,
    this.yellowHalos,
    this.leafCurling,
    this.whitefliesPresent,
    this.mealybugsPresent,
    this.aphidsPresent,
    this.visibleSpotting,
    this.surfaceDamage,
  });

  bool get isComplete => isTomatoComplete;

  bool get isTomatoComplete =>
      concentricRings != null &&
      waterSoakedLesions != null &&
      yellowHalos != null &&
      leafCurling != null &&
      whitefliesPresent != null;

  bool get isHibiscusComplete =>
      whitefliesPresent != null &&
      mealybugsPresent != null &&
      aphidsPresent != null &&
      visibleSpotting != null &&
      surfaceDamage != null;

  bool get hasAnswers =>
      concentricRings != null ||
      waterSoakedLesions != null ||
      yellowHalos != null ||
      leafCurling != null ||
      whitefliesPresent != null ||
      mealybugsPresent != null ||
      aphidsPresent != null ||
      visibleSpotting != null ||
      surfaceDamage != null;

  bool get hasPositiveObservation => <FieldObservation?>[
        concentricRings,
        waterSoakedLesions,
        yellowHalos,
        leafCurling,
        whitefliesPresent,
        mealybugsPresent,
        aphidsPresent,
        visibleSpotting,
        surfaceDamage,
      ].contains(FieldObservation.yes);

  DiseaseSymptomAnswers copyWith({
    FieldObservation? concentricRings,
    FieldObservation? waterSoakedLesions,
    FieldObservation? yellowHalos,
    FieldObservation? leafCurling,
    FieldObservation? whitefliesPresent,
    FieldObservation? mealybugsPresent,
    FieldObservation? aphidsPresent,
    FieldObservation? visibleSpotting,
    FieldObservation? surfaceDamage,
  }) =>
      DiseaseSymptomAnswers(
        concentricRings: concentricRings ?? this.concentricRings,
        waterSoakedLesions: waterSoakedLesions ?? this.waterSoakedLesions,
        yellowHalos: yellowHalos ?? this.yellowHalos,
        leafCurling: leafCurling ?? this.leafCurling,
        whitefliesPresent: whitefliesPresent ?? this.whitefliesPresent,
        mealybugsPresent: mealybugsPresent ?? this.mealybugsPresent,
        aphidsPresent: aphidsPresent ?? this.aphidsPresent,
        visibleSpotting: visibleSpotting ?? this.visibleSpotting,
        surfaceDamage: surfaceDamage ?? this.surfaceDamage,
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
