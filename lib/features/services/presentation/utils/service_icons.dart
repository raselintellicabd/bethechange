import 'package:flutter/material.dart';

IconData serviceIconFor(String serviceId) {
  return switch (serviceId) {
    'frequency-specific-microcurrent' => Icons.bolt_outlined,
    'infrared-sauna-therapy' => Icons.wb_sunny_outlined,
    'hyperbaric-oxygen-therapy' => Icons.air_outlined,
    'iv-nutritional-infusions' => Icons.water_drop_outlined,
    'liquivida-iv-therapy' => Icons.local_drink_outlined,
    'ozone-therapy' => Icons.blur_on_outlined,
    'reflexology' => Icons.accessibility_new_outlined,
    'ion-foot-detox' => Icons.spa_outlined,
    _ => Icons.medical_services_outlined,
  };
}
