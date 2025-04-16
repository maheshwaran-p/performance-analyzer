import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:cached_network_image/cached_network_image.dart';

import '../providers/user_provider.dart';
import '../providers/certificate_provider.dart';
import 'auth/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        final profileData = await userProvider.getProfile();
        setState(() {
          _profileData = profileData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Logout'),
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.logout();
                
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), 
                  (route) => false
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final certificateProvider = Provider.of<CertificateProvider>(context);
    
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 12,
          color: Colors.blue,
        ),
      );
    }
    
    if (!userProvider.isLoggedIn) {
      return const Center(
        child: Text('Please log in to view your profile'),
      );
    }
    
    final user = userProvider.currentUser!;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade800,
                        ],
                      ),
                    ),
                  ),
                  
                  // Profile Image and Details
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Hero(
                          tag: 'profile_image',
child: Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.white,
      width: 4,
    ),
  ),
  child: CircleAvatar(
    radius: 60,
    backgroundColor: Colors.blue.shade600,
    child: Text(
      user.name.isNotEmpty 
        ? user.name[0].toUpperCase() 
        : 'U', // Default to 'U' if name is empty
      style: const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.isHod ? 'Head of Department' : 'Faculty Staff',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _showLogoutDialog,
              ),
            ],
          ),
          
          // Profile Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Professional Stats
                _buildStatsCard(context, certificateProvider),
                
                // Personal Information
                _buildSectionCard(
                  title: 'Personal Information',
                  children: [
                    _buildDetailRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: user.email,
                    ),
                    _buildDetailRow(
                      icon: Icons.numbers,
                      label: 'Registration No',
                      value: user.regNoAsString,
                    ),
                    _buildDetailRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: user.phoneAsString,
                    ),
                  ],
                ),
                
                // Skills
                _buildSectionCard(
                  title: 'Skills',
                  children: _buildSkillChips(
                    _profileData['skills']?.toString().split(',') ?? []
                  ),
                ),
                
                // Certificate Categories
                _buildCertificateCategoriesCard(),
                
                // Recent Certificates
                _buildRecentCertificatesCard(certificateProvider),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, CertificateProvider certificateProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn(
              value: _profileData['certificatesCount']?.toString() ?? '0',
              label: 'Certificates',
              color: Colors.blue,
            ),
            _buildStatColumn(
              value: _profileData['publicationsCount']?.toString() ?? '0',
              label: 'Publications',
              color: Colors.purple,
            ),
            _buildStatColumn(
              value: certificateProvider.averageScore.toString(),
              label: 'Score',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String value, 
    required String label, 
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title, 
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon, 
    required String label, 
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkillChips(List<String> skills) {
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills
          .where((skill) => skill.trim().isNotEmpty)
          .map((skill) => Chip(
            label: Text(skill.trim()),
            backgroundColor: Colors.blue.shade50,
            labelStyle: const TextStyle(color: Colors.blue),
          ))
          .toList(),
      ),
    ];
  }

  Widget _buildCertificateCategoriesCard() {
    final categories = _profileData['certificateCategories'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Certificate Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 20),
            ...categories.entries.map((entry) => _buildCategoryProgressBar(
              category: entry.key,
              progress: entry.value ?? 0.0,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgressBar({
    required String category, 
    required double progress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Technical Certifications':
        return Colors.blue;
      case 'Academic Publications':
        return Colors.purple;
      case 'Competition Achievements':
        return Colors.orange;
      case 'Online Courses':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentCertificatesCard(CertificateProvider certificateProvider) {
    final originalCertificates = certificateProvider.serverCertificates
      .where((cert) => cert['IsOriginal'] == true)
      .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Certificates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 20),
            if (originalCertificates.isEmpty)
              const Center(
                child: Text(
                  'No original certificates found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...originalCertificates.take(3).map((cert) => ListTile(
                leading: Icon(
                  Icons.verified,
                  color: Colors.green.shade700,
                ),
                title: Text(
                  cert['CertificateName']?.toString() ?? 'Unknown Certificate',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Score: ${cert['Score']?.toString() ?? '0'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              )).toList(),
            if (originalCertificates.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Implement view all certificates
                },
                child: const Text('View All Certificates'),
              ),
          ],
        ),
      ),
    );
  }
}