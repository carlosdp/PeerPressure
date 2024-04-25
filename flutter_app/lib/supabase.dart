import 'package:supabase_flutter/supabase_flutter.dart';
import './mode.dart';

const supabaseUrl = isDev
    ? 'http://192.168.0.221:54321'
    : 'https://crvwkrbiwxbxwxmzgzcn.supabase.co';
const supabaseAnonKey = isDev
    ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
    : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNydndrcmJpd3hieHd4bXpnemNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTQwNTc0ODYsImV4cCI6MjAyOTYzMzQ4Nn0.4Ce-GB40wCZwW9ZukKRIPdaDg8Nl1tkXEMJXpS3Ja4A';
final supabase = Supabase.instance.client;
