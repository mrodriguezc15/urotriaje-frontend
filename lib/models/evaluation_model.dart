import 'package:flutter/material.dart';

class EvaluationResult {
  final String riskLevel;
  final String recommendation;
  final String date;
  final Color riskColor;

  EvaluationResult({
    required this.riskLevel,
    required this.recommendation,
    required this.date,
    required this.riskColor,
  });
}