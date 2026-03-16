import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/theme.dart';
import '../services/firebase_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLogin = true;
  bool _isLoading = false;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        await _firebaseService.login(_emailController.text.trim(), _passwordController.text.trim());
      } else {
        await _firebaseService.signUp(_emailController.text.trim(), _passwordController.text.trim());
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
    return Scaffold(
      body: Stack(
        children: [
          // Decoration
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    FadeInDown(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.lock_person_rounded, size: 40, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                      ),
                    ),
                    FadeInDown(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        _isLogin ? 'Sign in to continue monitoring' : 'Secure your home electrical system',
                        style: const TextStyle(color: AppColors.textBody),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 20),
                      FadeInDown(
                        duration: const Duration(milliseconds: 300),
                        child: _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: Icons.lock_reset_rounded,
                          isPassword: true,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    FadeInUp(
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isLogin ? 'LOGIN' : 'SIGN UP',
                                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
