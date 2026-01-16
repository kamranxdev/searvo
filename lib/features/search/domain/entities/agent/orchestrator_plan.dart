import 'package:freezed_annotation/freezed_annotation.dart';

part 'orchestrator_plan.freezed.dart';
part 'orchestrator_plan.g.dart';

@freezed
abstract class OrchestratorPlan with _$OrchestratorPlan {
  const factory OrchestratorPlan({
    required List<OrchestratorStep> steps,
    required String reasoning,
  }) = _OrchestratorPlan;

  factory OrchestratorPlan.fromJson(Map<String, dynamic> json) =>
      _$OrchestratorPlanFromJson(json);
}

@freezed
abstract class OrchestratorStep with _$OrchestratorStep {
  const factory OrchestratorStep({
    required String toolId,
    required Map<String, dynamic> input,
    required String description,
  }) = _OrchestratorStep;

  factory OrchestratorStep.fromJson(Map<String, dynamic> json) =>
      _$OrchestratorStepFromJson(json);
}
