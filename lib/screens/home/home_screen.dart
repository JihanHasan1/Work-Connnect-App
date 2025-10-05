import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import '../chat/team_chat_list_screen.dart';
import '../faq/faq_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../admin/admin_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tabCount = auth.isAdmin ? 5 : 4;
    _tabController = TabController(length: tabCount, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final List<Widget> screens = [
      const DashboardScreen(),
      const TeamChatListScreen(),
      const FAQScreen(),
      const ChatbotScreen(),
      if (auth.isAdmin) const AdminPanelScreen(),
    ];

    return DefaultTabController(
      length: screens.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Work-Connect',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (value) async {
                if (value == 'profile') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile page coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (value == 'settings') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings page coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (value == 'logout') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await auth.signOut();
                  }
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  enabled: false,
                  value: 'profile_header',
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        (auth.currentUser?.username ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      auth.currentUser?.displayName ??
                          auth.currentUser?.username ??
                          'User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      auth.currentUser?.role
                              ?.replaceAll('_', ' ')
                              .toUpperCase() ??
                          'Role',
                      style: const TextStyle(fontSize: 12),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person, color: Color(0xFF6366F1)),
                    title: Text('Profile'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings, color: Color(0xFF64748B)),
                    title: Text('Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title:
                        Text('Sign Out', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              _tabController.animateTo(index);
            });
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: 'Teams',
            ),
            const NavigationDestination(
              icon: Icon(Icons.help_outline),
              selectedIcon: Icon(Icons.help),
              label: 'FAQ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: 'Assistant',
            ),
            if (auth.isAdmin)
              const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings),
                label: 'Admin',
              ),
          ],
        ),
      ),
    );
  }
}
