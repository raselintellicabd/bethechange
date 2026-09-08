import 'package:flutter/material.dart';

/// Maps icon name strings from API JSON to Material icons.
IconData materialIconFromName(String name) {
  return switch (name) {
    'account_circle_outlined' => Icons.account_circle_outlined,
    'medical_services_outlined' => Icons.medical_services_outlined,
    'shopping_bag_outlined' => Icons.shopping_bag_outlined,
    'help_outline' => Icons.help_outline,
    _ => Icons.circle_outlined,
  };
}
