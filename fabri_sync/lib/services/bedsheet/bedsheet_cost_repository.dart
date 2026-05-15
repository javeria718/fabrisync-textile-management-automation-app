/// Bedsheet cost configuration repository.
/// Handles Supabase operations for bedsheet pricing.

import 'package:fabri_sync/services/bedsheet/bedsheet_cost_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BedsheetCostRepository {
  BedsheetCostRepository({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  Future<BedsheetCostConfig?> fetchBedsheetCostConfig({
    required String bedsheetType,
    required String fabricType,
    required String bedSize,
    required String qualityGrade,
  }) async {
    try {
      final response = await supabase
          .from('bedsheet_cost_config')
          .select()
          .eq('bedsheet_type', bedsheetType)
          .eq('fabric_type', fabricType)
          .eq('bed_size', bedSize)
          .eq('quality_grade', qualityGrade)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return BedsheetCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error fetching bedsheet cost config: $e');
      return null;
    }
  }

  Future<List<BedsheetCostConfig>> fetchAllBedsheetConfigs() async {
    try {
      final response = await supabase
          .from('bedsheet_cost_config')
          .select()
          .order('bedsheet_type', ascending: true)
          .order('fabric_type', ascending: true)
          .order('bed_size', ascending: true)
          .order('quality_grade', ascending: true);

      return (response as List)
          .map((e) => BedsheetCostConfig.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching all bedsheet configs: $e');
      return [];
    }
  }

  Future<List<BedsheetCostConfig>> fetchConfigsByType(
    String bedsheetType,
  ) async {
    try {
      final response = await supabase
          .from('bedsheet_cost_config')
          .select()
          .eq('bedsheet_type', bedsheetType)
          .order('fabric_type', ascending: true)
          .order('bed_size', ascending: true)
          .order('quality_grade', ascending: true);

      return (response as List)
          .map((e) => BedsheetCostConfig.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching bedsheet configs by type: $e');
      return [];
    }
  }

  Future<BedsheetCostConfig?> createBedsheetCostConfig(
    BedsheetCostConfig config,
  ) async {
    try {
      final response = await supabase
          .from('bedsheet_cost_config')
          .insert(config.toMap())
          .select()
          .single();
      return BedsheetCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error creating bedsheet cost config: $e');
      return null;
    }
  }

  Future<BedsheetCostConfig?> updateBedsheetCostConfig(
    BedsheetCostConfig config,
  ) async {
    try {
      final response = await supabase
          .from('bedsheet_cost_config')
          .update(config.toMap())
          .eq('id', config.id)
          .select()
          .single();
      return BedsheetCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error updating bedsheet cost config: $e');
      return null;
    }
  }

  Future<bool> deleteBedsheetCostConfig(String id) async {
    try {
      await supabase.from('bedsheet_cost_config').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting bedsheet cost config: $e');
      return false;
    }
  }

  Future<int> seedDefaultConfigurations() async {
    try {
      final now = DateTime.now().toIso8601String();
      final seedData = _generateDefaultSeedData(now);
      await supabase.from('bedsheet_cost_config').insert(seedData);
      return seedData.length;
    } catch (e) {
      print('Error seeding bedsheet configurations: $e');
      return 0;
    }
  }

  static List<Map<String, dynamic>> _generateDefaultSeedData(String isoNow) {
    const bedsheetTypes = ['Flat Sheet', 'Fitted Sheet', 'Pillow Cover Set'];
    const fabricTypes = ['Cotton', 'Blend', 'Silk'];
    const bedSizes = ['Single', 'Double', 'Queen', 'King'];
    const qualityGrades = ['Economy', 'Standard', 'Premium'];

    final data = <Map<String, dynamic>>[];
    for (final type in bedsheetTypes) {
      for (final fabric in fabricTypes) {
        for (final size in bedSizes) {
          for (final quality in qualityGrades) {
            data.add({
              'bedsheet_type': type,
              'fabric_type': fabric,
              'bed_size': size,
              'quality_grade': quality,
              'base_labor_hours': _getBaseLaborHours(type),
              'material_rate': _getMaterialRate(fabric),
              'labor_multiplier': _getLaborMultiplier(type, fabric, quality),
              'processing_rate': _getProcessingRate(type, quality),
              'printing_charge': 850.0,
              'wastage_percent': _getWastagePercent(fabric),
              'created_at': isoNow,
              'updated_at': isoNow,
            });
          }
        }
      }
    }
    return data;
  }

  static double _getBaseLaborHours(String bedsheetType) {
    return switch (bedsheetType) {
      'Flat Sheet' => 0.8,
      'Fitted Sheet' => 1.5,
      'Pillow Cover Set' => 0.5,
      _ => 0.8,
    };
  }

  static double _getMaterialRate(String fabricType) {
    return switch (fabricType) {
      'Cotton' => 650.0,
      'Blend' => 850.0,
      'Silk' => 1600.0,
      _ => 650.0,
    };
  }

  static double _getLaborMultiplier(
    String bedsheetType,
    String fabricType,
    String qualityGrade,
  ) {
    final typeMultiplier = switch (bedsheetType) {
      'Flat Sheet' => 1.0,
      'Fitted Sheet' => 1.5,
      'Pillow Cover Set' => 0.8,
      _ => 1.0,
    };

    final fabricMultiplier = switch (fabricType) {
      'Cotton' => 1.0,
      'Blend' => 1.15,
      'Silk' => 1.6,
      _ => 1.0,
    };

    final qualityMultiplier = switch (qualityGrade) {
      'Economy' => 1.0,
      'Standard' => 1.15,
      'Premium' => 1.4,
      _ => 1.0,
    };

    return typeMultiplier * fabricMultiplier * qualityMultiplier;
  }

  static double _getProcessingRate(String bedsheetType, String qualityGrade) {
    final typeRate = switch (bedsheetType) {
      'Flat Sheet' => 180.0,
      'Fitted Sheet' => 450.0,
      'Pillow Cover Set' => 120.0,
      _ => 180.0,
    };

    final qualityFactor = switch (qualityGrade) {
      'Economy' => 1.0,
      'Standard' => 1.15,
      'Premium' => 1.5,
      _ => 1.0,
    };

    return typeRate * qualityFactor;
  }

  static double _getWastagePercent(String fabricType) {
    return switch (fabricType) {
      'Cotton' => 5.0,
      'Blend' => 7.0,
      'Silk' => 12.0,
      _ => 5.0,
    };
  }

  Future<bool> hasConfigurationData() async {
    try {
      final response = await supabase
          .from('bedsheet_cost_config')
          .select('id')
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking bedsheet configuration data: $e');
      return false;
    }
  }

  Future<int> getConfigurationCount() async {
    try {
      final response = await supabase
          .from('bedsheet_cost_config')
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      print('Error getting bedsheet configuration count: $e');
      return 0;
    }
  }
}
