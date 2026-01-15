// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orchestrator_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrchestratorPlan _$OrchestratorPlanFromJson(Map<String, dynamic> json) =>
    _OrchestratorPlan(
      steps: (json['steps'] as List<dynamic>)
          .map((e) => OrchestratorStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      reasoning: json['reasoning'] as String,
    );

Map<String, dynamic> _$OrchestratorPlanToJson(_OrchestratorPlan instance) =>
    <String, dynamic>{'steps': instance.steps, 'reasoning': instance.reasoning};

_OrchestratorStep _$OrchestratorStepFromJson(Map<String, dynamic> json) =>
    _OrchestratorStep(
      toolId: json['toolId'] as String,
      input: json['input'] as Map<String, dynamic>,
      description: json['description'] as String,
    );

Map<String, dynamic> _$OrchestratorStepToJson(_OrchestratorStep instance) =>
    <String, dynamic>{
      'toolId': instance.toolId,
      'input': instance.input,
      'description': instance.description,
    };
