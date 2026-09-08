import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppHeroBanner extends StatelessWidget {
  const AppHeroBanner({
    super.key,
    required this.title,
    this.tag,
    this.height = 190,
    this.backgroundColor,
    this.child,
  });

  final String title;
  final String? tag;
  final double height;
  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFB7C4A3);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(bg, AppColors.forestDark, 0.05)!,
              Color.lerp(bg, AppColors.forestDark, 0.82)!,
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag!,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 10,
                            color: AppColors.forestDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

class SegmentControl extends StatelessWidget {
  const SegmentControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.sageLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.forest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontSize: labels.length > 2 ? 10 : 12,
                      color: i == selectedIndex
                          ? Colors.white
                          : AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final label in labels)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class HorizontalContentCard extends StatelessWidget {
  const HorizontalContentCard({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbColor,
    this.onTap,
    this.width = 128,
  });

  final String title;
  final String? subtitle;
  final Color? thumbColor;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 64,
                width: double.infinity,
                color: thumbColor ?? AppColors.sage,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(fontSize: 11),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 9.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListRowTile extends StatelessWidget {
  const ListRowTile({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbColor,
    this.onTap,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Color? thumbColor;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: thumbColor ?? AppColors.sage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 12.5),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          for (var i = 0; i < totalSteps; i++) ...[
            if (i > 0)
              const Expanded(
                child: SizedBox(
                  height: 2,
                  child: ColoredBox(color: AppColors.line),
                ),
              ),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= currentStep
                    ? AppColors.forest
                    : AppColors.sageLight,
              ),
              child: Text(
                '${i + 1}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: i <= currentStep ? Colors.white : AppColors.inkMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LockedContextChip extends StatelessWidget {
  const LockedContextChip({
    super.key,
    required this.label,
    this.icon = Icons.medical_services_outlined,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sageLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.forestDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientTile extends StatelessWidget {
  const PatientTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: AppColors.forest),
              ),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.labelLarge.copyWith(fontSize: 12)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

