import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import 'home_screen.dart';

class ReportScreen extends StatefulWidget {
  final AnalysisResult result;

  const ReportScreen({super.key, required this.result});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _showAllSafe = false;

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return AppColors.safe;
      case RiskLevel.moderate:
        return AppColors.moderate;
      case RiskLevel.highRisk:
        return AppColors.highRisk;
      case RiskLevel.cancerLinked:
        return AppColors.cancerLinked;
      case RiskLevel.unknown:
        return AppColors.unknown;
    }
  }

  Color _riskBgColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return AppColors.safeBg;
      case RiskLevel.moderate:
        return AppColors.moderateBg;
      case RiskLevel.highRisk:
        return AppColors.highRiskBg;
      case RiskLevel.cancerLinked:
        return AppColors.cancerLinkedBg;
      case RiskLevel.unknown:
        return AppColors.unknownBg;
    }
  }

  IconData _riskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Icons.check_circle_rounded;
      case RiskLevel.moderate:
        return Icons.warning_amber_rounded;
      case RiskLevel.highRisk:
        return Icons.dangerous_rounded;
      case RiskLevel.cancerLinked:
        return Icons.cancel_rounded;
      case RiskLevel.unknown:
        return Icons.help_outline_rounded;
    }
  }

  void _shareReport() {
    final r = widget.result;
    var text = 'Uncle John Ingredient Report\n';
    text += '============================\n\n';
    text += 'Found ${r.totalCount} ingredients.\n';
    text += '${r.summaryMessage}\n\n';

    for (final ing in r.sortedIngredients) {
      text += '${ing.riskLabel}: ${ing.displayName}\n';
      if (ing.riskLevel != RiskLevel.safe &&
          ing.riskLevel != RiskLevel.unknown) {
        text += '  ${ing.explanation}\n';
        if (ing.isBannedAnywhere) {
          text += '  Banned in: ${ing.regionalStatus.entries.where((e) => e.value == "banned").map((e) => e.key).join(", ")}\n';
        }
      }
    }

    text += '\nScanned with Uncle John app';
    text += '\nBecause Uncle John cares about what you eat.';

    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final sorted = result.sortedIngredients;

    final concerning = sorted
        .where((i) =>
            i.riskLevel != RiskLevel.safe &&
            i.riskLevel != RiskLevel.unknown)
        .toList();
    final safe =
        sorted.where((i) => i.riskLevel == RiskLevel.safe).toList();
    final unknown =
        sorted.where((i) => i.riskLevel == RiskLevel.unknown).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkBg, AppColors.darkSurface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) => false,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Uncle John',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 28),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Text(
                        'ANALYSIS COMPLETE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 8),

                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            height: 1.3,
                          ),
                          children: [
                            const TextSpan(text: 'Uncle John\n'),
                            TextSpan(
                              text: 'found ${result.totalCount} ',
                              style: TextStyle(
                                  color: AppColors.primaryOrange),
                            ),
                            const TextSpan(text: 'ingredients.'),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      _buildSummaryCard(result),

                      if (result.concernCount > 0) ...[
                        const SizedBox(height: 12),
                        _buildQuickStats(result),
                      ],

                      const SizedBox(height: 24),

                      if (concerning.isNotEmpty || unknown.isNotEmpty) ...[
                        Text(
                          'DETAILED BREAKDOWN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      ...concerning.asMap().entries.map((entry) {
                        return _buildIngredientCard(entry.value)
                            .animate()
                            .fadeIn(
                                duration: 400.ms,
                                delay: (300 + entry.key * 100).ms)
                            .slideX(begin: 0.05, end: 0);
                      }),

                      ...unknown.asMap().entries.map((entry) {
                        return _buildIngredientCard(entry.value)
                            .animate()
                            .fadeIn(
                                duration: 400.ms,
                                delay: (300 +
                                        (concerning.length + entry.key) *
                                            100)
                                    .ms);
                      }),

                      if (concerning.isNotEmpty)
                        _buildEncouragementCard(),

                      if (safe.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._buildSafeSection(safe),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HomeScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Scan Another'),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _shareReport,
                          icon: Icon(
                            Icons.share_rounded,
                            color: AppColors.primaryOrange,
                          ),
                          label: const Text('Share Report'),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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

  Widget _buildQuickStats(AnalysisResult result) {
    return Row(
      children: [
        if (result.cancerLinkedCount > 0)
          _buildStatChip('${result.cancerLinkedCount} Avoid',
              AppColors.cancerLinked, AppColors.cancerLinkedBg),
        if (result.cancerLinkedCount > 0) const SizedBox(width: 8),
        if (result.highRiskCount > 0)
          _buildStatChip('${result.highRiskCount} High Risk',
              AppColors.highRisk, AppColors.highRiskBg),
        if (result.highRiskCount > 0) const SizedBox(width: 8),
        if (result.moderateCount > 0)
          _buildStatChip('${result.moderateCount} Limit',
              AppColors.moderate, AppColors.moderateBg),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }

  Widget _buildStatChip(String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AnalysisResult result) {
    final hasConcerns = result.concernCount > 0;
    final hasCancer = result.cancerLinkedCount > 0;
    final bgColor = hasCancer
        ? AppColors.cancerLinkedBg.withValues(alpha: 0.15)
        : hasConcerns
            ? AppColors.highRiskBg.withValues(alpha: 0.15)
            : AppColors.safeBg.withValues(alpha: 0.15);
    final iconColor = hasCancer
        ? AppColors.cancerLinked
        : hasConcerns
            ? AppColors.highRisk
            : AppColors.safe;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            hasConcerns
                ? Icons.notifications_active_rounded
                : Icons.check_circle_rounded,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.summaryMessage,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.summarySubtext,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  Widget _buildIngredientCard(IngredientInfo ingredient) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _riskIcon(ingredient.riskLevel),
            color: _riskColor(ingredient.riskLevel),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _riskBgColor(ingredient.riskLevel),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ingredient.riskLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _riskColor(ingredient.riskLevel),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (ingredient.riskLevel != RiskLevel.safe) ...[
                  const SizedBox(height: 8),
                  Text(
                    ingredient.explanation,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
                if (ingredient.isBannedAnywhere) ...[
                  const SizedBox(height: 8),
                  _buildBannedTag(ingredient),
                ],
                if (ingredient.riskLevel != RiskLevel.safe &&
                    ingredient.riskLevel != RiskLevel.unknown &&
                    ingredient.sourceAttribution.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Source: ${ingredient.sourceAttribution}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannedTag(IngredientInfo ingredient) {
    final bannedIn = ingredient.regionalStatus.entries
        .where((e) => e.value == 'banned')
        .map((e) => e.key)
        .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cancerLinked.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.cancerLinked.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 14,
            color: AppColors.cancerLinked,
          ),
          const SizedBox(width: 4),
          Text(
            'Banned in $bannedIn',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.cancerLinked,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragementCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"Listen to your gut, literally! A few swaps today can make a world of difference for your energy tomorrow. You\'re doing great."',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
  }

  List<Widget> _buildSafeSection(List<IngredientInfo> safe) {
    final visible = _showAllSafe ? safe : safe.take(2).toList();
    final remaining = safe.length - 2;

    return [
      ...visible.map((ingredient) =>
          _buildIngredientCard(ingredient)),
      if (!_showAllSafe && remaining > 0)
        GestureDetector(
          onTap: () => setState(() => _showAllSafe = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'See $remaining more safe ingredients',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
    ];
  }
}