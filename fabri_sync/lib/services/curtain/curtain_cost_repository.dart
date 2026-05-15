/// Curtain cost configuration repository
/// Handles all Supabase database interactions for curtain pricing configuration

import 'package:fabri_sync/services/curtain/curtain_cost_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurtainCostRepository {
  CurtainCostRepository({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  // ============================================================================
  // QUERY METHODS
  // ============================================================================

  /// Fetch curtain cost configuration by specific curtain type, fabric, and header
  /// Returns null if not found
  Future<CurtainCostConfig?> fetchCurtainCostConfig({
    required String curtainType,
    required String fabricType,
    required String headerStyle,
  }) async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .select()
          .eq('curtain_type', curtainType)
          .eq('fabric_type', fabricType)
          .eq('header_style', headerStyle)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return CurtainCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error fetching curtain cost config: $e');
      return null;
    }
  }

  /// Fetch all curtain cost configs (useful for admin/config management)
  Future<List<CurtainCostConfig>> fetchAllCurtainConfigs() async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .select()
          .order('curtain_type', ascending: true);

      return (response as List)
          .map((e) => CurtainCostConfig.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching all curtain configs: $e');
      return [];
    }
  }

  /// Fetch configs by curtain type
  Future<List<CurtainCostConfig>> fetchConfigsByType(String curtainType) async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .select()
          .eq('curtain_type', curtainType)
          .order('fabric_type', ascending: true);

      return (response as List)
          .map((e) => CurtainCostConfig.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching configs by type: $e');
      return [];
    }
  }

  /// Fetch configs by fabric type
  Future<List<CurtainCostConfig>> fetchConfigsByFabric(
    String fabricType,
  ) async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .select()
          .eq('fabric_type', fabricType)
          .order('curtain_type', ascending: true);

      return (response as List)
          .map((e) => CurtainCostConfig.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching configs by fabric: $e');
      return [];
    }
  }

  // ============================================================================
  // CRUD METHODS (For admin configuration)
  // ============================================================================

  /// Create a new curtain cost config
  Future<CurtainCostConfig?> createCurtainCostConfig(
    CurtainCostConfig config,
  ) async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .insert(config.toMap())
          .select()
          .single();

      return CurtainCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error creating curtain cost config: $e');
      return null;
    }
  }

  /// Update an existing curtain cost config
  Future<CurtainCostConfig?> updateCurtainCostConfig(
    CurtainCostConfig config,
  ) async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .update(config.toMap())
          .eq('id', config.id)
          .select()
          .single();

      return CurtainCostConfig.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error updating curtain cost config: $e');
      return null;
    }
  }

  /// Delete a curtain cost config by ID
  Future<bool> deleteCurtainCostConfig(String id) async {
    try {
      await supabase.from('curtain_cost_config').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting curtain cost config: $e');
      return false;
    }
  }

  // ============================================================================
  // SEED DATA & INITIALIZATION
  // ============================================================================

  /// Seed database with default curtain cost configurations
  /// Returns number of configs inserted
  Future<int> seedDefaultConfigurations() async {
    try {
      final now = DateTime.now();
      final seedData = _generateDefaultSeedData(now);

      // Use batch insert
      await supabase.from('curtain_cost_config').insert(seedData);
      return seedData.length;
    } catch (e) {
      print('Error seeding configurations: $e');
      return 0;
    }
  }

  /// Generate realistic default seed data for all curtain combinations
  static List<Map<String, dynamic>> _generateDefaultSeedData(DateTime now) {
    final isoNow = now.toIso8601String();
    const curtainTypes = [
      'Window Curtain',
      'Door Curtain',
      'Blackout Curtain',
      'Decorative Curtain',
    ];
    const fabricTypes = ['Sheer', 'Blackout', 'Thermal'];
    const headerStyles = ['Pleated', 'Eyelet', 'Rod Pocket'];

    final data = <Map<String, dynamic>>[];

    // Generate configs for all combinations
    for (final curtainType in curtainTypes) {
      for (final fabricType in fabricTypes) {
        for (final headerStyle in headerStyles) {
          // Skip unrealistic combinations (e.g., Blackout fabric + Blackout curtain redundant)
          data.add({
            'curtain_type': curtainType,
            'fabric_type': fabricType,
            'header_style': headerStyle,
            'material_rate': _getMaterialRate(fabricType),
            'labor_multiplier': _getLaborMultiplier(fabricType),
            'complexity_multiplier': _getComplexityMultiplier(
              curtainType,
              headerStyle,
            ),
            'base_labor_hours': _getBaseLaborHours(curtainType),
            'processing_cost': _getProcessingCost(curtainType),
            'wastage_percent': _getWastagePercent(fabricType),
            'created_at': isoNow,
            'updated_at': isoNow,
          });
        }
      }
    }

    return data;
  }

  // ============================================================================
  // HELPER METHODS FOR SEED DATA
  // ============================================================================

  static double _getMaterialRate(String fabricType) {
    return switch (fabricType) {
      'Sheer' => 450.0,
      'Blackout' => 850.0,
      'Thermal' => 1200.0,
      _ => 450.0,
    };
  }

  static double _getLaborMultiplier(String fabricType) {
    return switch (fabricType) {
      'Sheer' => 1.00,
      'Blackout' => 1.25,
      'Thermal' => 1.45,
      _ => 1.00,
    };
  }

  static double _getComplexityMultiplier(
    String curtainType,
    String headerStyle,
  ) {
    var typeComplexity = switch (curtainType) {
      'Window Curtain' => 1.00,
      'Door Curtain' => 1.15,
      'Blackout Curtain' => 1.40,
      'Decorative Curtain' => 1.60,
      _ => 1.00,
    };

    var headerMultiplier = switch (headerStyle) {
      'Pleated' => 1.15,
      'Eyelet' => 1.20,
      'Rod Pocket' => 1.05,
      _ => 1.05,
    };

    return typeComplexity * headerMultiplier;
  }

  static double _getBaseLaborHours(String curtainType) {
    return switch (curtainType) {
      'Window Curtain' => 0.80,
      'Door Curtain' => 1.00,
      'Blackout Curtain' => 1.50,
      'Decorative Curtain' => 1.80,
      _ => 0.80,
    };
  }

  static double _getProcessingCost(String curtainType) {
    return switch (curtainType) {
      'Window Curtain' => 200.0,
      'Door Curtain' => 300.0,
      'Blackout Curtain' => 600.0,
      'Decorative Curtain' => 850.0,
      _ => 200.0,
    };
  }

  static double _getWastagePercent(String fabricType) {
    return switch (fabricType) {
      'Sheer' => 5.0,
      'Blackout' => 10.0,
      'Thermal' => 12.0,
      _ => 5.0,
    };
  }

  // ============================================================================
  // HEALTH CHECK / VALIDATION
  // ============================================================================

  /// Check if table exists and has data
  /// Useful for initialization checks
  Future<bool> hasConfigurationData() async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .select('id')
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking configuration data: $e');
      return false;
    }
  }

  /// Count total configurations in database
  Future<int> getConfigurationCount() async {
    try {
      final response = await supabase
          .from('curtain_cost_config')
          .select('id')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting configuration count: $e');
      return 0;
    }
  }
}
