import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/theme.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textBody,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildStatusView(),
          const LogsPage(),
          const ProfilePage(),
        ],
      ),
    );
  }

  Widget _buildStatusView() {
    return StreamBuilder<String>(
      stream: _firebaseService.statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'NORMAL';
        final isTripped = status.toUpperCase() == 'TRIPPED';

        return Stack(
          children: [
            // Background decoration
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isTripped ? AppColors.statusTripped : AppColors.statusStable).withValues(alpha: 0.1),
                ),
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, Irene',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                    ),
                    Text(
                      'ELCB Monitoring System',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),
                    
                    // Main Status Card
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ZoomIn(
                              duration: const Duration(seconds: 1),
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: (isTripped ? AppColors.statusTripped : AppColors.statusStable).withValues(alpha: 0.5),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isTripped ? AppColors.statusTripped : AppColors.statusStable).withValues(alpha: 0.3),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isTripped ? Icons.warning_rounded : Icons.check_circle_rounded,
                                      size: 80,
                                      color: isTripped ? AppColors.statusTripped : AppColors.statusStable,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isTripped ? AppColors.statusTripped : AppColors.statusStable,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                            
                            // Status info
                            FadeInUp(
                              child: _buildInfoCard(
                                icon: Icons.timer_outlined,
                                title: 'Last Updated',
                                value: DateFormat('hh:mm:ss a').format(DateTime.now()),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: _buildInfoCard(
                                icon: Icons.wifi,
                                title: 'Sensor Status',
                                value: 'Connected (ESP32)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textBody, fontSize: 14)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// Placeholder for Logs Page
class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('Previous records of ELCB trips', style: TextStyle(color: AppColors.textBody)),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder(
                stream: firebaseService.tripLogsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final logs = snapshot.data ?? [];
                  
                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          const Text('No trip events recorded', style: TextStyle(color: AppColors.textBody)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return FadeInLeft(
                        delay: Duration(milliseconds: index * 100),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.statusTripped.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flash_on_rounded, color: AppColors.statusTripped, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE, MMM d, yyyy').format(log.timestamp),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      DateFormat('hh:mm:ss a').format(log.timestamp),
                                      style: const TextStyle(color: AppColors.textBody, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textBody),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _consumerController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _consumerController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _firebaseService.getProfile();
    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _addressController.text = user.address;
        _consumerController.text = user.consumerNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => _firebaseService.logout(),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.statusTripped),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const Text('Your electricity connection details', style: TextStyle(color: AppColors.textBody)),
              const SizedBox(height: 32),
              
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _buildField('Full Name', Icons.person_outline, _nameController),
              _buildField('Phone Number', Icons.phone_outlined, _phoneController),
              _buildField('Address', Icons.location_on_outlined, _addressController, maxLines: 3),
              _buildField('Consumer Number', Icons.receipt_long_outlined, _consumerController),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final updatedUser = UserModel(
                        name: _nameController.text,
                        phone: _phoneController.text,
                        address: _addressController.text,
                        consumerNumber: _consumerController.text,
                      );
                      await _firebaseService.saveProfile(updatedUser);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await _firebaseService.resetDatabase();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Database has been reset and initialized!')),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.statusTripped),
                  label: const Text('RESET DATABASE STRUCTURE', style: TextStyle(color: AppColors.statusTripped)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary),
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
      ),
    );
  }
}
