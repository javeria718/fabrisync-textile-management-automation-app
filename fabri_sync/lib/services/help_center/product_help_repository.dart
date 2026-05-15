import 'package:fabri_sync/services/abaya/abaya_cost_config.dart';
import 'package:fabri_sync/services/abaya/abaya_cost_repository.dart';
import 'package:fabri_sync/services/bedsheet/bedsheet_cost_config.dart';
import 'package:fabri_sync/services/bedsheet/bedsheet_cost_repository.dart';
import 'package:fabri_sync/services/curtain/curtain_cost_config.dart';
import 'package:fabri_sync/services/curtain/curtain_cost_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductHelpRepository {
  ProductHelpRepository({SupabaseClient? client})
    : supabase = client ?? Supabase.instance.client;

  final SupabaseClient supabase;

  Future<List<CurtainCostConfig>> fetchAllCurtainCostConfigs() async {
    return await CurtainCostRepository(
      client: supabase,
    ).fetchAllCurtainConfigs();
  }

  Future<List<AbayaCostConfig>> fetchAllAbayaCostConfigs() async {
    return await AbayaCostRepository(client: supabase).fetchAllAbayaConfigs();
  }

  Future<List<BedsheetCostConfig>> fetchAllBedsheetCostConfigs() async {
    return await BedsheetCostRepository(
      client: supabase,
    ).fetchAllBedsheetConfigs();
  }
}
