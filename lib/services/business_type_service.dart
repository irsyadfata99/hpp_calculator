// File: lib/services/business_type_service.dart - Business Type Service

class BusinessTypeService {
  static List<BusinessType> getAllBusinessTypes() {
    return [
      _getFnBBusinessType(),
      _getKonveksiBusinessType(),
      _getATKBusinessType(),
      _getServiceBusinessType(),
      _getRetailBusinessType(),
      _getManufacturingBusinessType(),
      _getCustomBusinessType(),
    ];
  }

  static BusinessType _getFnBBusinessType() {
    return BusinessType(
      type: BusinessTypeEnum.fnb,
      name: 'Food & Beverage',
      description: 'Restoran, Warung, Catering, Bakery',
      icon: '🍽️',
      commonIngredients: [
        'Beras',
        'Minyak Goreng',
        'Gula',
        'Garam',
        'Bawang Merah',
        'Bawang Putih',
        'Cabai',
        'Ayam',
        'Daging Sapi',
        'Ikan',
        'Telur',
        'Terigu',
        'Santan',
        'Kecap Manis',
        'Kecap Asin',
        'Saos Tomat',
        'Mentega',
        'Susu',
        'Sayur Mayur',
        'Bumbu Instant',
        'MSG',
        'Gula Pasir',
        'Tepung Terigu'
      ],
      preferredUnits: ['%', 'gram', 'ml', 'kg', 'liter', 'unit', 'sendok'],
      primaryUnit: '%',
      characteristics: BusinessCharacteristics(
        typicalMargin: 35.0,
        commonFixedCosts: [
          'Sewa Tempat',
          'Listrik & Air',
          'Gas',
          'Gaji Karyawan',
          'Perizinan',
          'Kebersihan',
          'Marketing',
          'Peralatan Dapur'
        ],
        efficiencyBenchmarks: {
          'food_cost_ratio': 30.0, // Max 30% dari harga jual
          'portion_per_staff': 100.0, // Min 100 porsi per staff per hari
          'waste_ratio': 5.0, // Max 5% waste
        },
        seasonalFactors: ['Ramadan', 'Lebaran', 'Tahun Baru', 'Musim Hujan'],
        productionPattern: ProductionPatterns(
          pattern: 'daily',
          workingDays: {
            'monday': 1,
            'tuesday': 1,
            'wednesday': 1,
            'thursday': 1,
            'friday': 1,
            'saturday': 1,
            'sunday': 1
          },
          averageProductionPerDay: 3.0, // 3x masak per hari
          peakSeasons: ['Ramadan', 'Weekend'],
        ),
      ),
    );
  }

  static BusinessType _getKonveksiBusinessType() {
    return BusinessType(
      type: BusinessTypeEnum.konveksi,
      name: 'Konveksi & Fashion',
      description: 'Garment, Tailor, Fashion, Bordir',
      icon: '👗',
      commonIngredients: [
        'Kain Katun',
        'Kain Polyester',
        'Benang',
        'Kancing',
        'Resleting',
        'Furing',
        'Elastis',
        'Pita',
        'Dakron',
        'Kain Denim',
        'Kain Sutra',
        'Thread',
        'Interfacing',
        'Bias Tape',
        'Velcro',
        'Karet',
        'Label'
      ],
      preferredUnits: ['meter', 'yard', 'unit', '%', 'roll', 'pak'],
      primaryUnit: 'meter',
      characteristics: BusinessCharacteristics(
        typicalMargin: 45.0,
        commonFixedCosts: [
          'Sewa Workshop',
          'Listrik',
          'Gaji Operator',
          'Maintenance Mesin',
          'Perizinan',
          'Packaging',
          'Marketing',
          'Peralatan Jahit'
        ],
        efficiencyBenchmarks: {
          'material_efficiency': 85.0, // Min 85% material usage
          'production_per_staff': 12.0, // Min 12 pieces per staff per day
          'defect_ratio': 3.0, // Max 3% defect
        },
        seasonalFactors: ['Back to School', 'Lebaran', 'Wedding Season'],
        productionPattern: ProductionPatterns(
          pattern: 'batch',
          workingDays: {
            'monday': 1,
            'tuesday': 1,
            'wednesday': 1,
            'thursday': 1,
            'friday': 1,
            'saturday': 1,
            'sunday': 0
          },
          averageProductionPerDay: 1.5, // 1-2 batch per hari
          peakSeasons: ['Lebaran', 'Back to School'],
        ),
      ),
    );
  }

  static BusinessType _getATKBusinessType() {
    return BusinessType(
      type: BusinessTypeEnum.atk,
      name: 'ATK & Stationery',
      description: 'Alat Tulis, Percetakan, Fotocopy',
      icon: '📝',
      commonIngredients: [
        'Kertas A4',
        'Kertas A3',
        'Tinta Printer',
        'Toner',
        'Pensil',
        'Pulpen',
        'Spidol',
        'Penggaris',
        'Penghapus',
        'Stapler',
        'Paper Clip',
        'Amplop',
        'Map',
        'Binder',
        'Laminating Film'
      ],
      preferredUnits: ['unit', 'lembar', 'pack', 'box', '%', 'rim'],
      primaryUnit: 'unit',
      characteristics: BusinessCharacteristics(
        typicalMargin: 25.0,
        commonFixedCosts: [
          'Sewa Toko',
          'Listrik',
          'Gaji Kasir',
          'Maintenance Printer',
          'Perizinan',
          'Packaging',
          'Inventory Cost',
          'Security'
        ],
        efficiencyBenchmarks: {
          'inventory_turnover': 6.0, // 6x per tahun
          'sales_per_sqm': 500000.0, // Min 500k per m2 per bulan
          'customer_per_day': 50.0, // Min 50 customer per hari
        },
        seasonalFactors: ['Back to School', 'New Year', 'Exam Season'],
        productionPattern: ProductionPatterns(
          pattern: 'continuous',
          workingDays: {
            'monday': 1,
            'tuesday': 1,
            'wednesday': 1,
            'thursday': 1,
            'friday': 1,
            'saturday': 1,
            'sunday': 0
          },
          averageProductionPerDay: 1.0,
          peakSeasons: ['Back to School', 'Exam Season'],
        ),
      ),
    );
  }

  static BusinessType _getServiceBusinessType() {
    return BusinessType(
      type: BusinessTypeEnum.service,
      name: 'Service & Repair',
      description: 'Bengkel, Service AC, Elektronik',
      icon: '🔧',
      commonIngredients: [
        'Oli Mesin',
        'Filter Udara',
        'Busi',
        'Ban',
        'Freon AC',
        'Kabel',
        'Solder',
        'Flux',
        'Spare Part',
        'Cleaning Fluid',
        'Grease',
        'Belt',
        'Bearing',
        'Gasket',
        'Tools'
      ],
      preferredUnits: ['%', 'unit', 'liter', 'ml', 'meter', 'pack'],
      primaryUnit: '%',
      characteristics: BusinessCharacteristics(
        typicalMargin: 60.0,
        commonFixedCosts: [
          'Sewa Workshop',
          'Listrik',
          'Gaji Teknisi',
          'Peralatan Service',
          'Perizinan',
          'Insurance',
          'Training',
          'Spare Part Stock'
        ],
        efficiencyBenchmarks: {
          'service_completion': 95.0, // Min 95% completion rate
          'customer_satisfaction': 90.0, // Min 90% satisfaction
          'technician_productivity': 8.0, // Min 8 jobs per technician per day
        },
        seasonalFactors: ['Pre-Holiday', 'Rainy Season', 'Summer'],
        productionPattern: ProductionPatterns(
          pattern: 'daily',
          workingDays: {
            'monday': 1,
            'tuesday': 1,
            'wednesday': 1,
            'thursday': 1,
            'friday': 1,
            'saturday': 1,
            'sunday': 0
          },
          averageProductionPerDay: 8.0, // 8 service per hari
          peakSeasons: ['Pre-Holiday', 'Summer'],
        ),
      ),
    );
  }

  static BusinessType _getRetailBusinessType() {
    return BusinessType(
      type: BusinessTypeEnum.retail,
      name: 'Retail & Trading',
      description: 'Toko, Minimarket, Grosir',
      icon: '🏪',
      commonIngredients: [
        'Produk A',
        'Produk B',
        'Produk C',
        'Packaging',
        'Shopping Bags',
        'Labels',
        'Price Tags',
        'Inventory Items'
      ],
      preferredUnits: ['unit', '%', 'pack', 'box', 'karton', 'lusin'],
      primaryUnit: 'unit',
      characteristics: BusinessCharacteristics(
        typicalMargin: 20.0,
        commonFixedCosts: [
          'Sewa Toko',
          'Listrik',
          'Gaji Kasir',
          'Security',
          'Perizinan',
          'POS System',
          'Inventory Management',
          'Marketing'
        ],
        efficiencyBenchmarks: {
          'inventory_turnover': 12.0, // 12x per tahun
          'sales_per_sqm': 1000000.0, // Min 1jt per m2 per bulan
          'gross_margin': 20.0, // Min 20% gross margin
        },
        seasonalFactors: ['Holiday Season', 'Back to School', 'Payday'],
        productionPattern: ProductionPatterns(
          pattern: 'continuous',
          workingDays: {
            'monday': 1,
            'tuesday': 1,
            'wednesday': 1,
            'thursday': 1,
            'friday': 1,
            'saturday': 1,
            'sunday': 1
          },
          averageProductionPerDay: 1.0,
          peakSeasons: ['Holiday Season', 'Payday'],
        ),
      ),
    );
  }

  static BusinessType _getManufacturingBusinessType() {
    return BusinessType(
      type: BusinessTypeEnum.manufacturing,
      name: 'Manufacturing',
      description: 'Pabrik, Produksi Massal, Assembly',
      icon: '🏭',
      commonIngredients: [
        'Raw Material A',
        'Raw Material B',
        'Chemical Components',
        'Metal Parts',
        'Plastic Components',
        'Packaging Material',
        'Quality Control Items',
        'Production Supplies'
      ],
      preferredUnits: ['kg', 'ton', 'liter', 'unit', '%', 'batch'],
      primaryUnit: 'kg',
      characteristics: BusinessCharacteristics(
        typicalMargin: 30.0,
        commonFixedCosts: [
          'Factory Rent',
          'Utilities',
          'Worker Salary',
          'Machine Maintenance',
          'Quality Control',
          'Safety Equipment',
          'Waste Management',
          'Compliance'
        ],
        efficiencyBenchmarks: {
          'production_efficiency': 90.0, // Min 90% machine efficiency
          'quality_rate': 98.0, // Min 98% quality rate
          'oee': 85.0, // Overall Equipment Effectiveness 85%
        },
        seasonalFactors: [
          'Raw Material Price',
          'Demand Cycle',
          'Maintenance Season'
        ],
        productionPattern: ProductionPatterns(
          pattern: 'continuous',
          workingDays: {
            'monday': 1,
            'tuesday': 1,
            'wednesday': 1,
            'thursday': 1,
            'friday': 1,
            'saturday': 1,
            'sunday': 0
          },
          averageProductionPerDay: 2.0, // 2 shift per hari
          peakSeasons: ['Q4 Demand', 'Export Season'],
        ),
      ),
    );
  }

  static BusinessType _getCustomBusinessType() {
    return BusinessType(
      type: BusinessTypeEnum.custom,
      name: 'Custom Business',
      description: 'Jenis Usaha Lainnya',
      icon: '⚙️',
      commonIngredients: [],
      preferredUnits: [
        AppConstants.defaultUsageUnit,
        AppConstants.defaultUnit,
        'pack',
        'kg'
      ],
      primaryUnit: AppConstants.defaultUsageUnit,
      characteristics: BusinessCharacteristics(
        typicalMargin: AppConstants.defaultMargin,
        commonFixedCosts: ['Sewa Tempat', 'Listrik', 'Gaji', 'Operasional'],
        efficiencyBenchmarks: {},
        seasonalFactors: [],
        productionPattern: ProductionPatterns(
          pattern: 'daily',
          workingDays: {
            'monday': 1,
            'tuesday': 1,
            'wednesday': 1,
            'thursday': 1,
            'friday': 1,
            'saturday': 1,
            'sunday': 0
          },
          averageProductionPerDay: 1.0,
          peakSeasons: [],
        ),
      ),
    );
  }

  static BusinessType getBusinessTypeByEnum(BusinessTypeEnum type) {
    return getAllBusinessTypes().firstWhere(
      (bt) => bt.type == type,
      orElse: () => _getCustomBusinessType(),
    );
  }

  static List<String> getSmartIngredientSuggestions({
    required BusinessTypeEnum businessType,
    required String query,
    int limit = 10,
  }) {
    final business = getBusinessTypeByEnum(businessType);

    if (query.isEmpty) {
      return business.commonIngredients.take(limit).toList();
    }

    // Filter berdasarkan query
    final filtered = business.commonIngredients
        .where((ingredient) =>
            ingredient.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return filtered.take(limit).toList();
  }

  static String getRecommendedUnit({
    required BusinessTypeEnum businessType,
    required String ingredientName,
  }) {
    final business = getBusinessTypeByEnum(businessType);
    final ingredient = ingredientName.toLowerCase();

    // Logika smart recommendation berdasarkan nama ingredient
    if (businessType == BusinessTypeEnum.fnb) {
      if (ingredient.contains('minyak') ||
          ingredient.contains('santan') ||
          ingredient.contains('susu') ||
          ingredient.contains('air')) {
        return 'ml';
      }
      if (ingredient.contains('gula') ||
          ingredient.contains('garam') ||
          ingredient.contains('tepung') ||
          ingredient.contains('beras')) {
        return '%';
      }
      if (ingredient.contains('telur') || ingredient.contains('bawang')) {
        return 'unit';
      }
    } else if (businessType == BusinessTypeEnum.konveksi) {
      if (ingredient.contains('kain') || ingredient.contains('benang')) {
        return 'meter';
      }
      if (ingredient.contains('kancing') || ingredient.contains('resleting')) {
        return 'unit';
      }
    }

    return business.primaryUnit;
  }

  static Map<String, dynamic> getBusinessAnalytics({
    required BusinessType businessType,
    required Map<String, double> currentMetrics,
  }) {
    final benchmarks = businessType.characteristics.efficiencyBenchmarks;
    Map<String, dynamic> analysis = {
      'businessType': businessType.name,
      'overallScore': 0.0,
      'metrics': <String, Map<String, dynamic>>{},
      'recommendations': <String>[],
      'strengths': <String>[],
      'improvements': <String>[],
    };

    double totalScore = 0.0;
    int metricCount = 0;

    benchmarks.forEach((metric, benchmark) {
      if (currentMetrics.containsKey(metric)) {
        double current = currentMetrics[metric]!;
        double score = _calculateMetricScore(metric, current, benchmark);

        analysis['metrics'][metric] = {
          'current': current,
          'benchmark': benchmark,
          'score': score,
          'status': _getMetricStatus(score),
        };

        totalScore += score;
        metricCount++;

        if (score >= 90) {
          analysis['strengths'].add(_getMetricDescription(metric));
        } else if (score < 70) {
          analysis['improvements']
              .add(_getMetricRecommendation(metric, current, benchmark));
        }
      }
    });

    analysis['overallScore'] = metricCount > 0 ? totalScore / metricCount : 0.0;

    // Generate recommendations
    if (analysis['overallScore'] < 70) {
      analysis['recommendations']
          .add('Fokus pada improvement di area yang masih kurang');
    }
    if (analysis['overallScore'] >= 85) {
      analysis['recommendations']
          .add('Performa sangat baik! Pertahankan consistency');
    }

    return analysis;
  }

  static double _calculateMetricScore(
      String metric, double current, double benchmark) {
    // Different metrics have different calculation logic
    switch (metric) {
      case 'food_cost_ratio':
      case 'waste_ratio':
      case 'defect_ratio':
        // Lower is better
        return current <= benchmark ? 100.0 : (benchmark / current) * 100;

      default:
        // Higher is better
        return current >= benchmark ? 100.0 : (current / benchmark) * 100;
    }
  }

  static String _getMetricStatus(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Average';
    if (score >= 60) return 'Below Average';
    return 'Poor';
  }

  static String _getMetricDescription(String metric) {
    switch (metric) {
      case 'food_cost_ratio':
        return 'Rasio biaya bahan makanan terkontrol';
      case 'portion_per_staff':
        return 'Produktivitas karyawan tinggi';
      case 'waste_ratio':
        return 'Waste minimum';
      case 'material_efficiency':
        return 'Efisiensi material optimal';
      case 'production_per_staff':
        return 'Output produksi per karyawan baik';
      case 'defect_ratio':
        return 'Tingkat defect rendah';
      default:
        return 'Metrik $metric mencapai target';
    }
  }

  static String _getMetricRecommendation(
      String metric, double current, double benchmark) {
    switch (metric) {
      case 'food_cost_ratio':
        return 'Kurangi biaya bahan dari ${current.toStringAsFixed(1)}% ke ${benchmark.toStringAsFixed(1)}%';
      case 'portion_per_staff':
        return 'Tingkatkan produktivitas dari ${current.toStringAsFixed(0)} ke ${benchmark.toStringAsFixed(0)} porsi/staff';
      case 'waste_ratio':
        return 'Kurangi waste dari ${current.toStringAsFixed(1)}% ke ${benchmark.toStringAsFixed(1)}%';
      default:
        return 'Tingkatkan $metric dari ${current.toStringAsFixed(1)} ke ${benchmark.toStringAsFixed(1)}';
    }
  }
}
