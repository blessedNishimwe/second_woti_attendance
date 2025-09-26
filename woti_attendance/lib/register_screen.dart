import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole;
  String? _selectedRegionId;
  String? _selectedCouncilId;
  String? _selectedFacilityId;

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _councils = [];
  List<Map<String, dynamic>> _facilities = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchRegions();
  }

  Future<void> _fetchRegions() async {
    final data = await Supabase.instance.client
        .from('regions')
        .select('id, name')
        .order('name');
    setState(() {
      _regions = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _fetchCouncils(String regionId) async {
    setState(() {
      _councils = [];
      _facilities = [];
      _selectedCouncilId = null;
      _selectedFacilityId = null;
    });
    final data = await Supabase.instance.client
        .from('councils')
        .select('id, name')
        .eq('region_id', regionId)
        .order('name');
    setState(() {
      _councils = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _fetchFacilities(String councilId) async {
    setState(() {
      _facilities = [];
      _selectedFacilityId = null;
    });
    final data = await Supabase.instance.client
        .from('facilities')
        .select('id, name')
        .eq('council_id', councilId)
        .order('name');
    setState(() {
      _facilities = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() ||
        _selectedRole == null ||
        _selectedRegionId == null ||
        _selectedCouncilId == null ||
        _selectedFacilityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Register user with Supabase Auth and pass metadata for trigger
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'name': _nameController.text.trim(),
          'role': _selectedRole!,
        },
      );
      final user = response.user;

      if (user != null) {
        // Update user_profiles with facility_id
        await Supabase.instance.client
            .from('user_profiles')
            .update({
              'facility_id': _selectedFacilityId,
            })
            .eq('id', user.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please login.')),
        );
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context); // Go back to login
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Register for WoTi Attendance'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWideScreen ? 32 : 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? 600 : double.infinity,
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isWideScreen ? 32 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "WoTi Attendance",
                        style: theme.textTheme.displayLarge,
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Full Name'),
                        validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) =>
                            val!.isEmpty ? 'Enter your email' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (val) => val!.length < 6
                            ? 'Password must be at least 6 chars'
                            : null,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(labelText: 'Role'),
                        items: [
                          DropdownMenuItem(
                              value: 'worker', child: Text('Worker')),
                          DropdownMenuItem(
                              value: 'manager', child: Text('Manager')),
                          DropdownMenuItem(
                              value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedRole = val),
                      validator: (val) =>
                          val == null ? 'Select a role' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRegionId,
                      decoration: InputDecoration(labelText: 'Region'),
                      items: _regions
                          .map<DropdownMenuItem<String>>((r) => DropdownMenuItem<String>(
                                value: r['id'] as String,
                                child: Text(r['name']),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedRegionId = val);
                        if (val != null) _fetchCouncils(val);
                      },
                      validator: (val) =>
                          val == null ? 'Select a region' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCouncilId,
                      decoration: InputDecoration(labelText: 'Council'),
                      items: _councils
                          .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                                value: c['id'] as String,
                                child: Text(c['name']),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedCouncilId = val);
                        if (val != null) _fetchFacilities(val);
                      },
                      validator: (val) =>
                          val == null ? 'Select a council' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFacilityId,
                      decoration: InputDecoration(labelText: 'Facility'),
                      items: _facilities
                          .map<DropdownMenuItem<String>>((f) => DropdownMenuItem<String>(
                                value: f['id'] as String,
                                child: Text(f['name']),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedFacilityId = val),
                      validator: (val) =>
                          val == null ? 'Select a facility' : null,
                    ),
                    SizedBox(height: 24),
                    _loading
                        ? CircularProgressIndicator(color: kDeloitteGreen)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _register,
                              child: Text('Register'),
                            ),
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