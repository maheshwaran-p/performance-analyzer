import 'package:flutter/material.dart';
import 'package:performance_analzer2/models/perf.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import 'dart:math' as math;

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPerformanceData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPerformanceData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final performanceProvider = Provider.of<PerformanceProvider>(context, listen: false);
    
    try {
      if (userProvider.isLoggedIn && userProvider.currentUser != null) {
        await performanceProvider.fetchPerformanceData(userProvider.currentUser!.email);
      }
    } catch (e) {
      print('Error loading performance data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PerformanceProvider>(
      builder: (context, performanceProvider, child) {
        if (_isLoading || performanceProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading performance data...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        if (performanceProvider.error.isNotEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading performance data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    performanceProvider.error,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadPerformanceData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final performanceData = performanceProvider.performanceData;
        if (performanceData == null) {
          return const Scaffold(
            body: Center(
              child: Text('No performance data available'),
            ),
          );
        }

        // Extract performance data
        final overallScore = performanceData.overallScore;
        final categoryScores = performanceData.categoryScores;
        final achievements = performanceData.recentAchievements;
        final suggestions = performanceData.suggestions;
        final activityCounts = performanceData.activityCounts;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 220,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      innerBoxIsScrolled ? 'Academic Performance' : '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    background: _buildPerformanceHeader(context, overallScore, activityCounts),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
tabs: const [
  Tab(
    child: Text(
      'Overview',
      style: TextStyle(color: Colors.white),
    ),
  ),
  Tab(
    child: Text(
      'Research',
      style: TextStyle(color: Colors.white),
    ),
  ),
  Tab(
    child: Text(
      'Publications',
      style: TextStyle(color: Colors.white),
    ),
  ),
  Tab(
    child: Text(
      'Guest Lectures',
      style: TextStyle(color: Colors.white),
    ),
  ),
  Tab(
    child: Text(
      'Self Development',
      style: TextStyle(color: Colors.white),
    ),
  ),
],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                RefreshIndicator(
                  onRefresh: _loadPerformanceData,
                  child: _buildOverviewTab(context, performanceProvider, performanceData),
                ),
                
                // Research Tab
                _buildActivityTab(
                  context, 
                  'Research', 
                  'You have ${activityCounts.research} research projects',
                  Icons.science,
                  Colors.purple,
                  performanceProvider,
                  hasRecentActivity: achievements.any((a) => a.type == 'Research'),
                  recentActivities: achievements.where((a) => a.type == 'Research').toList(),
                ),
                
                // Publications Tab
                _buildActivityTab(
                  context, 
                  'Publications', 
                  'You have ${activityCounts.publications} publications',
                  Icons.article,
                  Colors.indigo,
                  performanceProvider,
                  hasRecentActivity: achievements.any((a) => a.type == 'Publication'),
                  recentActivities: achievements.where((a) => a.type == 'Publication').toList(),
                ),
                
                // Guest Lectures Tab
                _buildActivityTab(
                  context, 
                  'Guest Lectures', 
                  'You have ${activityCounts.guestLectures} guest lectures',
                  Icons.record_voice_over,
                  Colors.orange,
                  performanceProvider,
                  hasRecentActivity: achievements.any((a) => a.type == 'Lecture'),
                  recentActivities: achievements.where((a) => a.type == 'Lecture').toList(),
                ),
                
                // Self Development Tab
                _buildSelfDevelopmentTab(
                  context, 
                  activityCounts.selfDevelopment, 
                  performanceProvider,
                  recentActivities: achievements.where((a) => a.type == 'Self Development').toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceHeader(BuildContext context, int overallScore, ActivityCounts counts) {
    String performanceLabel = _getPerformanceLabel(overallScore);
    Color performanceColor = _getPerformanceColor(overallScore);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
SizedBox(
  width: 100,
  height: 100,
  child: Stack(
    alignment: Alignment.center,
    children: [
      // Outer progress ring
      SizedBox(
        width: 100,
        height: 100,
        child: CircularProgressIndicator(
          value: overallScore / 100,
          strokeWidth: 8,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      
      // Inner background circle
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$overallScore',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'points',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          performanceLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: performanceColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Based on ${counts.total} activities',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Last updated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, PerformanceProvider provider, PerformanceData data) {
    final categoryScores = data.categoryScores;
    final achievements = data.recentAchievements;
    final suggestions = data.suggestions;
    final activityCounts = data.activityCounts;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity breakdown
          _buildSectionHeader('Activity Breakdown', Icons.pie_chart),
          const SizedBox(height: 12),
          _buildActivityBreakdownCard(context, activityCounts),
          
          const SizedBox(height: 24),
          
          // Category performance
          _buildSectionHeader('Performance by Category', Icons.score),
          const SizedBox(height: 12),
          _buildCategoryGrid(context, categoryScores, provider),
          
          const SizedBox(height: 24),
          
          // Recent achievements
          _buildSectionHeader('Recent Achievements', Icons.emoji_events),
          const SizedBox(height: 12),
          // _buildAchievementsCard(context, achievements, provider),
          
          const SizedBox(height: 24),
          
          // Improvement suggestions
          _buildSectionHeader('Improvement Suggestions', Icons.lightbulb_outline),
          const SizedBox(height: 12),
          _buildSuggestionsCard(context, suggestions, provider),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActivityTab(
    BuildContext context, 
    String title, 
    String subtitle, 
    IconData icon, 
    Color color,
    PerformanceProvider provider,
    {required bool hasRecentActivity, required List<Achievement> recentActivities}
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          _buildActivityHeader(title, subtitle, icon, color),
          
          const SizedBox(height: 24),
          
          // If there are recent activities, show them
          if (hasRecentActivity) ...[
            _buildSectionHeader('Your Recent $title', Icons.access_time),
            const SizedBox(height: 12),
            ...recentActivities.map((activity) => 
              _buildAchievementItem(context, activity, provider)
            ).toList(),
          ],
          
          const SizedBox(height: 24),
          
          // Add new activity button
          // InkWell(
          //   onTap: () {
          //     // This would navigate to the ActivityScreen with the correct tab selected
          //     // Navigator.of(context).push(
          //     //   MaterialPageRoute(
          //     //     builder: (_) => AcademicActivitiesScreen(initialTab: _getTabIndex(title)),
          //     //   ),
          //     // );
          //   },
          //   child: Container(
          //     padding: const EdgeInsets.all(16),
          //     decoration: BoxDecoration(
          //       color: color.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: color.withOpacity(0.3)),
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(Icons.add_circle, color: color),
          //         const SizedBox(width: 10),
          //         Text(
          //           'Add New $title',
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             color: color,
          //             fontSize: 16,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          
          // If no recent activities, show empty state
          // if (!hasRecentActivity) ...[
          //   const SizedBox(height: 40),
          //   Center(
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(
          //           Icons.hourglass_empty,
          //           size: 48,
          //           color: Colors.grey.shade400,
          //         ),
          //         const SizedBox(height: 16),
          //         Text(
          //           'No $title Yet',
          //           style: TextStyle(
          //             fontSize: 18,
          //             fontWeight: FontWeight.bold,
          //             color: Colors.grey.shade700,
          //           ),
          //         ),
          //         const SizedBox(height: 8),
          //         Text(
          //           'Add your first $title to improve your score',
          //           style: TextStyle(
          //             fontSize: 14,
          //             color: Colors.grey.shade600,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildSelfDevelopmentTab(
    BuildContext context, 
    int count, 
    PerformanceProvider provider,
    {required List<Achievement> recentActivities}
  ) {
    final hasRecentActivity = recentActivities.isNotEmpty;
    
    // Define self development categories
    final List<Map<String, dynamic>> categories = [
      {"name": "Courses", "icon": Icons.school, "color": Colors.blue},
      {"name": "Workshops", "icon": Icons.build, "color": Colors.orange},
      {"name": "Certifications", "icon": Icons.verified, "color": Colors.green},
      {"name": "Training", "icon": Icons.fitness_center, "color": Colors.red},
      {"name": "Conferences", "icon": Icons.people, "color": Colors.purple},
      {"name": "Seminars", "icon": Icons.event_note, "color": Colors.teal},
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          _buildActivityHeader('Self Development', 'You have $count self development activities', Icons.trending_up, Colors.green),
          
          const SizedBox(height: 24),
          
          // Categories grid
          _buildSectionHeader('Activity Types', Icons.category),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: categories.map((category) {
              return _buildSelfDevCategory(context, category);
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // If there are recent activities, show them
          if (hasRecentActivity) ...[
            _buildSectionHeader('Your Recent Activities', Icons.access_time),
            const SizedBox(height: 12),
            ...recentActivities.map((activity) => 
              _buildAchievementItem(context, activity, provider)
            ).toList(),
          ],
          
          const SizedBox(height: 24),
          
          // Add new activity button
          // InkWell(
          //   onTap: () {
          //     // Navigate to self development tab in academic activities
          //     // Navigator.of(context).push(
          //     //   MaterialPageRoute(
          //     //     builder: (_) => AcademicActivitiesScreen(initialTab: 3),
          //     //   ),
          //     // );
          //   },
          //   child: Container(
          //     padding: const EdgeInsets.all(16),
          //     decoration: BoxDecoration(
          //       color: Colors.green.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: Colors.green.withOpacity(0.3)),
          //     ),
          //     child: const Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(Icons.add_circle, color: Colors.green),
          //         SizedBox(width: 10),
          //         Text(
          //           'Add New Self Development',
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             color: Colors.green,
          //             fontSize: 16,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          
          // If no recent activities, show empty state
          if (!hasRecentActivity) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Self Development Activities Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first self development activity to improve your score',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelfDevCategory(BuildContext context, Map<String, dynamic> category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // This would navigate to add a specific type of self development
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category["color"].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category["icon"],
                  color: category["color"],
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category["name"],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHeader(String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade800,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityBreakdownCard(BuildContext context, ActivityCounts counts) {
    final total = counts.total > 0 ? counts.total : 1; // Avoid division by zero
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildActivityProgressBar(
              context,
              'Certificates',
              counts.certificates,
              total,
              Colors.blue,
              Icons.verified,
            ),
            const SizedBox(height: 16),
            _buildActivityProgressBar(
              context,
              'Research',
              counts.research,
              total,
              Colors.purple,
              Icons.science,
            ),
            const SizedBox(height: 16),
            _buildActivityProgressBar(
              context,
              'Publications',
              counts.publications,
              total,
              Colors.indigo,
              Icons.article,
            ),
            const SizedBox(height: 16),
            _buildActivityProgressBar(
              context,
              'Guest Lectures',
              counts.guestLectures,
              total,
              Colors.orange,
              Icons.record_voice_over,
            ),
            const SizedBox(height: 16),
            _buildActivityProgressBar(
              context,
              'Self Development',
              counts.selfDevelopment,
              total,
              Colors.green,
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityProgressBar(
    BuildContext context,
    String title,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = count / total;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: MediaQuery.of(context).size.width * 0.7 * percentage,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, Map<String, int> categories, PerformanceProvider provider) {
    // Sort categories by score (highest first)
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final category = entry.key;
        final score = entry.value;
        final color = provider.getCategoryColor(category);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 85,
                  height: 85,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreLabel(score),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Complete the missing methods for PerformanceScreen

// Method to build achievement items
Widget _buildAchievementItem(BuildContext context, Achievement achievement, PerformanceProvider provider) {
  final IconData icon = provider.getIconForName(achievement.icon);
  final Color color = _getColorForAchievementType(achievement.type);
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(achievement.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Method to format ISO date string to a readable format
String _formatDate(String dateString) {
  try {
    final DateTime date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy').format(date);
  } catch (e) {
    return dateString;
  }
}

// Method to build suggestions card
Widget _buildSuggestionsCard(BuildContext context, List<Suggestion> suggestions, PerformanceProvider provider) {
  if (suggestions.isEmpty) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Suggestions Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re doing great! Keep up the good work',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              suggestion.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        suggestion.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}

// Helper method to get performance label based on score
String _getPerformanceLabel(int score) {
  if (score >= 90) return 'Exceptional';
  if (score >= 80) return 'Excellent';
  if (score >= 70) return 'Very Good';
  if (score >= 60) return 'Good';
  if (score >= 50) return 'Average';
  return 'Needs Improvement';
}

// Helper method to get performance color based on score
Color _getPerformanceColor(int score) {
  if (score >= 90) return Colors.green;
  if (score >= 80) return Colors.lightGreen;
  if (score >= 70) return Colors.amber;
  if (score >= 60) return Colors.orange;
  if (score >= 50) return Colors.deepOrange;
  return Colors.red;
}

// Helper method to get score label based on score
String _getScoreLabel(int score) {
  if (score >= 90) return 'Exceptional';
  if (score >= 80) return 'Excellent';
  if (score >= 70) return 'Very Good';
  if (score >= 60) return 'Good';
  if (score >= 50) return 'Average';
  return 'Needs Improvement';
}

// Helper method to get color for achievement type
Color _getColorForAchievementType(String type) {
  switch (type) {
    case 'Research':
      return Colors.purple;
    case 'Publication':
      return Colors.indigo;
    case 'Lecture':
      return Colors.orange;
    case 'Self Development':
      return Colors.green;
    default:
      return Colors.blue;
  }
}

}