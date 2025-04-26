import 'package:flutter/material.dart';
import 'package:performance_analzer2/service/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _staffList = [];
  Map<String, dynamic> _departmentStats = {};
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would fetch this data from your API
      // This is simulated data based on our known staff
      _staffList = [
        {
          'name': 'Asmitha Ck',
          'regNo': '312821104017',
          'email': 'asmick76@gmail.com',
          'phone': '7305721973',
          'certificateCount': 5,
          'averageScore': 78,
          'role': 'Staff',
        },
        {
          'name': 'Kaviya K',
          'regNo': '312821104054',
          'email': 'kk9861769@gmail.com',
          'phone': '7305681453',
          'certificateCount': 7,
          'averageScore': 82,
          'role': 'Staff',
        },
        {
          'name': 'Kavipriya S',
          'regNo': '312821104053',
          'email': 'kavipriyamalathi18@gmail.com',
          'phone': '9840837026',
          'certificateCount': 4,
          'averageScore': 75,
          'role': 'Staff',
        },
      ];

      // Calculate department statistics
      int totalCertificates = 0;
      int totalScore = 0;
      
      for (var staff in _staffList) {
        totalCertificates += staff['certificateCount'] as int;
        totalScore += (staff['certificateCount'] as int) * (staff['averageScore'] as int);
      }
      
      _departmentStats = {
        'totalStaff': _staffList.length,
        'totalCertificates': totalCertificates,
        'averageScore': totalCertificates > 0 ? (totalScore / totalCertificates).round() : 0,
        'pendingReviews': 2, // Simulated data
      };
    } catch (e) {
      print('Error loading HOD dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    if (!userProvider.isLoggedIn) {
      return const Center(child: Text('Please log in to view the dashboard'));
    }
    
    final user = userProvider.currentUser!;
    
    if (!user.isHod) {
      return const Center(
        child: Text('You need HOD privileges to access this dashboard'),
      );
    }
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Text(
            'Welcome, ${user.name}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Department Dashboard',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Department stats cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Staff Members',
                _departmentStats['totalStaff'].toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Total Certificates',
                _departmentStats['totalCertificates'].toString(),
                Icons.description,
                Colors.green,
              ),
              _buildStatCard(
                'Average Score',
                _departmentStats['averageScore'].toString(),
                Icons.analytics,
                Colors.purple,
              ),
              _buildStatCard(
                'Pending Reviews',
                _departmentStats['pendingReviews'].toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Staff list
          const Text(
            'Staff Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _staffList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final staff = _staffList[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(staff['name'].substring(0, 1)),
                  ),
                  title: Text(staff['name']),
                  subtitle: Text('Certificates: ${staff['certificateCount']}'),
                  trailing: _buildScoreIndicator(staff['averageScore']),
                  onTap: () {
                    _showStaffDetailsDialog(context, staff);
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          // const Text(
          //   'Quick Actions',
          //   style: TextStyle(
          //     fontSize: 20,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // const SizedBox(height: 16),
          
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildActionButton(
          //         'Review Certificates',
          //         Icons.fact_check,
          //         Colors.blue,
          //         () {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text('Certificate review coming soon')),
          //           );
          //         },
          //       ),
          //     ),
          //     const SizedBox(width: 16),
          //     Expanded(
          //       child: _buildActionButton(
          //         'Generate Report',
          //         Icons.assessment,
          //         Colors.green,
          //         () {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text('Report generation coming soon')),
          //           );
          //         },
          //       ),
          //     ),
          //   ],
          // ),
          
          // const SizedBox(height: 16),
          
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildActionButton(
          //         'Manage Categories',
          //         Icons.category,
          //         Colors.purple,
          //         () {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text('Category management coming soon')),
          //           );
          //         },
          //       ),
          //     ),
          //     const SizedBox(width: 16),
          //     Expanded(
          //       child: _buildActionButton(
          //         'Department Settings',
          //         Icons.settings,
          //         Colors.orange,
          //         () {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text('Department settings coming soon')),
          //           );
          //         },
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreIndicator(int score) {
    Color color;
    if (score >= 85) {
      color = Colors.green;
    } else if (score >= 70) {
      color = Colors.blue;
    } else if (score >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        score.toString(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  void _showStaffDetailsDialog(BuildContext context, Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(staff['name']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStaffDetailRow('Registration No', staff['regNo']),
                _buildStaffDetailRow('Email', staff['email']),
                _buildStaffDetailRow('Phone', staff['phone']),
                _buildStaffDetailRow('Certificates', staff['certificateCount'].toString()),
                _buildStaffDetailRow('Average Score', staff['averageScore'].toString()),
                const SizedBox(height: 16),
                const Text(
                  'Actions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Certificates'),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View certificates coming soon')),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.email),
                      label: const Text('Contact'),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contact functionality coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStaffDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
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
}