import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'app_theme.dart';
import 'screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kwojruueubkfjnfhrlij.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3b2pydXVldWJrZmpuZmhybGlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQzNzYsImV4cCI6MjA3Mzk1MDM3Nn0.7iu9h2hvjoMG6XaPmBHMSUd43hdHMPegB6U_VzEY2bI',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoTi Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode
          .system, // Use system brightness, or ThemeMode.dark/ThemeMode.light for fixed
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigation(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  bool _isLoading = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkSupabaseConnection();
  }

  Future<void> _checkSupabaseConnection() async {
    try {
      await Supabase.instance.client.from('user_profiles').select().limit(1);
      setState(() => _connectionStatus = 'Connected');
    } catch (e) {
      setState(() => _connectionStatus = 'Not Connected');
    }
  }

  void submit() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final supabase = Supabase.instance.client;

    try {
      if (isLogin) {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) {
          //Show main navigation after login
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed')),
          );
        }
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Registration successful! Please login.')),
          );
          setState(() => isLogin = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isWide = media.size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: [
          Row(
            children: [
              Icon(
                _connectionStatus == 'Connected'
                    ? Icons.check_circle
                    : Icons.error,
                color: _connectionStatus == 'Connected'
                    ? AppColors.deloitteGreen
                    : Colors.red,
                size: 22,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 400 : double.infinity,
            ),
            child: Column(
              children: [
                // Logo Text
                Text(
                  "WoTi Attendance",
                  style: theme.textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.surface,
                  elevation: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock,
                            size: 54, color: AppColors.deloitteGreen),
                        const SizedBox(height: 8),
                        Text(
                          isLogin ? 'Welcome Back!' : 'Register Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deloitteGreen,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email,
                                color: AppColors.deloitteGreen),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock,
                                color: AppColors.deloitteGreen),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.deloitteGreen))
                              : ElevatedButton(
                                  onPressed: submit,
                                  child: Text(isLogin ? 'Login' : 'Register'),
                                ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text("Don't have an account? Register"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
