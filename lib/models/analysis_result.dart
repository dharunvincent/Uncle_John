enum RiskLevel {
  safe,
  moderate,
  highRisk,
  cancerLinked,
  unknown,
}

class IngredientInfo {
  final String id;
  final String name;
  final String displayName;
  final List<String> aliases;
  final String category;
  final RiskLevel riskLevel;
  final String explanation;
  final Map<String, String> regionalStatus;
  final List<String> sources;
  final String notes;

  IngredientInfo({
    required this.id,
    required this.name,
    required this.displayName,
    required this.aliases,
    required this.category,
    required this.riskLevel,
    required this.explanation,
    required this.regionalStatus,
    required this.sources,
    required this.notes,
  });

  factory IngredientInfo.fromJson(Map<String, dynamic> json) {
    return IngredientInfo(
      id: json['id'] as String? ?? '',
      name: (json['name'] as String).toLowerCase(),
      displayName: json['display_name'] as String,
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((a) => (a as String).toLowerCase())
              .toList() ??
          [],
      category: json['category'] as String? ?? '',
      riskLevel: _parseRiskLevel(json['risk_level'] as String),
      explanation: json['explanation'] as String,
      regionalStatus: (json['regional_status'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      sources: (json['sources'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
    );
  }

  factory IngredientInfo.unknown(String name) {
    return IngredientInfo(
      id: '',
      name: name.toLowerCase(),
      displayName: _capitalizeWords(name),
      aliases: [],
      category: '',
      riskLevel: RiskLevel.unknown,
      explanation:
          'Uncle John doesn\'t have info on this one yet.',
      regionalStatus: {},
      sources: [],
      notes: '',
    );
  }

  static RiskLevel _parseRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'safe':
        return RiskLevel.safe;
      case 'moderate':
        return RiskLevel.moderate;
      case 'high_risk':
        return RiskLevel.highRisk;
      case 'cancer_linked':
        return RiskLevel.cancerLinked;
      default:
        return RiskLevel.unknown;
    }
  }

  static String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.safe:
        return 'SAFE';
      case RiskLevel.moderate:
        return 'LIMIT USE';
      case RiskLevel.highRisk:
        return 'HIGH RISK';
      case RiskLevel.cancerLinked:
        return 'AVOID';
      case RiskLevel.unknown:
        return 'UNKNOWN';
    }
  }

  String get regionalSummary {
    if (regionalStatus.isEmpty) return '';
    final parts = <String>[];
    regionalStatus.forEach((region, status) {
      final label = status.replaceAll('_', ' ');
      parts.add('$region: $label');
    });
    return parts.join(' · ');
  }

  bool get isBannedAnywhere =>
      regionalStatus.values.any((s) => s == 'banned');

  String get sourceAttribution {
    if (sources.isEmpty) return '';
    return sources.join(', ');
  }
}

class AnalysisResult {
  final List<IngredientInfo> ingredients;
  final String rawText;

  AnalysisResult({
    required this.ingredients,
    required this.rawText,
  });

  int get totalCount => ingredients.length;

  int get safeCount =>
      ingredients.where((i) => i.riskLevel == RiskLevel.safe).length;

  int get concernCount => ingredients
      .where((i) =>
          i.riskLevel == RiskLevel.moderate ||
          i.riskLevel == RiskLevel.highRisk ||
          i.riskLevel == RiskLevel.cancerLinked)
      .length;

  int get unknownCount =>
      ingredients.where((i) => i.riskLevel == RiskLevel.unknown).length;

  int get cancerLinkedCount =>
      ingredients.where((i) => i.riskLevel == RiskLevel.cancerLinked).length;

  int get highRiskCount =>
      ingredients.where((i) => i.riskLevel == RiskLevel.highRisk).length;

  int get moderateCount =>
      ingredients.where((i) => i.riskLevel == RiskLevel.moderate).length;

  List<IngredientInfo> get sortedIngredients {
    final order = {
      RiskLevel.cancerLinked: 0,
      RiskLevel.highRisk: 1,
      RiskLevel.moderate: 2,
      RiskLevel.unknown: 3,
      RiskLevel.safe: 4,
    };
    return List.from(ingredients)
      ..sort((a, b) => order[a.riskLevel]!.compareTo(order[b.riskLevel]!));
  }

  String get summaryMessage {
    if (concernCount == 0 && unknownCount == 0) {
      return 'All clear! Uncle John didn\'t find anything concerning.';
    } else if (concernCount == 0 && unknownCount > 0) {
      return 'Looks mostly fine, but $unknownCount ingredient${unknownCount > 1 ? 's are' : ' is'} not in Uncle John\'s list yet.';
    } else if (cancerLinkedCount > 0) {
      return '$concernCount need${concernCount > 1 ? '' : 's'} your attention. $cancerLinkedCount linked to cancer.';
    } else {
      return '$concernCount need${concernCount > 1 ? '' : 's'} your attention.';
    }
  }

  String get summarySubtext {
    if (concernCount == 0) {
      return 'Enjoy your food!';
    } else if (cancerLinkedCount > 0) {
      return 'Uncle John strongly recommends checking the red flagged items below.';
    } else {
      return 'Some elements may not align with a healthy lifestyle choice.';
    }
  }
}