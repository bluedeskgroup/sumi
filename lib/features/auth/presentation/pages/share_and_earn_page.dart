import 'package:flutter/material.dart';
import 'package:sumi/features/auth/models/referral_model.dart';
import 'package:sumi/features/auth/services/referral_service.dart';
import 'package:sumi/core/models/dynamic_referral_level.dart';
import 'package:sumi/core/services/dynamic_levels_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/auth/presentation/pages/withdrawal_history_page.dart';
import 'package:sumi/features/auth/presentation/pages/withdrawal_request_page.dart';

class ShareAndEarnPage extends StatefulWidget {
  const ShareAndEarnPage({super.key});

  @override
  State<ShareAndEarnPage> createState() => _ShareAndEarnPageState();
}

class _ShareAndEarnPageState extends State<ShareAndEarnPage> {
  final ReferralService _referralService = ReferralService();
  final DynamicLevelsService _levelsService = DynamicLevelsService();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _listenForGiftNotifications();
  }

  Future<void> _initializeData() async {
    // Initialize with enhanced tracking for better admin visibility
    await _referralService.initializeUserReferralWithTracking();
    await _levelsService.initializeLevels();
    
    // Ensure user has a referral code
    await _ensureReferralCodeExists();
  }

  Future<void> _ensureReferralCodeExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (!userDoc.exists || userDoc.data()?['referralCode'] == null) {
          // Force initialize if not exists
          await _referralService.initializeUserReferralWithTracking();
          print('تم إنشاء كود الإحالة تلقائياً للمستخدم');
        }
      }
    } catch (e) {
      print('خطأ في التحقق من كود الإحالة: $e');
    }
  }

  void _listenForGiftNotifications() {
    _referralService.getGiftNotificationsStream().listen((notifications) {
      if (notifications.isNotEmpty && mounted) {
        // Show notification for the latest unread notification
        final latestNotification = notifications.where((n) => !n['isRead']).isNotEmpty 
            ? notifications.where((n) => !n['isRead']).first 
            : null;
            
        if (latestNotification != null) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              final isRtl = Localizations.localeOf(context).languageCode == 'ar';
              
              // Show different dialogs based on notification type
              if (latestNotification['type'] == 'admin_bonus') {
                _showBonusNotificationDialog(isRtl, latestNotification);
              } else {
                _showGiftDialog(isRtl);
              }
              
              // Mark notification as read
              _referralService.markNotificationAsRead(latestNotification['id']);
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<ReferralStats>(
            stream: _referralService.getReferralStatsStream(),
            builder: (context, statsSnapshot) {
              if (!statsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final stats = statsSnapshot.data!;

              return Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    // Main Content
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // Content Frame
                          Container(
                            width: double.infinity,
                            child: Column(
                              children: [
                                // Header
                                _buildHeader(isRtl),
                                
                                const SizedBox(height: 8),
                                
                                // Main Content
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    children: [
                                      // Referral Levels Section
                                      _buildReferralLevelsSection(isRtl, stats.referralsCount),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Welcome Text
                                      _buildWelcomeSection(isRtl),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Divider
                                      _buildDivider(),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Stats Section
                                      _buildStatsSection(isRtl, stats),
                                      
                                                                    const SizedBox(height: 20),
                              
                              // Withdraw Button
                              _buildWithdrawButton(isRtl, stats.currentBalance),
                              
                              const SizedBox(height: 10),
                              
                              // Withdrawal History Button
                              _buildWithdrawalHistoryButton(isRtl),
                              
                              const SizedBox(height: 10),
              
              // Share Buttons Section
              _buildShareButtonsSection(isRtl, stats.referralCode),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Divider
                                      _buildDivider(),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Transactions Section
                                      _buildTransactionsSection(isRtl),
                                      
                                      const SizedBox(height: 100), // Space for bottom section
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bottom Fixed Section
                    _buildBottomSection(isRtl, stats.referralCode),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(bool isRtl) {
    return Container(
      width: double.infinity,
      height: 80,
      color: Color(0xFF9A46D7),
      child: Stack(
        children: [
          // Back button
          Positioned(
            left: isRtl ? null : 24,
            right: isRtl ? 24 : null,
            top: 28,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 24,
                height: 24,
                child: Icon(
                  isRtl ? Icons.arrow_forward : Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Title
          Positioned(
            left: 114,
            top: 31,
            child: Container(
              width: 202,
              height: 19,
              child: Text(
                isRtl ? 'شارك وإربح' : 'Share and Earn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                ),
                textAlign: TextAlign.center,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ),
          
          // Filter button
          Positioned(
            right: isRtl ? null : 24,
            left: isRtl ? 24 : null,
            top: 12.5,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Color(0xFFE7EBEF)),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF1D2035),
                    size: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralLevelsSection(bool isRtl, int referralsCount) {
    return StreamBuilder<List<DynamicReferralLevel>>(
      stream: _levelsService.getActiveLevelsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          print('Error in levels stream: ${snapshot.error}');
          return Container(
            height: 120,
            child: const Center(child: Text('خطأ في تحميل المستويات')),
          );
        }
        
        final levels = snapshot.data ?? [];
        if (levels.isEmpty) {
          return Container(
            height: 120,
            child: const Center(child: Text('لا توجد مستويات متاحة')),
          );
        }

        final currentLevel = _levelsService.getUserLevel(referralsCount);
        
        return Container(
          width: double.infinity,
          child: Column(
            children: [
              // Visual representation with levels and connecting lines
              Container(
                height: 100,
                child: Column(
                  children: [
                    // Levels Row
                    Container(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: levels.map((level) => _buildLevelIcon(level, referralsCount)).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Connecting Lines
                    if (levels.length > 1) _buildConnectingLines(levels, currentLevel),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Labels
              Container(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: levels.map((level) => 
                    Flexible(child: _buildDynamicLevelLabel(isRtl, level))
                  ).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelIcon(DynamicReferralLevel level, int referralsCount) {
    try {
      final isAchieved = referralsCount >= level.threshold;
      final isCurrentLevel = _levelsService.getUserLevel(referralsCount)?.id == level.id;
      
      return Flexible(
        child: Container(
          width: isCurrentLevel ? 70 : 60,
          height: isCurrentLevel ? 70 : 60,
          decoration: BoxDecoration(
            color: Color(_levelsService.parseColorHex(level.colorHex)).withOpacity(isAchieved ? 1.0 : 0.3),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: isCurrentLevel ? Color(0xFF9A46D7) : Colors.transparent,
              width: isCurrentLevel ? 3 : 0,
            ),
            boxShadow: isCurrentLevel ? [
              BoxShadow(
                color: Color(0xFF9A46D7).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              level.iconCode.isNotEmpty ? level.iconCode : '🏆',
              style: TextStyle(
                fontSize: isCurrentLevel ? 32 : 28,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error building level icon: $e');
      return Flexible(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(35),
          ),
          child: const Center(
            child: Text('🏆', style: TextStyle(fontSize: 28)),
          ),
        ),
      );
    }
  }

  Widget _buildConnectingLines(List<DynamicReferralLevel> levels, DynamicReferralLevel? currentLevel) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(levels.length - 1, (index) {
          final currentLevelIndex = currentLevel != null 
              ? levels.indexWhere((l) => l.id == currentLevel.id)
              : -1;
          
          final isActive = currentLevelIndex > index;
          
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? Color(0xFF9A46D7) : Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDynamicLevelLabel(bool isRtl, DynamicReferralLevel level) {
    return Container(
      child: Column(
        children: [
          Text(
            isRtl ? level.nameAr : level.nameEn,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(_levelsService.parseColorHex(level.colorHex)),
              fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              isRtl 
                ? '${level.percentage.toString().padLeft(2, '0')}% عائد على كل تسجيل من خلالك'
                : '${level.percentage.toString().padLeft(2, '0')}% return on each signup',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Color(0xFFA1B2BF),
                fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
              ),
              textAlign: TextAlign.center,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildWelcomeSection(bool isRtl) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 21,
            child: Text(
              isRtl ? 'مرحبا بك فى نظام الاحالة' : 'Welcome to the Referral System',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2035),
                fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                height: 1.6,
              ),
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          
          const SizedBox(height: 10),
          
          Container(
            height: 59,
            child: Text(
              isRtl 
                ? 'اكسب نقاط مكافآت مع كل حجز أو مشاركة للتطبيق مع صديقاتك، واستخدمي النقاط للحصول على خصومات حصرية على خدمات الجمال والموضة. اجمعي النقاط بسهولة واستمتعي بأفضل العروض المصممة لكِ!'
                : 'Earn reward points with every booking or app sharing with your friends, and use points to get exclusive discounts on beauty and fashion services. Collect points easily and enjoy the best offers designed for you!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7991A4),
                fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                height: 1.6,
              ),
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isRtl, ReferralStats stats) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          _buildStatRow(
            isRtl,
            isRtl ? 'رصيد حسابك الحالى :' : 'Your Current Balance:',
            '${stats.currentBalance.toInt()} ${isRtl ? 'ريال سعودي' : 'SAR'}',
            127,
          ),
          const SizedBox(height: 14),
          _buildStatRow(
            isRtl,
            isRtl ? 'اجمالى أرباحك :' : 'Total Earnings:',
            '${stats.totalEarnings.toInt()} ${isRtl ? 'ريال سعودي' : 'SAR'}',
            161,
          ),
          const SizedBox(height: 14),
          _buildStatRow(
            isRtl,
            isRtl ? 'عدد من سجل من خلالك :' : 'Referrals Count:',
            '${stats.referralsCount} ${isRtl ? 'مستخدمين' : 'users'}',
            153,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(bool isRtl, String label, String value, double valueWidth) {
    return Container(
      width: double.infinity,
      height: 19,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7991A4),
              fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
            ),
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          Container(
            width: valueWidth,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9A46D7),
                fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
              ),
              textAlign: TextAlign.left,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton(bool isRtl, double currentBalance) {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: currentBalance >= 100 ? () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WithdrawalRequestPage(),
            ),
          );
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFAF6FE),
          foregroundColor: Color(0xFF9A46D7),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Color(0xFFF5F5F5),
          disabledForegroundColor: Color(0xFFBBBBBB),
        ),
        child: Text(
          isRtl ? 'سحب الرصيد' : 'Withdraw Balance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
          ),
          textAlign: TextAlign.center,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  Widget _buildWithdrawalHistoryButton(bool isRtl) {
    return Container(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WithdrawalHistoryPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF9A46D7),
          side: BorderSide(color: Color(0xFF9A46D7), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: Icon(
          Icons.history,
          size: 18,
          color: Color(0xFF9A46D7),
        ),
        label: Text(
          isRtl ? 'عرض سجل السحب' : 'View Withdrawal History',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
            color: Color(0xFF9A46D7),
          ),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(bool isRtl) {
    return StreamBuilder<List<ReferralTransaction>>(
      stream: _referralService.getReferralTransactionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final transactions = snapshot.data!;
        
        if (transactions.isEmpty) {
          return Container(
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Color(0xFF9A46D7).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isRtl ? 'لا توجد معاملات بعد' : 'No transactions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7991A4),
                    fontFamily: isRtl ? 'Almarai' : null,
                  ),
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                Text(
                  isRtl ? 'ابدأ بمشاركة كود الإحالة وشاهد معاملاتك هنا!' : 'Start sharing your referral code and watch your transactions here!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9A46D7),
                    fontFamily: isRtl ? 'Almarai' : null,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          child: Column(
            children: transactions.take(4).map((transaction) => 
              _buildTransactionItem(isRtl, transaction)
            ).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(bool isRtl, ReferralTransaction transaction) {
    final isPositive = transaction.amount > 0;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  height: 51,
                  child: Column(
                    crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 24,
                        child: Text(
                          transaction.description,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF323F49),
                            fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                            height: 1.5,
                          ),
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 19,
                        child: Text(
                          isPositive 
                            ? '${transaction.amount.abs().toInt()} ${isRtl ? 'نقطة تم إضافتها' : 'points added'}'
                            : '${transaction.amount.abs().toInt()} ${isRtl ? 'نقطة تم استخدامها' : 'points used'}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF92A5B5),
                            fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                            height: 1.6,
                          ),
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 35,
                  height: 20,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    transaction.getFormattedDate(isRtl),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9DA2A7),
                      fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                      height: 1.6,
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(0xFFFFEED9).withOpacity(0.5),
              borderRadius: BorderRadius.circular(64),
            ),
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                child: Image.asset(
                  'assets/images/referral/transaction_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isRtl, String referralCode) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 60,
              color: Color(0xFF040F0F).withOpacity(0.05),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 130,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 32,
                    alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      isRtl ? 'كود : $referralCode' : 'Code : $referralCode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2035),
                        fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                        height: 1.5,
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () => _copyReferralCode(isRtl, referralCode),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF9A46D7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                Icons.content_copy,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                isRtl ? 'نسخ كود المشاركة' : 'Copy Referral Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                                ),
                                textAlign: TextAlign.center,
                                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Container(
                          width: 108,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const WithdrawalHistoryPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFAF6FE),
                              foregroundColor: Color(0xFF9A46D7),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: Container(
                              width: 80.1,
                              height: 20.61,
                              child: Text(
                                isRtl ? 'سجل السحب' : 'Withdrawal Log',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9A46D7),
                                  fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Home Indicator
            Container(
              width: double.infinity,
              height: 34,
              child: Center(
                child: Container(
                  width: 148,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFFAAB9C5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButtonsSection(bool isRtl, String referralCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isRtl ? 'شارك كود الإحالة مع أصدقائك' : 'Share your referral code with friends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2035),
              fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: Color(0xFF25D366),
                onTap: () => _shareViaWhatsApp(isRtl, referralCode),
              ),
              _buildShareButton(
                icon: Icons.send,
                label: 'Telegram',
                color: Color(0xFF0088CC),
                onTap: () => _shareViaTelegram(isRtl, referralCode),
              ),
              _buildShareButton(
                icon: Icons.email,
                label: isRtl ? 'إيميل' : 'Email',
                color: Color(0xFF34495E),
                onTap: () => _shareViaEmail(isRtl, referralCode),
              ),
              _buildShareButton(
                icon: Icons.share,
                label: isRtl ? 'مشاركة' : 'Share',
                color: Color(0xFF9A46D7),
                onTap: () => _shareGeneral(isRtl, referralCode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7991A4),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 380,
      height: 1,
      decoration: BoxDecoration(
        color: Color(0xFFB6C3CD).withOpacity(0.15),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // Helper methods remain the same...
  Future<void> _copyReferralCode(bool isRtl, String referralCode) async {
    await _referralService.copyReferralCode(referralCode);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Text(
              isRtl ? 'تم نسخ كود المشاركة' : 'Referral code copied',
              style: TextStyle(
                fontFamily: isRtl ? 'Almarai' : null,
              ),
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          backgroundColor: Color(0xFF9A46D7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }





  void _showBonusNotificationDialog(bool isRtl, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_giftcard,
                  size: 40,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                notification['title'] ?? (isRtl ? 'مكافأة جديدة!' : 'New Bonus!'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D2035),
                  fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${notification['amount'].toStringAsFixed(0)} ${isRtl ? 'ريال سعودي' : 'SAR'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9A46D7),
                    fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                notification['message'] ?? (isRtl ? 'تم إضافة مكافأة لحسابك!' : 'A bonus has been added to your account!'),
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF7991A4),
                  fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                ),
                textAlign: TextAlign.center,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
              
              const SizedBox(height: 24),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A46D7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isRtl ? 'رائع!' : 'Great!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGiftDialog(bool isRtl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0xFF1D2035).withOpacity(0.45),
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          width: double.infinity,
          height: 466,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE7EBEF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Header with title and close button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Text(
                      isRtl ? 'هدية' : 'Gift',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D2035),
                        fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                      ),
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.close,
                          color: Color(0xFFCED7DE),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gift illustration
                      Container(
                        width: 143,
                        height: 143,
                        child: Image.asset(
                          'assets/images/referral/gift_illustration.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Title and description container
                      Container(
                        width: 364,
                        child: Column(
                          children: [
                            // Main title
                            Text(
                              isRtl ? 'كسبت 50 نقطة هدية!' : 'You earned 50 bonus points!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D2035),
                                fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                                height: 1.38,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Description
                            Text(
                              isRtl 
                                ? 'حصلت على 50 نقطة في نقاط المكافآت لديك مقابل تسجيل صديقك من خلال رمز الدعوه الخاص بيك'
                                : 'You received 50 points in your rewards points for your friend\'s registration through your referral code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF637D92),
                                fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9A46D7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: Size(double.infinity, 60),
                  ),
                  child: Text(
                    isRtl ? 'استلام الهدية' : 'Claim Gift',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: isRtl ? 'Almarai' : 'Ping AR + LT',
                    ),
                    textAlign: TextAlign.center,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Share Methods
  Future<void> _shareViaWhatsApp(bool isRtl, String referralCode) async {
    await _trackSharingEvent('whatsapp', referralCode);
    
    final message = isRtl 
      ? 'مرحباً! 🌟\n\nاكتشف تطبيق سومي الرائع للجمال والموضة! استخدم كود الإحالة الخاص بي: $referralCode واحصل على خصومات حصرية.\n\nحمل التطبيق الآن واستمتع بأفضل الخدمات! 💫'
      : 'Hello! 🌟\n\nDiscover the amazing Sumi app for beauty and fashion! Use my referral code: $referralCode and get exclusive discounts.\n\nDownload the app now and enjoy the best services! 💫';
    
    try {
      await Share.share(
        message,
        subject: isRtl ? 'شارك تطبيق سومي عبر واتساب' : 'Share Sumi App via WhatsApp',
      );
    } catch (e) {
      print('Error sharing via WhatsApp: $e');
      _showShareFallback(isRtl, referralCode);
    }
  }

  Future<void> _shareViaTelegram(bool isRtl, String referralCode) async {
    await _trackSharingEvent('telegram', referralCode);
    
    final message = isRtl 
      ? 'مرحباً! 🌟\n\nاكتشف تطبيق سومي الرائع للجمال والموضة! استخدم كود الإحالة الخاص بي: $referralCode واحصل على خصومات حصرية.\n\nحمل التطبيق الآن واستمتع بأفضل الخدمات! 💫'
      : 'Hello! 🌟\n\nDiscover the amazing Sumi app for beauty and fashion! Use my referral code: $referralCode and get exclusive discounts.\n\nDownload the app now and enjoy the best services! 💫';
    
    try {
      await Share.share(
        message,
        subject: isRtl ? 'شارك تطبيق سومي عبر تيليجرام' : 'Share Sumi App via Telegram',
      );
    } catch (e) {
      print('Error sharing via Telegram: $e');
      _showShareFallback(isRtl, referralCode);
    }
  }

  Future<void> _shareViaEmail(bool isRtl, String referralCode) async {
    await _trackSharingEvent('email', referralCode);
    
    final message = isRtl 
      ? 'مرحباً!\n\nأريد أن أشارك معك تطبيق سومي الرائع للجمال والموضة!\n\nاستخدم كود الإحالة الخاص بي: $referralCode واحصل على خصومات حصرية عند التسجيل.\n\nحمل التطبيق الآن واستمتع بأفضل خدمات الجمال والموضة!\n\nشكراً لك! 💫'
      : 'Hello!\n\nI want to share with you the amazing Sumi app for beauty and fashion!\n\nUse my referral code: $referralCode and get exclusive discounts when you sign up.\n\nDownload the app now and enjoy the best beauty and fashion services!\n\nThank you! 💫';
    
    try {
      await Share.share(
        message,
        subject: isRtl ? 'كود إحالة تطبيق سومي' : 'Sumi App Referral Code',
      );
    } catch (e) {
      print('Error sharing via email: $e');
      _showShareFallback(isRtl, referralCode);
    }
  }

  Future<void> _shareGeneral(bool isRtl, String referralCode) async {
    await _trackSharingEvent('general', referralCode);
    
    final message = isRtl 
      ? 'مرحباً! 🌟\n\nاكتشف تطبيق سومي الرائع للجمال والموضة! استخدم كود الإحالة الخاص بي: $referralCode واحصل على خصومات حصرية.\n\nحمل التطبيق الآن واستمتع بأفضل الخدمات! 💫'
      : 'Hello! 🌟\n\nDiscover the amazing Sumi app for beauty and fashion! Use my referral code: $referralCode and get exclusive discounts.\n\nDownload the app now and enjoy the best services! 💫';
    
    try {
      await Share.share(
        message,
        subject: isRtl ? 'كود إحالة تطبيق سومي' : 'Sumi App Referral Code',
      );
    } catch (e) {
      print('Error sharing: $e');
      _showShareFallback(isRtl, referralCode);
    }
  }

  void _showShareFallback(bool isRtl, String referralCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRtl ? 'مشاركة كود الإحالة' : 'Share Referral Code',
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
        content: SelectableText(
          isRtl 
            ? 'كود الإحالة الخاص بك: $referralCode\n\nانسخ هذا الكود وشاركه مع أصدقائك!'
            : 'Your referral code: $referralCode\n\nCopy this code and share it with your friends!',
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isRtl ? 'موافق' : 'OK',
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _trackSharingEvent(String platform, String referralCode) async {
    try {
      if (_currentUser == null) return;
      
      await _referralService.trackSharingEvent(platform, referralCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Directionality.of(context) == TextDirection.rtl 
                ? 'تم فتح $platform للمشاركة' 
                : 'Opened $platform for sharing',
              textDirection: Directionality.of(context),
            ),
            backgroundColor: Color(0xFF9A46D7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error tracking sharing event: $e');
    }
  }

  User? get _currentUser => FirebaseAuth.instance.currentUser;
}