// File: lib/widgets/business/business_type_selection_widget.dart

import 'package:flutter/material.dart';
import '../../models/business_type.dart';
import '../../services/business_type_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class BusinessTypeSelectionWidget extends StatefulWidget {
  final BusinessTypeEnum? selectedType;
  final Function(BusinessTypeEnum) onTypeSelected;
  final VoidCallback? onAnalysisRequested;

  const BusinessTypeSelectionWidget({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    this.onAnalysisRequested,
  });

  @override
  BusinessTypeSelectionWidgetState createState() =>
      BusinessTypeSelectionWidgetState();
}

class BusinessTypeSelectionWidgetState
    extends State<BusinessTypeSelectionWidget> {
  BusinessType? _selectedBusiness;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedType != null) {
      _selectedBusiness =
          BusinessTypeService.getBusinessTypeByEnum(widget.selectedType!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildBusinessTypeGrid(),
            if (_selectedBusiness != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildSelectedBusinessDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.business,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Pilih Jenis Usaha',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        if (_selectedBusiness != null)
          IconButton(
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            icon: Icon(
              _showDetails ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessTypeGrid() {
    final businessTypes = BusinessTypeService.getAllBusinessTypes();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: businessTypes.length,
      itemBuilder: (context, index) {
        final business = businessTypes[index];
        final isSelected = _selectedBusiness?.type == business.type;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedBusiness = business;
              _showDetails = true;
            });
            widget.onTypeSelected(business.type);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  business.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  business.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedBusinessDetails() {
    if (!_showDetails) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Business Info
          _buildBusinessInfo(),

          const SizedBox(height: 16),

          // Characteristics
          _buildCharacteristics(),

          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _selectedBusiness!.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBusiness!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _selectedBusiness!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristics() {
    final chars = _selectedBusiness!.characteristics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Karakteristik Usaha:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _buildCharacteristicCard(
                'Margin Tipikal',
                '${chars.typicalMargin.toStringAsFixed(0)}%',
                Icons.trending_up,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCharacteristicCard(
                'Unit Utama',
                _selectedBusiness!.primaryUnit,
                Icons.straighten,
                AppColors.info,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Common Ingredients Preview
        if (_selectedBusiness!.commonIngredients.isNotEmpty) ...[
          const Text(
            'Bahan Umum:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _selectedBusiness!.commonIngredients
                .take(6)
                .map(
                  (ingredient) => Chip(
                    label: Text(
                      ingredient,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                    side: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.3)),
                  ),
                )
                .toList(),
          ),
          if (_selectedBusiness!.commonIngredients.length > 6)
            Text(
              '+${_selectedBusiness!.commonIngredients.length - 6} lainnya',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCharacteristicCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showIngredientSuggestions();
            },
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Saran Bahan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onAnalysisRequested,
            icon: const Icon(Icons.analytics),
            label: const Text('Analisis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showIngredientSuggestions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SmartIngredientSuggestionsWidget(
        businessType: _selectedBusiness!.type,
        onIngredientSelected: (ingredient) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saran: $ingredient'),
              backgroundColor: AppColors.info,
            ),
          );
        },
      ),
    );
  }
}

// Smart Ingredient Suggestions Widget
class SmartIngredientSuggestionsWidget extends StatefulWidget {
  final BusinessTypeEnum businessType;
  final Function(String) onIngredientSelected;

  const SmartIngredientSuggestionsWidget({
    super.key,
    required this.businessType,
    required this.onIngredientSelected,
  });

  @override
  SmartIngredientSuggestionsWidgetState createState() =>
      SmartIngredientSuggestionsWidgetState();
}

class SmartIngredientSuggestionsWidgetState
    extends State<SmartIngredientSuggestionsWidget> {
  final _searchController = TextEditingController();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSuggestions(String query) {
    setState(() {
      _suggestions = BusinessTypeService.getSmartIngredientSuggestions(
        businessType: widget.businessType,
        query: query,
        limit: 20,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.secondary),
              const SizedBox(width: 8),
              const Text(
                'Saran Bahan Usaha',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Cari bahan...',
              hintText: 'Ketik nama bahan',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _loadSuggestions,
          ),

          const SizedBox(height: 16),

          // Suggestions List
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final ingredient = _suggestions[index];
                final recommendedUnit = BusinessTypeService.getRecommendedUnit(
                  businessType: widget.businessType,
                  ingredientName: ingredient,
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                    child: Text(
                      ingredient.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(ingredient),
                  subtitle: Text('Satuan rekomendasi: $recommendedUnit'),
                  trailing: const Icon(Icons.add),
                  onTap: () => widget.onIngredientSelected(ingredient),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
