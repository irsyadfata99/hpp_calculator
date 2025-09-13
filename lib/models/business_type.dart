// File: lib/models/business_type.dart - Business Type Models

import '../utils/constants.dart';

enum BusinessTypeEnum {
  fnb,
  konveksi,
  atk,
  service,
  retail,
  manufacturing,
  custom
}

class BusinessType {
  final BusinessTypeEnum type;
  final String name;
  final String description;
  final String icon;
  final List<String> commonIngredients;
  final List<String> preferredUnits;
  final String primaryUnit;
  final BusinessCharacteristics characteristics;

  BusinessType({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.commonIngredients,
    required this.preferredUnits,
    required this.primaryUnit,
    required this.characteristics,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'name': name,
      'description': description,
      'icon': icon,
      'commonIngredients': commonIngredients,
      'preferredUnits': preferredUnits,
      'primaryUnit': primaryUnit,
      'characteristics': characteristics.toMap(),
    };
  }

  factory BusinessType.fromMap(Map<String, dynamic> map) {
    return BusinessType(
      type: BusinessTypeEnum.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => BusinessTypeEnum.custom,
      ),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      commonIngredients: List<String>.from(map['commonIngredients'] ?? []),
      preferredUnits: List<String>.from(map['preferredUnits'] ?? []),
      primaryUnit: map['primaryUnit'] ?? AppConstants.defaultUnit,
      characteristics:
          BusinessCharacteristics.fromMap(map['characteristics'] ?? {}),
    );
  }
}

class BusinessCharacteristics {
  final double typicalMargin;
  final List<String> commonFixedCosts;
  final Map<String, double> efficiencyBenchmarks;
  final List<String> seasonalFactors;
  final ProductionPatterns productionPattern;

  BusinessCharacteristics({
    required this.typicalMargin,
    required this.commonFixedCosts,
    required this.efficiencyBenchmarks,
    required this.seasonalFactors,
    required this.productionPattern,
  });

  Map<String, dynamic> toMap() {
    return {
      'typicalMargin': typicalMargin,
      'commonFixedCosts': commonFixedCosts,
      'efficiencyBenchmarks': efficiencyBenchmarks,
      'seasonalFactors': seasonalFactors,
      'productionPattern': productionPattern.toMap(),
    };
  }

  factory BusinessCharacteristics.fromMap(Map<String, dynamic> map) {
    return BusinessCharacteristics(
      typicalMargin:
          map['typicalMargin']?.toDouble() ?? AppConstants.defaultMargin,
      commonFixedCosts: List<String>.from(map['commonFixedCosts'] ?? []),
      efficiencyBenchmarks:
          Map<String, double>.from(map['efficiencyBenchmarks'] ?? {}),
      seasonalFactors: List<String>.from(map['seasonalFactors'] ?? []),
      productionPattern:
          ProductionPatterns.fromMap(map['productionPattern'] ?? {}),
    );
  }
}

class ProductionPatterns {
  final String pattern; // 'daily', 'batch', 'continuous', 'seasonal'
  final Map<String, int> workingDays;
  final double averageProductionPerDay;
  final List<String> peakSeasons;

  ProductionPatterns({
    required this.pattern,
    required this.workingDays,
    required this.averageProductionPerDay,
    required this.peakSeasons,
  });

  Map<String, dynamic> toMap() {
    return {
      'pattern': pattern,
      'workingDays': workingDays,
      'averageProductionPerDay': averageProductionPerDay,
      'peakSeasons': peakSeasons,
    };
  }

  factory ProductionPatterns.fromMap(Map<String, dynamic> map) {
    return ProductionPatterns(
      pattern: map['pattern'] ?? 'daily',
      workingDays: Map<String, int>.from(
          map['workingDays'] ?? {'monday': 1, 'sunday': 0}),
      averageProductionPerDay:
          map['averageProductionPerDay']?.toDouble() ?? 1.0,
      peakSeasons: List<String>.from(map['peakSeasons'] ?? []),
    );
  }
}
