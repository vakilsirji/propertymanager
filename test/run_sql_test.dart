import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() {
  test('Run SQL', () async {
    dotenv.testLoad(fileInput: File('.env').readAsStringSync());
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    final supabase = Supabase.instance.client;
    
    // Add owner_id
    try {
      final res = await supabase.rpc('execute_sql', params: {
        'sql': '''
          ALTER TABLE public.leads ADD COLUMN owner_id UUID REFERENCES public.users(id);
        '''
      });
      print('SQL success: \$res');
    } catch (e) {
      print('SQL failed, maybe already exists or no RPC: \$e');
    }
  });
}
