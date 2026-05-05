import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _aadhaarCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _stateCtrl;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _aadhaarCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    
    // Defer fetching until after first frame to use ref safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user != null) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _aadhaarCtrl.text = user.aadhaarNumber ?? '';
      
      // Fetch extra fields from Firestore directly since they might not be in UserModel
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _dobCtrl.text = data['dob'] ?? '';
              _ageCtrl.text = (data['age'] ?? '').toString();
              _stateCtrl.text = data['state'] ?? 'Gujarat';
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _aadhaarCtrl.dispose();
    _dobCtrl.dispose();
    _ageCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'aadhaar': _aadhaarCtrl.text.trim(),
        'dob': _dobCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text.trim()) ?? 0,
        'state': _stateCtrl.text.trim(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('Personal Information'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Full Name', _nameCtrl, enabled: _isEditing),
              const SizedBox(height: 16),
              _buildField('Email', _emailCtrl, enabled: _isEditing),
              const SizedBox(height: 16),
              _buildField('Aadhaar Number', _aadhaarCtrl, enabled: _isEditing, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField('Date of Birth (DD/MM/YYYY)', _dobCtrl, enabled: _isEditing),
              const SizedBox(height: 16),
              _buildField('Age', _ageCtrl, enabled: _isEditing, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField('State / Country', _stateCtrl, enabled: _isEditing),
              
              if (_isEditing) ...[
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveData,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _loadUserData(); // revert
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool enabled = true, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Please enter $label';
            return null;
          },
        ),
      ],
    );
  }
}
