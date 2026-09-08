import 'package:flutter/material.dart';

IconData serviceIconFor(String serviceId) {
  return switch (serviceId) {
    'fsm' => Icons.bolt_outlined,
    'infrared-sauna' => Icons.wb_sunny_outlined,
    'hbot' => Icons.air_outlined,
    'nutritional-iv' => Icons.water_drop_outlined,
    'liquivida-iv' => Icons.local_drink_outlined,
    'ozone' => Icons.blur_on_outlined,
    'reflexology' => Icons.accessibility_new_outlined,
    'ion-foot-detox' => Icons.spa_outlined,
    _ => Icons.medical_services_outlined,
  };
}
