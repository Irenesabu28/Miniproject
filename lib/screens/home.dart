import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'scan_qr.dart';
import 'wifi_setup.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StatusView(),
          LogsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.1), BlendMode.dstIn),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  const SizedBox(width: 50), // Space for centered item
                  _NavBarItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                ],
              ),
              Positioned(
                top: -30,
                left: 0,
                right: 0,
                child: Center(
                  child: _NavBarCenterItem(
                    icon: Icons.bolt_rounded,
                    label: 'Trips',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textBody.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? AppColors.primary : AppColors.textBody.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarCenterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarCenterItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isActive ? AppColors.primary : AppColors.textBody.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class StatusView extends StatelessWidget {
  const StatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    
    return StreamBuilder<String>(
      stream: firebaseService.statusStream,
      builder: (context, statusSnapshot) {
        return StreamBuilder<UserModel>(
          stream: firebaseService.profileStream,
          builder: (context, userSnapshot) {
            final user = userSnapshot.data ?? const UserModel();
            final status = statusSnapshot.data ?? 'NORMAL';
            final isTripped = status.toUpperCase() == 'TRIPPED';
            final statusColor = isTripped ? AppColors.statusTripped : AppColors.statusStable;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VoltGuard',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      Center(
                        child: Column(
                          children: [
                            const StatusOrbModule(),
                            const SizedBox(height: 56),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'SYSTEM STATUS: ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  status.toUpperCase() == 'NORMAL' ? 'SECURE' : status.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isTripped ? 'Danger: Leakage Detected' : 'Current Leakage: 2mA (Very Low)',
                              style: TextStyle(
                                color: isTripped ? Colors.redAccent.withValues(alpha: 0.9) : AppColors.primary.withValues(alpha: 0.9),
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // Small Safety Overview Icon
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "SECURE",
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionTile(
                                    label: "LINK NEW\nDEVICE",
                                    icon: Icons.qr_code_scanner_rounded,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ScanQRPage()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _ActionTile(
                                    label: "CONFIGURE\nDEVICE WIFI",
                                    icon: Icons.wifi_tethering_rounded,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const WifiSetupPage()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 120), // Spacer for bottom nav
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class StatusOrbModule extends StatelessWidget {
  const StatusOrbModule({super.key});

  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ultra Outer Glow
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
            
            // Neon Outer Ring
            Spin(
              duration: const Duration(seconds: 10),
              infinite: true,
              child: Container(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: 0.7,
                  strokeWidth: 2,
                  color: AppColors.primary.withValues(alpha: 0.3),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),

            // Neon Middle Ring
            Spin(
              duration: const Duration(seconds: 15),
              infinite: true,
              child: Container(
                width: 210,
                height: 210,
                child: CircularProgressIndicator(
                  value: 0.4,
                  strokeWidth: 3,
                  color: AppColors.primary.withValues(alpha: 0.4),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),

            // Neon Inner Ring
            Spin(
              duration: const Duration(seconds: 5),
              infinite: true,
              child: Container(
                width: 170,
                height: 170,
                child: const CircularProgressIndicator(
                  value: 0.3,
                  strokeWidth: 5,
                  color: AppColors.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),

            // Final Glowing Core
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 50),
            ),
          ],
        ),
      ),
    );
  }
}


class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trip History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Detailed logs of all ELCB events', style: TextStyle(color: AppColors.textBody)),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<TripLog>>(
                  stream: firebaseService.tripLogsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final logs = snapshot.data ?? [];
                    
                    if (logs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.white10),
                            SizedBox(height: 16),
                            Text('No trip events recorded', style: TextStyle(color: AppColors.textBody)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: logs.length,
                      padding: const EdgeInsets.only(bottom: 100),
                      itemBuilder: (context, index) {
                        return FadeInLeft(
                          delay: Duration(milliseconds: index * 100),
                          child: LogEntryCard(log: logs[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogEntryCard extends StatelessWidget {
  final TripLog log;
  const LogEntryCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              color: AppColors.statusTripped.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.statusTripped, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(log.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('hh:mm a').format(log.timestamp),
                  style: const TextStyle(color: AppColors.textBody, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.info_outline_rounded, color: AppColors.textBody),
        ],
      ),
    );
  }
}

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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _consumerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await _firebaseService.getProfile();
    if (user != null) {
      if (mounted) {
        setState(() {
          _nameController.text = user.name;
          _phoneController.text = user.phone;
          _addressController.text = user.address;
          _consumerController.text = user.consumerNumber;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final updatedUser = UserModel(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      consumerNumber: _consumerController.text,
    );
    
    await _firebaseService.saveProfile(updatedUser);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: SingleChildScrollView( // RESTORED SCROLLING TO FIX OVERFLOW
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => _firebaseService.logout(),
                          icon: const Icon(Icons.logout_rounded, color: AppColors.statusTripped),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    const Text('Subscription and Account Details', style: TextStyle(color: AppColors.textBody)),
                    const SizedBox(height: 32),
                    
                    const ProfileAvatar(),
                    const SizedBox(height: 32),
                    
                    ProfileField(label: 'Full Name', icon: Icons.person_outline, controller: _nameController),
                    ProfileField(label: 'Phone Number', icon: Icons.phone_outlined, controller: _phoneController),
                    ProfileField(label: 'Address', icon: Icons.location_on_outlined, controller: _addressController, maxLines: 2),
                    ProfileField(label: 'Consumer Number', icon: Icons.receipt_long_outlined, controller: _consumerController),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 10,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        child: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _ResetDatabaseButton(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetDatabaseButton extends StatelessWidget {
  const _ResetDatabaseButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await FirebaseService().resetDatabase();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Database has been reset and initialized!')),
            );
          }
        },
        icon: const Icon(Icons.refresh_rounded, color: AppColors.statusTripped),
        label: const Text('RESET SYSTEM DATA', style: TextStyle(color: AppColors.statusTripped)),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6366F1), // Reference blue
            ),
            child: const Icon(Icons.person, size: 60, color: Colors.white),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;

  const ProfileField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
