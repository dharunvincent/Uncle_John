import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/analysis_result.dart';

class IngredientAnalyzer {
  List<IngredientInfo> _database = [];
  bool _isLoaded = false;

  final Map<String, IngredientInfo> _exactMap = {};
  final Map<String, IngredientInfo> _aliasMap = {};

  Future<void> loadDatabase() async {
    if (_isLoaded) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/ingredients.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final List<dynamic> jsonList = jsonData['ingredients'];
      _database = jsonList
          .map((item) =>
              IngredientInfo.fromJson(item as Map<String, dynamic>))
          .toList();

      for (final entry in _database) {
        _exactMap[entry.name] = entry;
        for (final alias in entry.aliases) {
          _aliasMap[alias] = entry;
        }
      }

      _isLoaded = true;
    } catch (e) {
      _database = [];
      _isLoaded = true;
    }
  }

  List<String> _extractIngredients(String rawText) {
    var text = rawText.toLowerCase();

    final patterns = [
      RegExp(r'ingredients?\s*[:;]\s*', caseSensitive: false),
      RegExp(r'contains?\s*[:;]\s*', caseSensitive: false),
      RegExp(r'composition\s*[:;]\s*', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        text = text.substring(match.end);
        break;
      }
    }

    final stopPatterns = [
      RegExp(r'nutrition(al)?\s*(facts?|info|information)',
          caseSensitive: false),
      RegExp(r'manufactured\s+by', caseSensitive: false),
      RegExp(r'distributed\s+by', caseSensitive: false),
      RegExp(r'best\s+before', caseSensitive: false),
      RegExp(r'storage\s*(instructions?|conditions?)?:',
          caseSensitive: false),
      RegExp(r'allergen\s*(info|warning|advice)', caseSensitive: false),
      RegExp(r'may\s+contain', caseSensitive: false),
      RegExp(r'packed\s+by', caseSensitive: false),
      RegExp(r'net\s+wt', caseSensitive: false),
      RegExp(r'serving\s+size', caseSensitive: false),
    ];

    for (final pattern in stopPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        text = text.substring(0, match.start);
      }
    }

    var parts = text.split(RegExp(r'[,;\n]+'));

    List<String> ingredients = [];
    for (var part in parts) {
      var cleaned = part
          .replaceAll(RegExp(r'\([^)]*\)'), '')
          .replaceAll(RegExp(r'\[[^\]]*\]'), '')
          .replaceAll(RegExp(r'[%]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      cleaned = cleaned.replaceAll(RegExp(r'^\d+\.?\s*'), '');

      if (cleaned.length >= 2 && cleaned.length <= 80) {
        ingredients.add(cleaned);
      }
    }

    return ingredients;
  }

  IngredientInfo _lookupIngredient(String name) {
    final normalized = name.toLowerCase().trim();

    if (_exactMap.containsKey(normalized)) {
      return _exactMap[normalized]!;
    }

    if (_aliasMap.containsKey(normalized)) {
      final match = _aliasMap[normalized]!;
      return IngredientInfo(
        id: match.id,
        name: normalized,
        displayName: match.displayName,
        aliases: match.aliases,
        category: match.category,
        riskLevel: match.riskLevel,
        explanation: match.explanation,
        regionalStatus: match.regionalStatus,
        sources: match.sources,
        notes: match.notes,
      );
    }

    for (final entry in _database) {
      if (normalized.contains(entry.name) && entry.name.length >= 3) {
        return IngredientInfo(
          id: entry.id,
          name: normalized,
          displayName: entry.displayName,
          aliases: entry.aliases,
          category: entry.category,
          riskLevel: entry.riskLevel,
          explanation: entry.explanation,
          regionalStatus: entry.regionalStatus,
          sources: entry.sources,
          notes: entry.notes,
        );
      }

      for (final alias in entry.aliases) {
        if (alias.length >= 3 && normalized.contains(alias)) {
          return IngredientInfo(
            id: entry.id,
            name: normalized,
            displayName: entry.displayName,
            aliases: entry.aliases,
            category: entry.category,
            riskLevel: entry.riskLevel,
            explanation: entry.explanation,
            regionalStatus: entry.regionalStatus,
            sources: entry.sources,
            notes: entry.notes,
          );
        }
      }
    }

    for (final entry in _database) {
      if (entry.name.length >= 4 && entry.name.contains(normalized)) {
        return IngredientInfo(
          id: entry.id,
          name: normalized,
          displayName: entry.displayName,
          aliases: entry.aliases,
          category: entry.category,
          riskLevel: entry.riskLevel,
          explanation: entry.explanation,
          regionalStatus: entry.regionalStatus,
          sources: entry.sources,
          notes: entry.notes,
        );
      }
    }

    return IngredientInfo.unknown(name);
  }

  AnalysisResult analyze(String rawText) {
    final ingredientNames = _extractIngredients(rawText);

    final seen = <String>{};
    final unique = <String>[];
    for (final name in ingredientNames) {
      final key = name.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(name);
      }
    }

    final ingredients =
        unique.map((name) => _lookupIngredient(name)).toList();

    final seenIds = <String>{};
    final deduped = <IngredientInfo>[];
    for (final ing in ingredients) {
      final key = ing.id.isNotEmpty ? ing.id : ing.name;
      if (!seenIds.contains(key)) {
        seenIds.add(key);
        deduped.add(ing);
      }
    }

    return AnalysisResult(
      ingredients: deduped,
      rawText: rawText,
    );
  }
}