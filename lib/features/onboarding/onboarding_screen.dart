import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../services/preferences_service.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  String _selectedCurrency = 'SAR';
  final TextEditingController _incomeController = TextEditingController();
  bool _hasRecurringExpenses = false;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.account_balance_wallet,
      'title_ar': 'مرحباً بك في فلوسي',
      'title_en': 'Welcome to Flousi',
      'subtitle_ar': 'نظم مصاريفك الشهرية بسهولة',
      'subtitle_en': 'Organize your monthly expenses easily',
    },
    {
      'icon': Icons.attach_money,
      'title_ar': 'تحكم في مصاريفك',
      'title_en': 'Control Your Expenses',
      'subtitle_ar': 'اعرف بالضبط куда تذهب أموالك كل شهر',
      'subtitle_en': 'Know exactly where your money goes each month',
    },
    {
      'icon': Icons.savings,
      'title_ar': 'وفر لمستقبلك',
      'title_en': 'Save for Your Future',
      'subtitle_ar': 'حدد أهداف ادخار وحققها',
      'subtitle_en': 'Set savings goals and achieve them',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Save preferences
    await PreferencesService.instance.setCurrency(_selectedCurrency);
    
    final incomeInMinorUnits = (double.tryParse(_incomeController.text) ?? 0) * 100;
    await PreferencesService.instance.setMonthlyIncome(incomeInMinorUnits.toInt());
    
    await PreferencesService.instance.setOnboarded(true);
    await PreferencesService.instance.setFirstLaunchDate();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page['icon'] as IconData,
                          size: 120,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 48),
                        Text(
                          isArabic ? page['title_ar'] as String : page['title_en'] as String,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isArabic ? page['subtitle_ar'] as String : page['subtitle_en'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () => _completeOnboarding(),
                      child: Text(isArabic ? 'تخطي' : 'Skip'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _showSetupDialog();
                      }
                    },
                    icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
                    label: Text(isArabic 
                        ? (_currentPage < _pages.length - 1 ? 'التالي' : 'ابدأ')
                        : (_currentPage < _pages.length - 1 ? 'Next' : 'Start')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SetupDialog(
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (currency) => setState(() => _selectedCurrency = currency),
        incomeController: _incomeController,
        hasRecurringExpenses: _hasRecurringExpenses,
        onHasRecurringChanged: (value) => setState(() => _hasRecurringExpenses = value),
        onComplete: _completeOnboarding,
      ),
    );
  }
}

class _SetupDialog extends StatelessWidget {
  final String selectedCurrency;
  final Function(String) onCurrencySelected;
  final TextEditingController incomeController;
  final bool hasRecurringExpenses;
  final Function(bool) onHasRecurringChanged;
  final VoidCallback onComplete;

  const _SetupDialog({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.incomeController,
    required this.hasRecurringExpenses,
    required this.onHasRecurringChanged,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'إعداد حسابك' : 'Setup Your Account',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 24),
            
            // Currency selection
            Text(
              isArabic ? 'ما هي عملتك؟' : "What's your currency?",
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['SAR', 'EGP', 'USD', 'EUR', 'GBP', 'AED', 'KWD'].map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) => onCurrencySelected(value!),
            ),
            
            const SizedBox(height: 16),
            
            // Income input
            Text(
              isArabic ? 'كم مرتبك الشهري؟' : "What's your monthly income?",
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: isArabic ? 'مثال: 10000' : 'Example: 10000',
                suffixText: selectedCurrency,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recurring expenses
            CheckboxListTile(
              value: hasRecurringExpenses,
              onChanged: (value) => onHasRecurringChanged(value ?? false),
              title: Text(
                isArabic ? 'هل لديك مصاريف شهرية ثابتة؟' : 'Do you have recurring monthly expenses?',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onComplete,
                child: Text(isArabic ? 'إنهاء' : 'Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
