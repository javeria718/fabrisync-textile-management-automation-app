/// Abaya cost configuration repository.
/// Handles Supabase access for abaya pricing configuration.

import 'package:flutter/foundation.dart';
import 'package:fabri_sync/services/abaya/abaya_cost_config.dart';
import 'package:fabri_sync/services/abaya/abaya_pricing_rules.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbayaCostRepository {
  AbayaCostRepository({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  Future<AbayaCostConfig?> fetchAbayaCostConfig({
    required String abayaType,
    required String fabricType,
    required String qualityGrade,
  }) async {
    final normalizedAbayaType = AbayaPricingRules.normalizeLegacyAbayaType(
      abayaType,
    );

    // Debug: print incoming values to diagnose lookup mismatches
    try {
      debugPrint('ABAYA COST LOOKUP - RAW: "' + abayaType + '"');
      debugPrint(
        'ABAYA COST LOOKUP - NORMALIZED: "' + normalizedAbayaType + '"',
      );
      debugPrint('ABAYA COST LOOKUP - FABRIC: "' + fabricType + '"');
      debugPrint('ABAYA COST LOOKUP - QUALITY: "' + qualityGrade + '"');
    } catch (_) {}

    // Try multiple lookup strategies to avoid failures after value refactors.
    final candidates = [normalizedAbayaType, abayaType];

    try {
      for (final candidate in candidates) {
        // exact match
        debugPrint(
          'ABAYA COST QUERY: trying exact match for "' + candidate + '"',
        );
        var response = await supabase
            .from('abaya_cost_config')
            .select()
            .eq('abaya_type', candidate)
            .eq('fabric_type', fabricType)
            .eq('quality_grade', qualityGrade)
            .limit(1)
            .maybeSingle();

        debugPrint(
          'ABAYA COST QUERY RESULT (exact): ' + (response == null ? '0' : '1'),
        );
        if (response != null) {
          debugPrint('ABAYA COST FOUND (exact) for "' + candidate + '"');
          return AbayaCostConfig.fromMap(Map<String, dynamic>.from(response));
        }

        // try case-insensitive match
        debugPrint(
          'ABAYA COST QUERY: trying case-insensitive match for "' +
              candidate +
              '"',
        );
        response = await supabase
            .from('abaya_cost_config')
            .select()
            .ilike('abaya_type', candidate)
            .eq('fabric_type', fabricType)
            .eq('quality_grade', qualityGrade)
            .limit(1)
            .maybeSingle();

        debugPrint(
          'ABAYA COST QUERY RESULT (ilike): ' + (response == null ? '0' : '1'),
        );
        if (response != null) {
          debugPrint('ABAYA COST FOUND (ilike) for "' + candidate + '"');
          return AbayaCostConfig.fromMap(Map<String, dynamic>.from(response));
        }
      }

      debugPrint(
        'ABAYA COST QUERY: no matching config found for any candidate',
      );
      return null;
    } catch (e) {
      print('Error fetching abaya cost config: $e');
      return null;
    }
  }

  Future<List<AbayaCostConfig>> fetchAllAbayaConfigs() async {
    try {
      final response = await supabase
          .from('abaya_cost_config')
          .select()
          .order('abaya_type', ascending: true)
          .order('fabric_type', ascending: true)
          .order('quality_grade', ascending: true);

      return (response as List)
          .map((e) => AbayaCostConfig.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching all abaya configs: $e');
      return [];
    }
  }

  Future<List<AbayaCostConfig>> fetchConfigsByType(String abayaType) async {
    final normalizedAbayaType = AbayaPricingRules.normalizeLegacyAbayaType(
      abayaType,
    );
    try {
      final response = await supabase
          .from('abaya_cost_config')
          .select()
          .eq('abaya_type', normalizedAbayaType)
          .order('fabric_type', ascending: true)
          .order('quality_grade', ascending: true);

      return (response as List)
          .map((e) => AbayaCostConfig.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching configs by type: $e');
      return [];
    }
  }

  Future<AbayaCostConfig?> createAbayaCostConfig(AbayaCostConfig config) async {
    try {
      final response = await supabase
          .from('abaya_cost_config')
          .insert(config.toMap())
          .select()
          .single();
      return AbayaCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error creating abaya cost config: $e');
      return null;
    }
  }

  Future<AbayaCostConfig?> updateAbayaCostConfig(AbayaCostConfig config) async {
    try {
      final response = await supabase
          .from('abaya_cost_config')
          .update(config.toMap())
          .eq('id', config.id)
          .select()
          .single();
      return AbayaCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error updating abaya cost config: $e');
      return null;
    }
  }

  Future<bool> deleteAbayaCostConfig(String id) async {
    try {
      await supabase.from('abaya_cost_config').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting abaya cost config: $e');
      return false;
    }
  }

  Future<int> seedDefaultConfigurations() async {
    try {
      final now = DateTime.now().toIso8601String();
      final seedData = _generateDefaultSeedData(now);
      await supabase.from('abaya_cost_config').insert(seedData);
      return seedData.length;
    } catch (e) {
      print('Error seeding abaya configurations: $e');
      return 0;
    }
  }

  static List<Map<String, dynamic>> _generateDefaultSeedData(String isoNow) {
    const abayaTypes = ['Casual Abaya', 'Fancy Abaya', 'Embroidered Abaya'];
    const fabricTypes = ['Nidha', 'Chiffon', 'Georgette'];
    const qualityGrades = ['Economy', 'Standard', 'Premium'];

    final data = <Map<String, dynamic>>[];
    for (final type in abayaTypes) {
      for (final fabric in fabricTypes) {
        for (final quality in qualityGrades) {
          data.add({
            'abaya_type': type,
            'fabric_type': fabric,
            'quality_grade': quality,
            'base_labor_hours': _getBaseLaborHours(type),
            'fabric_rate': _getFabricRate(fabric),
            'labor_multiplier': _getLaborMultiplier(type, fabric, quality),
            'processing_rate': _getProcessingRate(type, quality),
            'embellishment_cost': _getEmbellishmentCost(type),
            'wastage_percent': _getWastagePercent(fabric),
            'created_at': isoNow,
            'updated_at': isoNow,
          });
        }
      }
    }
    return data;
  }

  static double _getBaseLaborHours(String abayaType) {
    return switch (abayaType) {
      'Casual Abaya' => 1.2,
      'Fancy Abaya' => 2.0,
      'Embroidered Abaya' => 3.0,
      _ => 1.2,
    };
  }

  static double _getFabricRate(String fabricType) {
    return switch (fabricType) {
      'Nidha' => 850.0,
      'Chiffon' => 1200.0,
      'Georgette' => 1050.0,
      _ => 850.0,
    };
  }

  static double _getLaborMultiplier(
    String abayaType,
    String fabricType,
    String qualityGrade,
  ) {
    final typeMultiplier = switch (abayaType) {
      'Casual Abaya' => 1.0,
      'Fancy Abaya' => 1.4,
      'Embroidered Abaya' => 1.8,
      _ => 1.0,
    };

    final fabricMultiplier = switch (fabricType) {
      'Nidha' => 1.0,
      'Chiffon' => 1.35,
      'Georgette' => 1.2,
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

  static double _getProcessingRate(String abayaType, String qualityGrade) {
    final base = switch (abayaType) {
      'Casual Abaya' => 250.0,
      'Fancy Abaya' => 550.0,
      'Embroidered Abaya' => 900.0,
      _ => 250.0,
    };

    final qualityFactor = switch (qualityGrade) {
      'Economy' => 1.0,
      'Standard' => 1.15,
      'Premium' => 1.35,
      _ => 1.0,
    };

    return base * qualityFactor;
  }

  static double _getEmbellishmentCost(String abayaType) {
    return switch (abayaType) {
      'Casual Abaya' => 450.0,
      'Fancy Abaya' => 450.0,
      'Embroidered Abaya' => 450.0,
      _ => 450.0,
    };
  }

  static double _getWastagePercent(String fabricType) {
    return switch (fabricType) {
      'Nidha' => 5.0,
      'Chiffon' => 10.0,
      'Georgette' => 8.0,
      _ => 5.0,
    };
  }

  Future<bool> hasConfigurationData() async {
    try {
      final response = await supabase
          .from('abaya_cost_config')
          .select('id')
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking abaya configuration data: $e');
      return false;
    }
  }

  Future<int> getConfigurationCount() async {
    try {
      final response = await supabase
          .from('abaya_cost_config')
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      print('Error getting abaya configuration count: $e');
      return 0;
    }
  }
}
