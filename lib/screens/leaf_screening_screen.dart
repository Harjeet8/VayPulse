import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/crop_catalog.dart';
import '../models/disease_assessment.dart';
import '../models/edge_intelligence.dart';
import '../models/leaf_screening_result.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/leaf_screening_service.dart';
import '../services/multimodal_disease_service.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

class LeafScreeningScreen extends StatefulWidget {
  final bool sensorPrompt;

  const LeafScreeningScreen({
    super.key,
    this.sensorPrompt = false,
  });

  @override
  State<LeafScreeningScreen> createState() => _LeafScreeningScreenState();
}

class _LeafScreeningScreenState extends State<LeafScreeningScreen> {
  final _picker = ImagePicker();
  Uint8List? imageBytes;
  LeafScreeningResult? result;
  DiseaseAssessment? assessment;
  bool analyzing = false;
  String? errorKey;
  String? selectedCrop;
  bool cropConfirmed = false;
  bool cropInitialized = false;
  DiseaseSymptomAnswers symptomAnswers = const DiseaseSymptomAnswers();

  bool get _isTomato {
    final crop = selectedCrop?.toLowerCase() ?? '';
    return crop.contains('tomato');
  }

  bool get _isHibiscus {
    final crop = selectedCrop?.toLowerCase() ?? '';
    return crop.contains('hibiscus');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (cropInitialized) return;
    final scope = AppScope.of(context);
    final fieldCrop = scope.farms.selectedField.crop;
    final hardwareCrop = scope
            .sensors.edgeIntelligence?.cameraHandoff.crop ??
        scope.sensors.hardwareTelemetry?.cropProfile ??
        scope.sensors.edgeIntelligence?.cropProfile.profile;
    final preferredCrop = scope.sensors.source == SensorDataSource.esp32
        ? hardwareCrop ?? fieldCrop
        : fieldCrop;
    selectedCrop = CropCatalog.profileFor(preferredCrop).name;
    cropInitialized = true;
  }

  Future<void> _pick(ImageSource source) async {
    if (!cropConfirmed || selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('crop_confirmation_required'))),
      );
      return;
    }
    try {
      await HapticFeedback.selectionClick();
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        imageBytes = bytes;
        result = null;
        assessment = null;
        errorKey = null;
        analyzing = true;
        symptomAnswers = const DiseaseSymptomAnswers();
      });
      final scope = AppScope.of(context);
      final cameraPrompt = widget.sensorPrompt &&
          scope.sensors.source == SensorDataSource.esp32 &&
          scope.sensors.edgeIntelligence?.cameraInspectionRecommended == true;
      final nodeId = scope.sensors.selectedNodeId;
      if (cameraPrompt) {
        await scope.inspectionHistory.recordStarted(nodeId);
        if (!mounted) return;
      }
      final screening = await LeafScreeningService.analyze(bytes);
      if (!mounted) return;
      final diseaseAssessment = _isTomato || _isHibiscus
          ? null
          : MultimodalDiseaseService.assess(
              visual: screening,
              crop: selectedCrop!,
            );
      setState(() {
        result = screening;
        assessment = diseaseAssessment;
        analyzing = false;
      });
      if (cameraPrompt && diseaseAssessment != null) {
        final top = diseaseAssessment.candidates.isEmpty
            ? null
            : diseaseAssessment.candidates.first;
        await scope.inspectionHistory.recordCompleted(
          nodeId,
          visualResultKey: diseaseAssessment.isInconclusive ||
                  top?.nameKey == 'disease_no_clear_match'
              ? null
              : top?.nameKey,
        );
      }
    } on LeafScreeningException catch (error) {
      if (!mounted) return;
      setState(() {
        analyzing = false;
        result = null;
        assessment = null;
        errorKey = error.messageKey;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        analyzing = false;
        errorKey = 'leaf_camera_unavailable';
      });
    }
  }

  void _completeSymptomScreening() {
    final screening = result;
    final crop = selectedCrop;
    final answersComplete = _isHibiscus
        ? symptomAnswers.isHibiscusComplete
        : symptomAnswers.isTomatoComplete;
    if (screening == null || crop == null || !answersComplete) {
      return;
    }
    final completed = MultimodalDiseaseService.assess(
      visual: screening,
      crop: crop,
      symptoms: symptomAnswers,
    );
    setState(() => assessment = completed);
    final scope = AppScope.of(context);
    if (widget.sensorPrompt &&
        scope.sensors.source == SensorDataSource.esp32 &&
        scope.sensors.edgeIntelligence?.cameraInspectionRecommended == true) {
      final top = completed.candidates.isEmpty ? null : completed.candidates.first;
      unawaited(scope.inspectionHistory.recordCompleted(
        scope.sensors.selectedNodeId,
        visualResultKey: completed.isInconclusive ||
                top?.nameKey == 'disease_no_clear_match'
            ? null
            : top?.nameKey,
      ));
    }
  }

  Future<void> _speakResult() async {
    final screening = result;
    if (screening == null) return;
    final scope = AppScope.of(context);
    final candidates = assessment?.candidates ?? const <DiseaseCandidate>[];
    final topCandidate = candidates.isEmpty ? null : candidates.first;
    final candidateText = topCandidate == null
        ? ''
        : '${context.tr('disease_top_match')}: '
            '${context.tr(topCandidate.nameKey)}, '
            '${context.tr('disease_match_score', {
                'value': topCandidate.matchScore,
              })}. '
            '${context.tr(topCandidate.reasonKey)}. '
            '${context.tr('disease_inspect_next')}: '
            '${context.tr(topCandidate.inspectionKey)}. ';
    final text = '$candidateText${context.tr(screening.riskKey)}. '
        '${context.tr(screening.explanationKey)}. '
        '${context.tr(screening.actionKey)}. '
        '${context.tr('disease_not_confirmed_short')}';
    final spoken = await scope.voice.speak(
      text: text,
      languageCode: scope.settings.value.languageCode,
    );
    if (!spoken && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('voice_unavailable'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final biotic = AppScope.of(context).sensors.source ==
                SensorDataSource.esp32 &&
            AppScope.of(context).sensors.connectionStatus ==
                SensorConnectionStatus.ready &&
            AppScope.of(context)
                    .sensors
                    .edgeIntelligence
                    ?.bioticStress
                    .suspected ==
                true
        ? AppScope.of(context).sensors.edgeIntelligence!.bioticStress
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('leaf_screening_title'))),
      body: PageFrame(
        children: [
          PhytoPageIntro(
            eyebrow: FarmerLanguage.isTamil(context)
                ? 'கேமரா சோதனை'
                : 'CAMERA CHECK',
            title: context.tr('leaf_screening_hero'),
            body: context.tr('leaf_screening_hero_body'),
            icon: Icons.document_scanner_outlined,
          ),
          const SizedBox(height: 20),
          _ScreeningProgress(
            activeStep: !cropConfirmed
                ? 0
                : imageBytes == null
                    ? 1
                    : result == null
                        ? 2
                        : 3,
          ),
          const SizedBox(height: 14),
          _CropConfirmationCard(
            selectedCrop: selectedCrop ?? CropCatalog.supported.first.name,
            confirmed: cropConfirmed,
            onCropChanged: (crop) {
              setState(() {
                selectedCrop = crop;
                cropConfirmed = false;
                imageBytes = null;
                result = null;
                assessment = null;
                errorKey = null;
                symptomAnswers = const DiseaseSymptomAnswers();
              });
            },
            onConfirmed: (confirmed) {
              setState(() {
                cropConfirmed = confirmed;
                if (!confirmed) {
                  result = null;
                  assessment = null;
                }
              });
            },
          ),
          const SizedBox(height: 14),
          _EvidenceSeparationCard(
            crop: context.tr(CropCatalog.profileFor(
              selectedCrop ?? CropCatalog.supported.first.name,
            ).localizationKey),
            sensorPrompt: widget.sensorPrompt,
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cameraButton = FilledButton.icon(
                    onPressed: analyzing || !cropConfirmed
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(context.tr('take_leaf_photo')),
                  );
                  final galleryButton = OutlinedButton.icon(
                    onPressed: analyzing || !cropConfirmed
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(context.tr('choose_leaf_photo')),
                  );
                  if (constraints.maxWidth < 430) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: cameraButton,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: galleryButton,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cameraButton),
                      const SizedBox(width: 10),
                      Expanded(child: galleryButton),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (imageBytes == null)
            const _PhotoGuide()
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.78),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(42),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (analyzing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 15),
                    Expanded(child: Text(context.tr('analyzing_leaf'))),
                  ],
                ),
              ),
            ),
          if (errorKey != null)
            Card(
              color: phytoTerracotta.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: phytoTerracotta),
                    const SizedBox(width: 10),
                    Expanded(child: Text(context.tr(errorKey!))),
                  ],
                ),
              ),
            ),
          if (result != null)
            _ScreeningResultCard(
              result: result!,
              onSpeak: _speakResult,
            ),
          if (result != null && _isTomato) ...[
            const SizedBox(height: 14),
            _TomatoSymptomCard(
              answers: symptomAnswers,
              onChanged: (answers) {
                setState(() {
                  symptomAnswers = answers;
                  assessment = null;
                });
              },
              onSubmit: _completeSymptomScreening,
            ),
          ],
          if (result != null && _isHibiscus) ...[
            const SizedBox(height: 14),
            _HibiscusSymptomCard(
              answers: symptomAnswers,
              onChanged: (answers) {
                setState(() {
                  symptomAnswers = answers;
                  assessment = null;
                });
              },
              onSubmit: _completeSymptomScreening,
            ),
          ],
          if (assessment != null) ...[
            const SizedBox(height: 14),
            _DiseaseAssessmentCard(assessment: assessment!),
            if (widget.sensorPrompt && biotic != null) ...[
              const SizedBox(height: 14),
              _BioticCameraOutcomeCard(
                info: biotic,
                assessment: assessment!,
              ),
            ],
          ],
          const SizedBox(height: 14),
          Card(
            color: phytoAmber.withValues(alpha: 0.07),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined, color: phytoAmber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(context.tr('leaf_safety_note'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BioticCameraOutcomeCard extends StatelessWidget {
  final BioticStressInfo info;
  final DiseaseAssessment assessment;

  const _BioticCameraOutcomeCard({
    required this.info,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    final top = assessment.candidates.isEmpty ? null : assessment.candidates.first;
    final noClearResult = assessment.isInconclusive ||
        top == null ||
        top.nameKey == 'disease_no_clear_match';
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer.withValues(alpha: 0.38),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FarmerLanguage.label(context, 'camera_sensor_combined'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              noClearResult
                  ? FarmerLanguage.label(context, 'camera_no_clear_title')
                  : '${FarmerLanguage.label(context, 'camera_possible_match')}: ${context.tr(top.nameKey)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 7),
            Text(
              noClearResult
                  ? FarmerLanguage.label(context, 'camera_no_clear_body')
                  : FarmerLanguage.label(context, 'camera_combined_body'),
            ),
            if (info.confidence != null) ...[
              const SizedBox(height: 7),
              Text(
                '${FarmerLanguage.label(context, 'biotic_confidence')}: ${info.confidence!.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (!noClearResult) ...[
              const SizedBox(height: 7),
              Text(
                FarmerLanguage.label(
                  context,
                  'camera_confirm_before_treatment',
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              FarmerLanguage.label(context, 'camera_result_separation'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              FarmerLanguage.label(context, 'biotic_safety_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreeningProgress extends StatelessWidget {
  final int activeStep;

  const _ScreeningProgress({required this.activeStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('screening_step_crop', Icons.grass_rounded),
      ('screening_step_photo', Icons.camera_alt_outlined),
      ('screening_step_evidence', Icons.hub_outlined),
      ('screening_step_result', Icons.fact_check_outlined),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: index <= activeStep
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        foregroundColor: index <= activeStep
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        child: Icon(steps[index].$2, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr(steps[index].$1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: constraints.maxWidth < 430 ? 8 : 24,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: index < activeStep
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TomatoSymptomCard extends StatelessWidget {
  final DiseaseSymptomAnswers answers;
  final ValueChanged<DiseaseSymptomAnswers> onChanged;
  final VoidCallback onSubmit;

  const _TomatoSymptomCard({
    required this.answers,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      context.tr('tomato_symptoms_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(context.tr('tomato_symptoms_body')),
              const SizedBox(height: 14),
              _ObservationField(
                questionKey: 'tomato_question_rings',
                value: answers.concentricRings,
                onChanged: (value) => onChanged(
                  answers.copyWith(concentricRings: value),
                ),
              ),
              _ObservationField(
                questionKey: 'tomato_question_water_soaked',
                value: answers.waterSoakedLesions,
                onChanged: (value) => onChanged(
                  answers.copyWith(waterSoakedLesions: value),
                ),
              ),
              _ObservationField(
                questionKey: 'tomato_question_yellow_halos',
                value: answers.yellowHalos,
                onChanged: (value) => onChanged(
                  answers.copyWith(yellowHalos: value),
                ),
              ),
              _ObservationField(
                questionKey: 'tomato_question_leaf_curl',
                value: answers.leafCurling,
                onChanged: (value) => onChanged(
                  answers.copyWith(leafCurling: value),
                ),
              ),
              _ObservationField(
                questionKey: 'tomato_question_whiteflies',
                value: answers.whitefliesPresent,
                onChanged: (value) => onChanged(
                  answers.copyWith(whitefliesPresent: value),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: answers.isComplete ? onSubmit : null,
                  icon: const Icon(Icons.manage_search_rounded),
                  label: Text(context.tr('rank_potential_issues')),
                ),
              ),
            ],
          ),
        ),
      );
}

class _HibiscusSymptomCard extends StatelessWidget {
  final DiseaseSymptomAnswers answers;
  final ValueChanged<DiseaseSymptomAnswers> onChanged;
  final VoidCallback onSubmit;

  const _HibiscusSymptomCard({
    required this.answers,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      context.tr('hibiscus_symptoms_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(context.tr('hibiscus_symptoms_body')),
              const SizedBox(height: 14),
              _ObservationField(
                questionKey: 'hibiscus_question_whiteflies',
                value: answers.whitefliesPresent,
                onChanged: (value) => onChanged(
                  answers.copyWith(whitefliesPresent: value),
                ),
              ),
              _ObservationField(
                questionKey: 'hibiscus_question_mealybugs',
                value: answers.mealybugsPresent,
                onChanged: (value) => onChanged(
                  answers.copyWith(mealybugsPresent: value),
                ),
              ),
              _ObservationField(
                questionKey: 'hibiscus_question_aphids',
                value: answers.aphidsPresent,
                onChanged: (value) => onChanged(
                  answers.copyWith(aphidsPresent: value),
                ),
              ),
              _ObservationField(
                questionKey: 'hibiscus_question_spots',
                value: answers.visibleSpotting,
                onChanged: (value) => onChanged(
                  answers.copyWith(visibleSpotting: value),
                ),
              ),
              _ObservationField(
                questionKey: 'hibiscus_question_damage',
                value: answers.surfaceDamage,
                onChanged: (value) => onChanged(
                  answers.copyWith(surfaceDamage: value),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      answers.isHibiscusComplete ? onSubmit : null,
                  icon: const Icon(Icons.manage_search_rounded),
                  label: Text(context.tr('rank_potential_issues')),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ObservationField extends StatelessWidget {
  final String questionKey;
  final FieldObservation? value;
  final ValueChanged<FieldObservation> onChanged;

  const _ObservationField({
    required this.questionKey,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<FieldObservation>(
          key: ValueKey('$questionKey:${value?.name}'),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr(questionKey)),
          items: FieldObservation.values
              .map(
                (choice) => DropdownMenuItem(
                  value: choice,
                  child: Text(context.tr('observation_${choice.name}')),
                ),
              )
              .toList(growable: false),
          onChanged: (choice) {
            if (choice != null) onChanged(choice);
          },
        ),
      );
}

class _CropConfirmationCard extends StatelessWidget {
  final String selectedCrop;
  final bool confirmed;
  final ValueChanged<String> onCropChanged;
  final ValueChanged<bool> onConfirmed;

  const _CropConfirmationCard({
    required this.selectedCrop,
    required this.confirmed,
    required this.onCropChanged,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      context.tr('confirm_crop_title'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(context.tr('confirm_crop_body')),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey(selectedCrop),
                initialValue: selectedCrop,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('select_crop'),
                  prefixIcon: const Icon(Icons.grass_rounded),
                ),
                items: CropCatalog.supported
                    .map(
                      (crop) => DropdownMenuItem(
                        value: crop.name,
                        child: Text(context.tr(crop.localizationKey)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) onCropChanged(value);
                },
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) => onConfirmed(value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(context.tr('confirm_crop_checkbox')),
                subtitle: Text(context.tr('crop_not_auto_detected')),
              ),
            ],
          ),
        ),
      );
}

class _EvidenceSeparationCard extends StatelessWidget {
  final String crop;
  final bool sensorPrompt;

  const _EvidenceSeparationCard({
    required this.crop,
    required this.sensorPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: sensorPrompt ? phytoAmber.withValues(alpha: 0.07) : null,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sensorPrompt
                      ? Icons.notification_important_outlined
                      : Icons.visibility_outlined,
                  color: sensorPrompt ? phytoAmber : phytoGreen,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    FarmerLanguage.label(context, 'evidence_separation_title'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              sensorPrompt
                  ? FarmerLanguage.label(context, 'sensor_inspection_prompt')
                  : FarmerLanguage.label(context, 'camera_visual_only'),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FarmerLanguage.label(context, 'visual_evidence'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(FarmerLanguage.label(context, 'visual_evidence_body')),
                  const SizedBox(height: 10),
                  Text(
                    FarmerLanguage.label(context, 'sensor_evidence'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(FarmerLanguage.label(context, 'sensor_evidence_body')),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Chip(
              avatar: const Icon(Icons.grass_outlined, size: 17),
              label: Text('${context.tr('crop')}: $crop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGuide extends StatelessWidget {
  const _PhotoGuide();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('photo_guide_title'),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              for (final key in [
                'photo_guide_light',
                'photo_guide_single_leaf',
                'photo_guide_focus',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: phytoLeaf, size: 19),
                      const SizedBox(width: 9),
                      Expanded(child: Text(context.tr(key))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}

class _ScreeningResultCard extends StatelessWidget {
  final LeafScreeningResult result;
  final VoidCallback onSpeak;

  const _ScreeningResultCard({required this.result, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final caution = result.riskKey != 'leaf_result_low_risk';
    final accent = caution ? phytoAmber : phytoLeaf;
    return Card(
      color: accent.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(caution ? Icons.search_rounded : Icons.eco_rounded,
                    color: accent),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    context.tr(result.riskKey),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(context.tr('confidence', {'value': result.confidence})),
              ],
            ),
            const SizedBox(height: 10),
            Text(context.tr(result.explanationKey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EvidenceChip(
                  label: context.tr('leaf_green_area'),
                  value: result.greenPercent,
                ),
                _EvidenceChip(
                  label: context.tr('leaf_yellow_area'),
                  value: result.yellowPercent,
                ),
                _EvidenceChip(
                  label: context.tr('leaf_brown_area'),
                  value: result.brownPercent,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              '${context.tr('recommended_action')}: ${context.tr(result.actionKey)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_outlined),
              label: Text(context.tr('listen_guidance')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiseaseAssessmentCard extends StatelessWidget {
  final DiseaseAssessment assessment;

  const _DiseaseAssessmentCard({required this.assessment});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: phytoGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child:
                        const Icon(Icons.biotech_outlined, color: phytoGreen),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('disease_potential_matches'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          context.tr('disease_crop_context', {
                            'crop': context.tr(
                              CropCatalog.profileFor(assessment.crop)
                                  .localizationKey,
                            ),
                          }),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(context.tr('disease_ranking_explanation')),
              if (assessment.isInconclusive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: phytoAmber.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.help_outline_rounded, color: phytoAmber),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('disease_inconclusive_title'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(context.tr('disease_inconclusive_body')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              for (var index = 0;
                  index < assessment.candidates.length;
                  index++) ...[
                _DiseaseCandidateTile(
                  candidate: assessment.candidates[index],
                  rank: index + 1,
                ),
                if (index != assessment.candidates.length - 1)
                  const Divider(height: 25),
              ],
              const SizedBox(height: 16),
              Text(
                context.tr('disease_evidence_used'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assessment.evidenceKeys
                    .map(
                      (key) => Chip(
                        avatar: const Icon(Icons.fact_check_outlined, size: 17),
                        label: Text(context.tr(key)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: phytoAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: phytoAmber.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: phytoAmber, size: 20),
                    const SizedBox(width: 9),
                    Expanded(child: Text(context.tr('disease_not_confirmed'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _DiseaseCandidateTile extends StatelessWidget {
  final DiseaseCandidate candidate;
  final int rank;

  const _DiseaseCandidateTile({
    required this.candidate,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? phytoGreen.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(candidate.nameKey),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(context.tr(candidate.categoryKey)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: candidate.matchScore / 100,
                    minHeight: 8,
                    backgroundColor: phytoGreen.withValues(alpha: 0.1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('disease_match_score', {
                  'value': candidate.matchScore,
                }),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(context.tr(candidate.reasonKey)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.search_rounded, color: phytoGreen, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('disease_inspect_next')}: '
                  '${context.tr(candidate.inspectionKey)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      );
}

class _EvidenceChip extends StatelessWidget {
  final String label;
  final double value;

  const _EvidenceChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Chip(
        label: Text('$label ${value.toStringAsFixed(1)}%'),
      );
}
