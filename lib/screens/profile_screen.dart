import 'package:flutter/material.dart';
import 'package:performance_analzer2/screens/login.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/certificate_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        _profileData = await userProvider.getProfile();
      }
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final certificateProvider = Provider.of<CertificateProvider>(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (!userProvider.isLoggedIn) {
      return const Center(child: Text('Please log in to view your profile'));
    }
    
    final user = userProvider.currentUser!;
    final certificateCount = certificateProvider.serverCertificates.length;
    
    // Safely convert dynamic types to integers with fallback values
    final researchCount = _safeIntValue(_profileData['researchCount']);
    final publicationsCount = _safeIntValue(_profileData['publicationsCount']);
    final guestLecturesCount = _safeIntValue(_profileData['guestLecturesCount']);
    final score = certificateProvider.averageScore;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: const NetworkImage('https://via.placeholder.com/150'),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile photo update coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user.isHod ? 'Head of Department' : 'Faculty Staff',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Profile'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile coming soon')),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // Stats row
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(context, certificateCount.toString(), 'Certificates'),
                _buildDivider(),
                _buildStatItem(context, publicationsCount.toString(), 'Publications'),
                _buildDivider(),
                _buildStatItem(context, score.toString(), 'Score'),
              ],
            ),
          ),
          
          // Profile sections
          _buildProfileSection(
            context,
            'Personal Information',
            [
              _buildInfoRow(Icons.email, 'Email', user.email),
              _buildInfoRow(Icons.numbers, 'Registration No', user.regNoAsString),
              _buildInfoRow(Icons.phone, 'Phone', user.phoneAsString),
              _buildInfoRow(Icons.location_on, 'Location', 'Your College, State'),
            ],
          ),
          
          // Education section (placeholder)
          _buildProfileSection(
            context,
            'Education',
            [
              _buildEducationItem(
                'Your Primary Degree',
                'Your University',
                '2019 - 2021',
                'Include any specializations or honors here',
              ),
              const Divider(height: 20),
              _buildEducationItem(
                'Your Secondary Degree',
                'Your University',
                '2015 - 2019',
                'Include GPA or any other relevant information',
              ),
            ],
          ),
          
          // Skills section
          _buildProfileSection(
            context,
            'Skills',
            [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Your Skill 1',
                  'Your Skill 2',
                  'Your Skill 3',
                  'Your Skill 4',
                  'Your Skill 5',
                  'Your Skill 6',
                  'Your Skill 7',
                  'Your Skill 8',
                ].map((skill) => _buildSkillChip(skill)).toList(),
              ),
            ],
          ),
          
          // Certificate breakdown section
          _buildProfileSection(
            context,
            'Certificate Categories',
            [
              _buildCategoryProgressBar(
                'Technical Certifications',
                0.85,
                Colors.blue,
              ),
              const SizedBox(height: 15),
              _buildCategoryProgressBar(
                'Academic Publications',
                0.65,
                Colors.purple,
              ),
              const SizedBox(height: 15),
              _buildCategoryProgressBar(
                'Competition Achievements',
                0.70,
                Colors.orange,
              ),
              const SizedBox(height: 15),
              _buildCategoryProgressBar(
                'Online Courses',
                0.90,
                Colors.green,
              ),
            ],
          ),
          
          // Recent certificates section
          if (certificateProvider.serverCertificates.isNotEmpty)
            _buildProfileSection(
              context,
              'Your Recent Certificates',
              [
                ...certificateProvider.serverCertificates.take(3).map((cert) {
                  return ListTile(
                    leading: Icon(
                      Icons.description,
                      color: Colors.blue.shade700,
                    ),
                    title: Text(cert['CertificateName']?.toString() ?? 'Unknown Certificate'),
                    subtitle: Text('Score: ${cert['Score']?.toString() ?? '0'}'),
                    trailing: Icon(
                      cert['IsOriginal'] == true 
                          ? Icons.check_circle 
                          : Icons.cancel,
                      color: cert['IsOriginal'] == true 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  );
                }).toList(),
                if (certificateProvider.serverCertificates.length > 3)
                  TextButton(
                    onPressed: () {
                      // View all certificates
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
          
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to safely convert dynamic values to int
  int _safeIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }
  
  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.blue.shade100,
    );
  }
  
  Widget _buildProfileSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (title != 'Skills' && title != 'Certificate Categories' && !title.contains('Recent'))
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit section coming soon')),
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    color: Colors.grey[600],
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEducationItem(String degree, String school, String years, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          degree,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.school,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              school,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              years,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSkillChip(String skill) {
    return Chip(
      label: Text(
        skill,
        style: const TextStyle(
          fontSize: 13,
        ),
      ),
      backgroundColor: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      labelPadding: const EdgeInsets.symmetric(horizontal: 5),
    );
  }
  
  Widget _buildCategoryProgressBar(String category, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              await userProvider.logout();
              
              // Clear navigation stack and go to login
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), 
                (route) => false
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}
}