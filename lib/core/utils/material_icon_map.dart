import 'package:flutter/material.dart';

/// Maps icon name strings from API JSON to Material icons.
IconData materialIconFromName(String name) {
  return switch (name) {
    'account_circle_outlined' => Icons.account_circle_outlined,
    'medical_services_outlined' => Icons.medical_services_outlined,
    'calendar_plus_outlined' => Icons.edit_calendar_outlined,
    'shopping_bag_outlined' => Icons.shopping_bag_outlined,
    'help_outline' => Icons.help_outline,
    'card_membership_outlined' => Icons.card_membership_outlined,
    'badge_outlined' => Icons.badge_outlined,
    'mail_outline' => Icons.mail_outline,
    _ => Icons.circle_outlined,
  };
}
