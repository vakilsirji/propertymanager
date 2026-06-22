import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  final supabase = Supabase.instance.client;
  
  try {
    await supabase.rpc('execute_sql', params: {
      'sql': '''
        ALTER TABLE public.leads 
        ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES public.users(id);
      '''
    });
    print('SQL Executed successfully!');
  } catch (e) {
    print('Error executing SQL: \$e');
  }
}
