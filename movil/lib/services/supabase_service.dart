import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://tpjaebcovdpkhqgcsewk.supabase.co';
  static const String anonKey = 'sb_publishable_JHjk-xXpcz9ofx3JyxLrdQ_o27lUQS7';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}
