import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../services/preferences_service.dart';
import '../../services/database_service.dart';
import '../dashboard/dashboard_screen.dart';

/// Complete onboarding flow with 3 screens:
/// 1. Welcome & Personal Information (name, salary, default bills)
/// 2. Important Bills Setup (add custom bills)
/// 3. Completion Screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  
  // Step 1: Personal Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _waterBillController = TextEditingController();
  final TextEditingController _electricityBillController = TextEditingController();
  
  bool _isNameValid = false;
  bool _isSalaryValid = false;
  bool _isWaterBillValid = true;
  bool _isElectricityBillValid = true;
  
  // Step 2: Custom Bills
  final List<CustomBill> _customBills = [];
  
  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _salaryController.addListener(_validateSalary);
    _waterBillController.addListener(_validateWaterBill);
    _electricityBillController.addListener(_validateElectricityBill);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    _waterBillController.dispose();
    _electricityBillController.dispose();
    super.dispose();
  }
  
  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().isNotEmpty;
    });
  }
  
  void _validateSalary() {
    setState(() {
      final salaryText = _salaryController.text.trim();
      _isSalaryValid = salaryText.isNotEmpty && 
          double.tryParse(salaryText) != null && 
          double.tryParse(salaryText)! > 0;
    });
  }
  
  void _validateWaterBill() {
    setState(() {
      final text = _waterBillController.text.trim();
      _isWaterBillValid = text.isEmpty || 
          (double.tryParse(text) != null && double.tryParse(text)! >= 0);
    });
  }
  
  void _validateElectricityBill() {
    setState(() {
      final text = _electricityBillController.text.trim();
      _isElectricityBillValid = text.isEmpty || 
          (double.tryParse(text) != null && double.tryParse(text)! >= 0);
    });
  }
  
  bool get _canProceedFromStep1 {
    return _isNameValid && _isSalaryValid && _isWaterBillValid && _isElectricityBillValid;
  }
  
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }
  
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  Future<void> _completeOnboarding() async {
    // Save user profile
    await PreferencesService.instance.setUserName(_nameController.text.trim());
    
    // Convert salary to minor units (EGP has 2 decimal places)
    final salaryMajor = double.parse(_salaryController.text.trim());
    final salaryMinor = (salaryMajor * 100).round();
    await PreferencesService.instance.setMonthlyIncome(salaryMinor);
    await PreferencesService.instance.setCurrency('EGP');
    
    // Create water bill if amount is provided
    final waterText = _waterBillController.text.trim();
    if (waterText.isNotEmpty) {
      final waterMajor = double.parse(waterText);
      final waterMinor = (waterMajor * 100).round();
      await DatabaseService.instance.createRecurringExpense(
        title: 'فاتورة الماء',
        amountInMinorUnits: waterMinor,
        category: 'utilities',
        iconCode: 'water_drop',
        colorHex: AppTheme.waterBillColor.value.toRadixString(16).padLeft(8, '0'),
        currencyCode: 'EGP',
      );
    }
    
    // Create electricity bill if amount is provided
    final electricityText = _electricityBillController.text.trim();
    if (electricityText.isNotEmpty) {
      final electricityMajor = double.parse(electricityText);
      final electricityMinor = (electricityMajor * 100).round();
      await DatabaseService.instance.createRecurringExpense(
        title: 'فاتورة الكهرباء',
        amountInMinorUnits: electricityMinor,
        category: 'utilities',
        iconCode: 'bolt',
        colorHex: AppTheme.electricityBillColor.value.toRadixString(16).padLeft(8, '0'),
        currencyCode: 'EGP',
      );
    }
    
    // Create custom bills
    for (final bill in _customBills) {
      await DatabaseService.instance.createRecurringExpense(
        title: bill.name,
        amountInMinorUnits: bill.amountMinor,
        category: 'custom',
        iconCode: bill.iconCode,
        colorHex: bill.colorHex,
        currencyCode: 'EGP',
      );
    }
    
    // Mark onboarding as completed
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
            // Language toggle at top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LanguageToggle(),
                ],
              ),
            ),
            
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildWelcomeStep(loc, isArabic),
                  _buildBillsStep(loc, isArabic),
                  _buildCompletionStep(loc, isArabic),
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(loc, isArabic),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeStep(AppLocalizations loc, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          
          // Welcome icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            isArabic 
                ? 'أهلاً وسهلاً بك\nفي برنامج فلوسي!!'
                : 'Welcome to\nFlousi Program!!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            isArabic
                ? 'عايزك تحط كام حاجة هنا علشان ناخد أفضل تجربة\nممكنة وإنت بتستخدم البرنامج'
                : 'We need you to enter a few things here so we can give you\nthe best experience while using the app',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Name field
          _buildTextField(
            label: isArabic ? 'الاسم الكريم' : 'Full Name',
            hint: isArabic ? 'ادخل اسمك الكريم' : 'Enter your name',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            isValid: _isNameValid,
            errorText: !_isNameValid && _nameController.text.isNotEmpty
                ? (isArabic ? 'الاسم مطلوب' : 'Name is required')
                : null,
          ),
          
          const SizedBox(height: 20),
          
          // Salary field
          _buildTextField(
            label: isArabic ? 'الراتب الشهري' : 'Monthly Salary',
            hint: isArabic ? 'مثال: 5000' : 'Example: 5000',
            controller: _salaryController,
            prefixIcon: Icons.attach_money,
            suffixText: 'EGP',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            isValid: _isSalaryValid,
            errorText: !_isSalaryValid && _salaryController.text.isNotEmpty
                ? (isArabic ? 'أدخل مبلغ صحيح أكبر من صفر' : 'Enter a valid amount greater than zero')
                : null,
          ),
          
          const SizedBox(height: 32),
          
          // Default bills section
          Text(
            isArabic ? 'ضع المبلغ لكل شيء في الأسفل' : 'Enter the amount for each item below',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Water Bill Card
          _buildBillCard(
            title: isArabic ? 'فاتورة الماء' : 'Water Bill',
            icon: Icons.water_drop,
            iconColor: AppTheme.waterBillColor,
            controller: _waterBillController,
            isValid: _isWaterBillValid,
          ),
          
          const SizedBox(height: 16),
          
          // Electricity Bill Card
          _buildBillCard(
            title: isArabic ? 'فاتورة الكهرباء' : 'Electricity Bill',
            icon: Icons.bolt,
            iconColor: AppTheme.electricityBillColor,
            controller: _electricityBillController,
            isValid: _isElectricityBillValid,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildBillCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required bool isValid,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? Colors.grey.shade200 : Colors.red.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title and input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00 EGP',
                    suffixText: 'EGP',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillsStep(AppLocalizations loc, bool isArabic) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // Title
                Text(
                  isArabic 
                      ? 'هل عندك فواتير مهمة عايز تحطها؟'
                      : 'Do you have important bills to add?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  isArabic
                      ? 'من المهم إنك تحطها علشان نعرف نحسب الفلوس صح'
                      : 'It\'s important to add them so we can calculate your money correctly',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Add bill button
                _buildAddBillButton(loc, isArabic),
                
                const SizedBox(height: 24),
                
                // Bills list
                if (_customBills.isNotEmpty) ...[
                  Text(
                    isArabic ? 'الفواتير المضافة' : 'Added Bills',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._customBills.map((bill) => _buildCustomBillItem(bill, isArabic)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddBillButton(AppLocalizations loc, bool isArabic) {
    return InkWell(
      onTap: () => _showAddBillDialog(loc, isArabic),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              isArabic ? 'إضافة فاتورة جديدة' : 'Add New Bill',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomBillItem(CustomBill bill, bool isArabic) {
    final color = Color(int.parse(bill.colorHex, radix: 16));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with color
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconData(bill.iconCode),
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Bill info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(bill.amountMinor)} EGP',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editBill(bill),
                tooltip: isArabic ? 'تعديل' : 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _confirmDeleteBill(bill),
                tooltip: isArabic ? 'حذف' : 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showAddBillDialog(AppLocalizations loc, bool isArabic) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedIcon = 'receipt_long';
    String selectedColor = AppTheme.billColors.first.value.toRadixString(16).padLeft(8, '0');
    bool isAmountValid = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'إضافة فاتورة جديدة' : 'Add New Bill',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم الفاتورة' : 'Bill Name',
                    hintText: isArabic ? 'مثال: فاتورة الإنترنت' : 'Example: Internet Bill',
                    prefixIcon: const Icon(Icons.receipt_long),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Amount field
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      isAmountValid = value.isNotEmpty && 
                          double.tryParse(value) != null && 
                          double.tryParse(value)! > 0;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: isArabic ? 'المبلغ' : 'Amount',
                    hintText: '0.00',
                    suffixText: 'EGP',
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Icon picker
                Text(
                  isArabic ? 'اختر أيقونة' : 'Choose Icon',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableIcons.map((iconCode) {
                    final iconData = _getIconData(iconCode);
                    final isSelected = selectedIcon == iconCode;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = iconCode),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          size: 24,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Color picker
                Text(
                  isArabic ? 'اختر لون' : 'Choose Color',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppTheme.billColors.map((color) {
                    final colorHex = color.value.toRadixString(16).padLeft(8, '0');
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = colorHex),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty && isAmountValid) {
                  final amountMajor = double.parse(amountController.text.trim());
                  final amountMinor = (amountMajor * 100).round();
                  
                  setState(() {
                    _customBills.add(CustomBill(
                      name: nameController.text.trim(),
                      amountMinor: amountMinor,
                      iconCode: selectedIcon,
                      colorHex: selectedColor,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(isArabic ? 'إضافة' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _editBill(CustomBill bill) {
    final nameController = TextEditingController(text: bill.name);
    final amountController = TextEditingController(
      text: (bill.amountMinor / 100).toStringAsFixed(2),
    );
    String selectedIcon = bill.iconCode;
    String selectedColor = bill.colorHex;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            Provider.of<AppLocalizations>(context, listen: false).locale.languageCode == 'ar'
                ? 'تعديل الفاتورة'
                : 'Edit Bill',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفاتورة',
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    suffixText: 'EGP',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 24),
                // Icon picker (simplified for edit)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableIcons.map((iconCode) {
                    final isSelected = selectedIcon == iconCode;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = iconCode),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconData(iconCode),
                          size: 20,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Color picker (simplified for edit)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppTheme.billColors.map((color) {
                    final colorHex = color.value.toRadixString(16).padLeft(8, '0');
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = colorHex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final amountMajor = double.tryParse(amountController.text.trim()) ?? 0;
                  final amountMinor = (amountMajor * 100).round();
                  
                  setState(() {
                    final index = _customBills.indexOf(bill);
                    if (index != -1) {
                      _customBills[index] = CustomBill(
                        name: nameController.text.trim(),
                        amountMinor: amountMinor,
                        iconCode: selectedIcon,
                        colorHex: selectedColor,
                      );
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDeleteBill(CustomBill bill) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic ? 'هل أنت متأكد إنك عايز تحذف الفاتورة؟' : 'Are you sure you want to delete this bill?',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _customBills.remove(bill);
              });
              Navigator.pop(context);
            },
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionStep(AppLocalizations loc, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Success animation/icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 120,
              color: AppTheme.successGreen,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title
          Text(
            isArabic ? 'مبروك!' : 'Congratulations!',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            isArabic 
                ? 'كدا خلصت كل حاجة.... إستمتع ببرنامج فلوسي'
                : 'You\'re all set.... Enjoy Flousi Program',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Launch button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 4,
                shadowColor: AppTheme.successGreen.withOpacity(0.3),
              ),
              onPressed: _completeOnboarding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isArabic ? 'إنطلاق' : 'Launch',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isArabic ? Icons.arrow_forward : Icons.arrow_back,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons(AppLocalizations loc, bool isArabic) {
    if (_currentStep == 2) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _prevStep,
              child: Text(
                isArabic ? 'السابق' : 'Back',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            )
          else
            const SizedBox.shrink(),
          
          ElevatedButton.icon(
            onPressed: _currentStep == 0 
                ? (_canProceedFromStep1 ? _nextStep : null)
                : _nextStep,
            icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
            label: Text(
              _currentStep == 0 
                  ? (isArabic ? 'التالي' : 'Next')
                  : (isArabic ? 'التالي' : 'Next'),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool isValid = true,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            prefixIcon: Icon(prefixIcon),
            errorText: errorText,
            filled: true,
            fillColor: isValid ? Colors.grey.shade50 : Colors.red.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? Colors.grey.shade200 : Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.red,
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
      ],
    );
  }
  
  IconData _getIconData(String iconCode) {
    switch (iconCode) {
      case 'water_drop': return Icons.water_drop;
      case 'bolt': return Icons.bolt;
      case 'wifi': return Icons.wifi;
      case 'phone': return Icons.phone;
      case 'car': return Icons.car_rental;
      case 'home': return Icons.home;
      case 'school': return Icons.school;
      case 'medical': return Icons.medical_services;
      case 'shopping': return Icons.shopping_cart;
      case 'food': return Icons.restaurant;
      case 'subscription': return Icons.subscriptions;
      case 'insurance': return Icons.security;
      case 'transport': return Icons.directions_bus;
      case 'gas': return Icons.local_gas_station;
      case 'internet': return Icons.router;
      case 'entertainment': return Icons.movie;
      default: return Icons.receipt_long;
    }
  }
  
  String _formatAmount(int amountMinor) {
    return (amountMinor / 100).toStringAsFixed(2);
  }
  
  static const List<String> _availableIcons = [
    'receipt_long',
    'water_drop',
    'bolt',
    'wifi',
    'phone',
    'car',
    'home',
    'school',
    'medical_services',
    'shopping_cart',
    'restaurant',
    'subscriptions',
    'security',
    'directions_bus',
    'local_gas_station',
    'router',
    'movie',
  ];
}

// Custom Bill data class
class CustomBill {
  final String name;
  final int amountMinor;
  final String iconCode;
  final String colorHex;
  
  CustomBill({
    required this.name,
    required this.amountMinor,
    required this.iconCode,
    required this.colorHex,
  });
}

// Language toggle widget
class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageButton(
            flag: '🇪🇬',
            label: 'عربي',
            isSelected: isArabic,
            onTap: () {
              localeProvider.setLocale(const Locale('ar'));
              PreferencesService.instance.setLanguage('ar');
            },
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          _LanguageButton(
            flag: '🇬🇧',
            label: 'English',
            isSelected: !isArabic,
            onTap: () {
              localeProvider.setLocale(const Locale('en'));
              PreferencesService.instance.setLanguage('en');
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
