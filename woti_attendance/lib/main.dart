import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'attendance_screen.dart';
import 'app_theme.dart';

// Deloitte Green
//const Color AppColors.deloitteGreen = Color(0xFF00A859);


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kwojruueubkfjnfhrlij.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3b2pydXVldWJrZmpuZmhybGlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQzNzYsImV4cCI6MjA3Mzk1MDM3Nn0.7iu9h2hvjoMG6XaPmBHMSUd43hdHMPegB6U_VzEY2bI',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoTi Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => AttendanceScreen(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
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
      // Use user_profiles table which always has data
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
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed')),
          );
        }
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful! Please login.')),
          );
          setState(() => isLogin = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        actions: [
          Row(
            children: [
              Icon(
                _connectionStatus == 'Connected'
                    ? Icons.check_circle
                    : Icons.error,
                color: _connectionStatus == 'Connected'
                    ? theme.primaryColor
                    : Colors.red,
                size: 22,
              ),
              SizedBox(width: 8),
            ],
          ),
        ],
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Card(
              color: theme.cardColor,
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "WoTi Attendance",
                      style: theme.textTheme.displayLarge,
                    ),
                    SizedBox(height: 16),
                    Icon(Icons.lock, size: 54, color: theme.primaryColor),
                    SizedBox(height: 8),
                    Text(
                      isLogin ? 'Welcome Back!' : 'Register Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: theme.primaryColor),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: theme.primaryColor),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                          : ElevatedButton(
                              onPressed: submit,
                              child: Text(isLogin ? 'Login' : 'Register'),
                            ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text("Don't have an account? Register"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}