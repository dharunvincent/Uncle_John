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
      RegExp(r'fssai\s*(lic(ense)?\.?\s*(no\.?|number)?)?\s*[:.]?',
          caseSensitive: false),
      RegExp(r'\bgstin\b', caseSensitive: false),
      RegExp(r'\btin\s*(no\.?|number)?\s*[:.]', caseSensitive: false),
      RegExp(r'\bbatch\s*(no\.?|number)?\s*[:.]', caseSensitive: false),
      RegExp(r'\bmrp\b', caseSensitive: false),
      RegExp(r'mfg\.?\s*(date|dt)?\s*[:.]?', caseSensitive: false),
      RegExp(r'manufacturing\s+date', caseSensitive: false),
      RegExp(r'(is|are)\s+(the\s+)?(registered\s+)?trade\s*mark',
          caseSensitive: false),
      RegExp(r'trade\s*mark\s+of', caseSensitive: false),
    ];

    for (final pattern in stopPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        text = text.substring(0, match.start);
      }
    }

    // OCR line-wraps are just physical formatting, not ingredient
    // boundaries, so flatten them to spaces before splitting on commas.
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    final rawParts = _splitTopLevel(text);

    List<String> ingredients = [];
    for (final part in rawParts) {
      ingredients.addAll(_flattenIngredientToken(part));
    }

    final cleaned = <String>[];
    for (var raw in ingredients) {
      var token = raw
          .replaceAll(RegExp(r'\[[^\]]*\]'), '')
          .replaceAll(RegExp(r'[%]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Don't strip a bare INS/E-number token (e.g. "330", "160c") as if it
      // were list numbering like "1. Sugar" -- it IS the ingredient.
      if (!_insNumberPattern.hasMatch(token)) {
        token = token.replaceAll(RegExp(r'^[\d.\*\-•]+\s*'), '');
        token = token.replaceAll(RegExp(r'[\*]+$'), '').trim();
      }

      if (token.length < 2 || token.length > 80) continue;
      if (_looksLikeJunkCode(token)) continue;

      cleaned.add(token);
    }

    return cleaned;
  }

  /// Splits [text] on commas/semicolons, but only outside of
  /// parentheses/brackets, so a parenthetical like "(Spices, Salt)" doesn't
  /// get torn apart by its own internal commas.
  static List<String> _splitTopLevel(String text) {
    final result = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '(' || ch == '[') {
        depth++;
      } else if (ch == ')' || ch == ']') {
        if (depth > 0) depth--;
      } else if (depth == 0 && (ch == ',' || ch == ';')) {
        result.add(text.substring(start, i));
        start = i + 1;
      }
    }
    result.add(text.substring(start));
    return result;
  }

  static final RegExp _insNumberPattern = RegExp(r'^\d{1,4}[a-z]?$');

  /// Recursively breaks down a single ingredient fragment that may contain a
  /// parenthetical, e.g.:
  ///  - "potato (83%)" -> ["potato"]                (percentage annotation dropped)
  ///  - "flavours (natural and nature identical...)" -> ["flavours"]  (descriptive annotation dropped)
  ///  - "acidity regulators (330, 296, 334)" -> ["330", "296", "334"] (functional class + INS numbers)
  ///  - "seasoning (spices, salt, maltodextrin)" -> ["seasoning", "spices", "salt", "maltodextrin"]
  static List<String> _flattenIngredientToken(String rawPart) {
    var part = rawPart.trim();
    part = part.replaceAll(RegExp(r'^[\d.\*\-•\s]+'), '').trim();
    if (part.isEmpty) return [];

    final openIdx = part.indexOf('(');
    if (openIdx == -1) {
      return [part];
    }

    var depth = 0;
    var closeIdx = -1;
    for (var i = openIdx; i < part.length; i++) {
      if (part[i] == '(') depth++;
      if (part[i] == ')') {
        depth--;
        if (depth == 0) {
          closeIdx = i;
          break;
        }
      }
    }

    final prefix = part.substring(0, openIdx).trim();

    if (closeIdx == -1) {
      return prefix.isNotEmpty ? [prefix] : [];
    }

    final inner = part.substring(openIdx + 1, closeIdx).trim();
    final suffix = part.substring(closeIdx + 1).trim();

    final results = <String>[];
    // The '%' must be present -- otherwise a bare INS number like "(319)"
    // would be mistaken for a percentage annotation and silently dropped.
    final isPercentage = RegExp(r'^\d+(\.\d+)?\s*%$').hasMatch(inner);

    if (inner.isEmpty || isPercentage) {
      if (prefix.isNotEmpty) results.add(prefix);
    } else {
      final subParts = _splitTopLevel(inner)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final allNumeric = subParts.isNotEmpty &&
          subParts.every((s) => _insNumberPattern.hasMatch(s));

      if (allNumeric) {
        results.addAll(subParts);
      } else if (subParts.length > 1) {
        if (prefix.isNotEmpty) results.add(prefix);
        for (final sub in subParts) {
          results.addAll(_flattenIngredientToken(sub));
        }
      } else {
        if (prefix.isNotEmpty) results.add(prefix);
      }
    }

    if (suffix.isNotEmpty) {
      results.addAll(_flattenIngredientToken(suffix));
    }

    return results;
  }

  /// Filters out back-label junk (GSTIN, FSSAI license numbers, batch codes,
  /// MRP amounts, dates) that is mostly digits, while still allowing short
  /// INS/E-number style tokens like "330" or "160c" through.
  static bool _looksLikeJunkCode(String token) {
    if (_insNumberPattern.hasMatch(token)) return false;
    final digitCount = token.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (token.length > 5 && digitCount / token.length >= 0.5) return true;
    return false;
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