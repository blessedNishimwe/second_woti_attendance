import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'app_theme.dart';
import 'screens/main_navigation.dart';
import 'di/service_locator.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/optimized_auth_provider.dart';
import 'providers/optimized_attendance_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://kwojruueubkfjnfhrlij.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3b2pydXVldWJrZmpuZmhybGlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQzNzYsImV4cCI6MjA3Mzk1MDM3Nn0.7iu9h2hvjoMG6XaPmBHMSUd43hdHMPegB6U_VzEY2bI',
  );
  
  // Initialize dependency injection
  await initializeDependencies();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => serviceLocator<OptimizedAuthProvider>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<OptimizedAttendanceProvider>()),
      ],
      child: MaterialApp(
        title: 'WoTi Attendance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/home': (context) => const MainNavigation(),
          '/register': (context) => RegisterScreen(),
        },
      ),
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
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  bool isLogin = true;
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

  Future<void> _submit() async {
    final authProvider = Provider.of<OptimizedAuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    bool success;
    if (isLogin) {
      success = await authProvider.login(email, password);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }

      success = await authProvider.register(
        email: email,
        password: password,
        name: name,
        employeeId: _employeeIdController.text.trim().isEmpty 
            ? null 
            : _employeeIdController.text.trim(),
        department: _departmentController.text.trim().isEmpty 
            ? null 
            : _departmentController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => isLogin = true);
        _clearForm();
      }
    }

    if (!success && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _employeeIdController.clear();
    _departmentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isWide = media.size.width > 600;

    return Consumer<OptimizedAuthProvider>(
      builder: (context, authProvider, child) {
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
                            if (!isLogin) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person,
                                      color: AppColors.deloitteGreen),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _employeeIdController,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Employee ID (Optional)',
                                  prefixIcon: Icon(Icons.badge,
                                      color: AppColors.deloitteGreen),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _departmentController,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Department (Optional)',
                                  prefixIcon: Icon(Icons.business,
                                      color: AppColors.deloitteGreen),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: authProvider.isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.deloitteGreen))
                                  : ElevatedButton(
                                      onPressed: _submit,
                                      child: Text(isLogin ? 'Login' : 'Register'),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() => isLogin = !isLogin);
                                _clearForm();
                              },
                              child: Text(isLogin 
                                  ? "Don't have an account? Register"
                                  : "Already have an account? Login"),
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
      },
    );
  }
}
