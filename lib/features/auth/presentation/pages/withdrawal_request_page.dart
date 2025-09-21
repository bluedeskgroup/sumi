import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sumi/features/auth/services/referral_service.dart';

class WithdrawalRequestPage extends StatefulWidget {
  const WithdrawalRequestPage({super.key});

  @override
  State<WithdrawalRequestPage> createState() => _WithdrawalRequestPageState();
}

class _WithdrawalRequestPageState extends State<WithdrawalRequestPage> {
  final ReferralService _referralService = ReferralService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  
  bool _isLoading = false;
  double _currentBalance = 0.0;
  double _minAmount = 100.0; // Will be loaded from settings
  List<String> _savedAccountNumbers = [];
  String? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadUserBalance();
    _loadSavedAccounts();
    _listenToSettings();
    _testSettings(); // Test settings loading
    // Keep amount field empty as requested
  }

  Future<void> _testSettings() async {
    print('=== Testing Settings ===');
    try {
      final settings = await _referralService.getReferralSettings();
      print('Test: Settings loaded = $settings');
      final minWithdrawal = settings['minimumWithdrawal'];
      print('Test: minimumWithdrawal = $minWithdrawal (type: ${minWithdrawal.runtimeType})');
    } catch (e) {
      print('Test: Error loading settings = $e');
    }
    print('=== End Test ===');
  }

  Future<void> _loadUserBalance() async {
    try {
      await _referralService.initializeUserReferral();
      // Listen to referral stats stream for current balance
      _referralService.getReferralStatsStream().listen((stats) {
        if (mounted) {
          setState(() {
            _currentBalance = stats.currentBalance;
          });
        }
      });
    } catch (e) {
      print('Error loading balance: $e');
      // Fallback to a default balance
      setState(() {
        _currentBalance = 5000.0;
      });
    }
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final accounts = await _referralService.getSavedAccountNumbers();
      setState(() {
        _savedAccountNumbers = accounts;
        if (accounts.isNotEmpty) {
          _selectedAccount = accounts.first;
          _accountController.text = accounts.first;
        }
      });
    } catch (e) {
      print('Error loading saved accounts: $e');
    }
  }

  void _listenToSettings() {
    print('Starting to listen to settings stream...');
    _referralService.getReferralSettingsStream().listen((settings) {
      if (mounted) {
        final newMinAmount = (settings['minimumWithdrawal'] ?? 100.0).toDouble();
        print('Settings stream update: minimumWithdrawal = $newMinAmount');
        
        setState(() {
          _minAmount = newMinAmount;
        });
        print('Updated _minAmount to: $_minAmount');
      }
    }).onError((error) {
      print('Error in settings stream: $error');
      if (mounted) {
        setState(() {
          _minAmount = 100.0; // Fallback default
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isRtl),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Money Icon
                    _buildMoneyIcon(),
                    
                    const SizedBox(height: 32),
                    
                    // Form Content
                    _buildFormContent(isRtl),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isRtl) {
    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                  size: 18,
                  color: const Color(0xFF323F49),
                ),
              ),
            ),
            
            // Title
            Expanded(
              child: Text(
                isRtl ? 'طلب سحب رصيد' : 'Withdrawal Request',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1D2035),
                  height: 1.39,
                ),
              ),
            ),
            
            // Filter Button (placeholder)
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE7EBEF)),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                size: 12,
                color: Color(0xFF323F49),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyIcon() {
    return Container(
      width: 103,
      height: 103,
      child: Icon(
        Icons.account_balance_wallet,
        size: 60,
        color: const Color(0xFFCED7DE),
      ),
    );
  }

  Widget _buildFormContent(bool isRtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount Section
        _buildAmountSection(isRtl),
        
        const SizedBox(height: 32),
        
        // Submit Button
        _buildSubmitButton(isRtl),
      ],
    );
  }

  Widget _buildAmountSection(bool isRtl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          isRtl ? 'قيمة السحب' : 'Withdrawal Amount',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1D2035),
            height: 1.5,
          ),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        
        const SizedBox(height: 15),
        
        // Amount Input
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFF1D2035),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: isRtl ? 'أدخل قيمة السحب' : 'Enter withdrawal amount',
                      hintStyle: TextStyle(
                        color: const Color(0xFFCED7DE),
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: _formatAmountInput,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: const Color(0xFF4A5E6D),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 14),
        
        // Info Text with StreamBuilder for real-time updates
        StreamBuilder<Map<String, dynamic>>(
          stream: _referralService.getReferralSettingsStream(),
          builder: (context, settingsSnapshot) {
            final settings = settingsSnapshot.data ?? {'minimumWithdrawal': 100.0};
            final minAmount = (settings['minimumWithdrawal'] ?? 100.0).toDouble();
            
            return Container(
              width: double.infinity,
              child: Text(
                isRtl 
                    ? 'الحد الأدنى لسحب الرصيد للمرة الواحدة ${minAmount.toInt()} ريال سعودي'
                    : 'Minimum withdrawal amount per transaction: ${minAmount.toInt()} SAR',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: Color(0xFFAAB9C5),
                  height: 1.6,
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
            );
          },
        ),
        
        const SizedBox(height: 14),
        
        // Account Input - Smart Selection
        _buildAccountInput(isRtl),
      ],
    );
  }

  Widget _buildAccountInput(bool isRtl) {
    if (_savedAccountNumbers.isEmpty) {
      // New user - show empty text field
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE7EBEF)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(
                Icons.account_balance,
                size: 20,
                color: const Color(0xFF9A46D7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _accountController,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF1D2035),
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: isRtl 
                        ? 'أدخل رقم حسابك البنكي'
                        : 'Enter your bank account number',
                    hintStyle: TextStyle(
                      color: const Color(0xFFCED7DE),
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Existing user - show dropdown + option to add new
      return Column(
        children: [
          // Dropdown for saved accounts
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE7EBEF)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: const Color(0xFF9A46D7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedAccount,
                      isExpanded: true,
                      underline: Container(),
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFF1D2035),
                        height: 1.5,
                      ),
                      hint: Text(
                        isRtl ? 'اختر رقم الحساب' : 'Select account number',
                        style: TextStyle(
                          color: const Color(0xFFCED7DE),
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      items: [
                        ..._savedAccountNumbers.map((account) => DropdownMenuItem<String>(
                          value: account,
                          child: Text(
                            account,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          ),
                        )),
                        DropdownMenuItem<String>(
                          value: 'new_account',
                          child: Text(
                            isRtl ? '+ إضافة حساب جديد' : '+ Add new account',
                            style: const TextStyle(
                              color: Color(0xFF9A46D7),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'new_account') {
                          _showAddAccountDialog(isRtl);
                        } else {
                          setState(() {
                            _selectedAccount = value;
                            _accountController.text = value ?? '';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  void _showAddAccountDialog(bool isRtl) {
    final newAccountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRtl ? 'إضافة حساب جديد' : 'Add New Account',
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        content: TextField(
          controller: newAccountController,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            hintText: isRtl ? 'أدخل رقم الحساب الجديد' : 'Enter new account number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAccount = newAccountController.text.trim();
              if (newAccount.isNotEmpty) {
                setState(() {
                  if (!_savedAccountNumbers.contains(newAccount)) {
                    _savedAccountNumbers.add(newAccount);
                  }
                  _selectedAccount = newAccount;
                  _accountController.text = newAccount;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A46D7),
              foregroundColor: Colors.white,
            ),
            child: Text(isRtl ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isRtl) {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitWithdrawalRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9A46D7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: const Color(0xFFE7EBEF),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isRtl ? 'طلب سحب' : 'Request Withdrawal',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.39,
                ),
              ),
      ),
    );
  }



  void _formatAmountInput(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanValue.isNotEmpty) {
      final number = int.parse(cleanValue);
      final formatted = '${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ريال';
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _amountController.clear();
    }
  }

  Future<void> _submitWithdrawalRequest() async {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    // Get clean amount
    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanAmount.isEmpty) {
      _showErrorDialog(isRtl ? 'الرجاء إدخال مبلغ السحب' : 'Please enter withdrawal amount', isRtl);
      return;
    }

    final amount = double.parse(cleanAmount);
    
    // Get current settings to ensure we use the latest minimum amount
    final currentSettings = await _referralService.getReferralSettings();
    final currentMinAmount = (currentSettings['minimumWithdrawal'] ?? 100.0).toDouble();
    print('Current minimum withdrawal amount: $currentMinAmount');
    
    // Validate amount
    if (amount < currentMinAmount) {
      _showErrorDialog(
        isRtl 
            ? 'الحد الأدنى للسحب هو ${currentMinAmount.toInt()} ريال سعودي'
            : 'Minimum withdrawal amount is ${currentMinAmount.toInt()} SAR',
        isRtl
      );
      return;
    }

    if (amount > _currentBalance) {
      _showErrorDialog(
        isRtl 
            ? 'رصيدك الحالي غير كافي. الرصيد المتاح: ${_currentBalance.toInt()} ريال'
            : 'Insufficient balance. Available balance: ${_currentBalance.toInt()} SAR',
        isRtl
      );
      return;
    }

    if (_accountController.text.trim().isEmpty) {
      _showErrorDialog(
        isRtl ? 'الرجاء إدخال رقم الحساب' : 'Please enter account number',
        isRtl
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _referralService.requestWithdrawal(amount, _accountController.text.trim());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _showSuccessDialog(isRtl);
        } else {
          _showErrorDialog(
            isRtl ? 'فشل في إرسال طلب السحب' : 'Failed to submit withdrawal request',
            isRtl
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          isRtl ? 'حدث خطأ أثناء إرسال الطلب' : 'Error occurred while submitting request',
          isRtl
        );
      }
    }
  }

  void _showErrorDialog(String message, bool isRtl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRtl ? 'خطأ' : 'Error',
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        content: Text(
          message,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRtl ? 'موافق' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(bool isRtl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRtl ? 'نجح الطلب' : 'Request Successful',
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        content: Text(
          isRtl 
              ? 'تم إرسال طلب السحب بنجاح. سيتم مراجعته قريباً.'
              : 'Withdrawal request submitted successfully. It will be reviewed soon.',
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous page
            },
            child: Text(isRtl ? 'موافق' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }
}