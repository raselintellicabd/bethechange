import 'package:flutter/material.dart';

/// Maps icon name strings from API JSON to Material icons.
IconData materialIconFromName(String name) {
  return switch (name) {
    'account_circle_outlined' => Icons.account_circle_outlined,
    'assignment_outlined' => Icons.assignment_outlined,
    'person_outline' => Icons.person_outline,
    'history' => Icons.history,
    'medical_services_outlined' => Icons.medical_services_outlined,
    'calendar_plus_outlined' => Icons.edit_calendar_outlined,
    'shopping_bag_outlined' => Icons.shopping_bag_outlined,
    'help_outline' => Icons.help_outline,
    'card_membership_outlined' => Icons.card_membership_outlined,
    'badge_outlined' => Icons.badge_outlined,
    'card_giftcard_outlined' => Icons.card_giftcard_outlined,
    'stars_outlined' => Icons.stars_outlined,
    'mail_outline' => Icons.mail_outline,
    _ => Icons.circle_outlined,
  };
}
