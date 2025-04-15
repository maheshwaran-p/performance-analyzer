import 'package:flutter/material.dart';
import 'package:performance_analzer2/screens/activity_uploader.dart';
import 'package:performance_analzer2/screens/hod_dashboard.dart';
import 'package:performance_analzer2/screens/performance_screen.dart';
import 'package:performance_analzer2/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

import '../widgets/upload_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isHod = userProvider.currentUser?.isHod ?? false;
    
    // Define screens based on user role
    final List<Widget> _screens = [
      const UploadWidget(),
      const AcademicActivitiesScreen(),
      const PerformanceScreen(),
      const ProfileScreen(),
      if (isHod) const HodDashboardScreen(),
    ];

    final List<BottomNavigationBarItem> _navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.upload_file),
        label: 'Certificates',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.school),
        label: 'Activities',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.analytics),
        label: 'Performance',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
      if (isHod)
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_getScreenTitle(_selectedIndex, isHod)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context, isHod);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: _navigationItems,
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  String _getScreenTitle(int index, bool isHod) {
    switch (index) {
      case 0:
        return 'Certificates';
      case 1:
        return 'Academic Activities';
      case 2:
        return 'Performance';
      case 3:
        return 'Profile';
      case 4:
        return isHod ? 'HOD Dashboard' : 'Certificate Analyzer';
      default:
        return 'Certificate Analyzer';
    }
  }

  void _showHelpDialog(BuildContext context, bool isHod) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How To Use This App'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpSection(
                  'Certificates Tab',
                  [
                    'Upload and analyze your certificates',
                    'Get validation scores and recommendations',
                    'Submit verified certificates to your profile',
                  ],
                ),
                const SizedBox(height: 10),
                _buildHelpSection(
                  'Activities Tab',
                  [
                    'Add research projects, publications, lectures',
                    'Upload supporting documents for verification',
                    'Track all your academic activities in one place',
                  ],
                ),
                const SizedBox(height: 10),
                _buildHelpSection(
                  'Performance Tab',
                  [
                    'View your overall performance metrics',
                    'Track progress across different categories',
                    'Get personalized improvement suggestions',
                  ],
                ),
                const SizedBox(height: 10),
                _buildHelpSection(
                  'Profile Tab',
                  [
                    'View personal information and statistics',
                    'See your validated certificates and activities',
                    'Manage your account settings',
                  ],
                ),
                if (isHod) ...[
                  const SizedBox(height: 10),
                  _buildHelpSection(
                    'Dashboard Tab (HOD Only)',
                    [
                      'Overview of department statistics',
                      'View staff performance metrics',
                      'Manage department settings and approvals',
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got It'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(point)),
                ],
              ),
            )),
      ],
    );
  }
}