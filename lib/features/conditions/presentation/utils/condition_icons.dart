import 'package:flutter/material.dart';

IconData conditionIconFor(String conditionId) {
  return switch (conditionId) {
    'diabetes' => Icons.water_drop_outlined,
    'obesity' => Icons.monitor_weight_outlined,
    'heart-disease' => Icons.favorite_outline,
    'chronic-fatigue' => Icons.battery_alert_outlined,
    'chronic-pain' => Icons.healing_outlined,
    'hormone-imbalance' => Icons.science_outlined,
    'detoxification' => Icons.spa_outlined,
    'concussion' => Icons.psychology_outlined,
    _ => Icons.health_and_safety_outlined,
  };
}
