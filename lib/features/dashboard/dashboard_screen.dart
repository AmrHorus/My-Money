import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const Center(child: Text('Expenses')),
    const Center(child: Text('Budget')),
    const Center(child: Text('Statistics')),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: loc.tr('home'),
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: loc.tr('settings'),
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('app_name'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      loc.tr('tagline'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      ),
                      onPressed: () {
                        if (themeProvider.isDarkMode) {
                          themeProvider.setThemeMode(ThemeMode.light);
                        } else if (themeProvider.isLightMode) {
                          themeProvider.setThemeMode(ThemeMode.dark);
                        } else {
                          themeProvider.setThemeMode(ThemeMode.dark);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('remaining'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2,350 SAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceInfo(
                          context,
                          Icons.arrow_upward,
                          loc.tr('income'),
                          '10,000',
                        ),
                      ),
                      Expanded(
                        child: _buildBalanceInfo(
                          context,
                          Icons.arrow_downward,
                          loc.tr('obligations'),
                          '4,150',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  context,
                  Icons.repeat,
                  loc.tr('recurring_expenses'),
                  '4,150 SAR',
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  Icons.shopping_cart,
                  loc.tr('variable_expenses'),
                  '1,500 SAR',
                  Colors.red,
                ),
                _buildStatCard(
                  context,
                  Icons.savings,
                  loc.tr('savings'),
                  '2,000 SAR',
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  Icons.calendar_today,
                  loc.tr('upcoming_payments'),
                  '3',
                  Colors.blue,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Expenses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.tr('recent_expenses'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(isArabic ? 'عرض الكل' : 'View All'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Sample expense list
            _buildExpenseItem(
              context,
              '🏠',
              loc.tr('housing'),
              '2,500 SAR',
              DateTime.now().subtract(const Duration(days: 1)),
            ),
            _buildExpenseItem(
              context,
              '💡',
              loc.tr('electricity'),
              '300 SAR',
              DateTime.now().subtract(const Duration(days: 2)),
            ),
            _buildExpenseItem(
              context,
              '📶',
              loc.tr('internet'),
              '250 SAR',
              DateTime.now().subtract(const Duration(days: 3)),
            ),
            
            const SizedBox(height: 100), // Space for FAB and bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(BuildContext context, IconData icon, String label, String amount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, String emoji, String title, String amount, DateTime date) {
    final isArabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        subtitle: Text(
          '${date.day}/${date.month}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            loc.tr('settings'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(loc.tr('theme'), style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: DropdownButton<ThemeMode>(
                    value: Provider.of<ThemeProvider>(context).themeMode,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: ThemeMode.system, child: Text(loc.tr('system_mode'))),
                      DropdownMenuItem(value: ThemeMode.light, child: Text(loc.tr('light_mode'))),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text(loc.tr('dark_mode'))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        Provider.of<ThemeProvider>(context, listen: false).setThemeMode(value);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(loc.tr('language'), style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: DropdownButton<String>(
                    value: loc.locale.languageCode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(value));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(loc.tr('export_data'), style: const TextStyle(fontFamily: 'Cairo')),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(loc.tr('privacy'), style: const TextStyle(fontFamily: 'Cairo')),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(loc.tr('about'), style: const TextStyle(fontFamily: 'Cairo')),
                  trailing: Text('v1.0.0', style: TextStyle(color: Colors.grey.shade600)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
