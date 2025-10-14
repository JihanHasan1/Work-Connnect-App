import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const DashboardScreen({Key? key, required this.onNavigateToTab})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.currentUser?.displayName ??
                      auth.currentUser?.username ??
                      'User',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    auth.currentUser?.role
                            ?.toUpperCase()
                            .replaceAll('_', ' ') ??
                        '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _QuickActionCard(
                icon: FontAwesomeIcons.users,
                title: 'Team Chat',
                subtitle: 'Communicate',
                color: const Color(0xFF1E293B),
                onTap: () {
                  debugPrint(
                      '🔄 Team Chat card tapped - navigating to index 1');
                  onNavigateToTab(1); // Navigate to Teams tab
                },
              ),
              _QuickActionCard(
                icon: FontAwesomeIcons.circleQuestion,
                title: 'FAQs',
                subtitle: 'Find Answers',
                color: const Color(0xFF475569),
                onTap: () {
                  debugPrint('🔄 FAQs card tapped - navigating to index 2');
                  onNavigateToTab(2); // Navigate to FAQ tab
                },
              ),
              _QuickActionCard(
                icon: FontAwesomeIcons.robot,
                title: 'ChatBot',
                subtitle: 'Get Help',
                color: const Color(0xFF10B981),
                onTap: () {
                  debugPrint('🔄 ChatBot card tapped - navigating to index 3');
                  onNavigateToTab(3); // Navigate to chatbot tab
                },
              ),
              if (auth.isAdmin)
                _QuickActionCard(
                  icon: FontAwesomeIcons.userGear,
                  title: 'Admin',
                  subtitle: 'Manage',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    debugPrint('🔄 Admin card tapped - navigating to index 4');
                    onNavigateToTab(4); // Navigate to admin tab
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          _ActivityCard(
            icon: Icons.chat_bubble_outline,
            title: 'New message in Team Chat',
            time: '5 minutes ago',
            color: Color(0xFF1E293B),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            icon: Icons.help_outline,
            title: 'FAQ updated: Company Policies',
            time: '1 hour ago',
            color: Color(0xFF475569),
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            icon: Icons.check_circle_outline,
            title: 'Issue resolved by Team Leader',
            time: '2 hours ago',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          debugPrint('🎯 Card tapped: $title');
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color color;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
