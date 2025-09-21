import 'package:flutter/material.dart';
import 'package:sumi/features/auth/models/referral_model.dart';
import 'package:sumi/features/auth/services/referral_service.dart';
import 'package:intl/intl.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  final ReferralService _referralService = ReferralService();

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
            
            // Section Header
            _buildSectionHeader(isRtl),
            
            // Withdrawal List
            Expanded(
              child: _buildWithdrawalList(isRtl),
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
                isRtl ? 'سجل السحب' : 'Withdrawal History',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1D2035),
                ),
              ),
            ),
            
            // Filter Button
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

  Widget _buildSectionHeader(bool isRtl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Text(
        isRtl ? 'معاملاتك السابقة خلال الشهر' : 'Your Previous Transactions This Month',
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontFamily: 'Ping AR + LT',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF1D2035),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildWithdrawalList(bool isRtl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<List<WithdrawalRecord>>(
        stream: _referralService.getWithdrawalRecordsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error in withdrawal stream: ${snapshot.error}');
            return _buildErrorState(isRtl, snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isRtl);
          }

          final withdrawals = snapshot.data!;
          return ListView.separated(
            itemCount: withdrawals.length,
            separatorBuilder: (context, index) => _buildSeparator(),
            itemBuilder: (context, index) {
              final withdrawal = withdrawals[index];
              return _buildWithdrawalItem(withdrawal, isRtl);
            },
          );
        },
      ),
    );
  }

  Widget _buildWithdrawalItem(WithdrawalRecord withdrawal, bool isRtl) {
    final isCompleted = withdrawal.status == 'completed';
    final isPending = withdrawal.status == 'pending';

    // Colors based on status
    Color statusColor;
    Color backgroundColor;
    IconData statusIcon;
    String statusText;
    String detailText;

    if (isCompleted) {
      statusColor = const Color(0xFF1ED29C);
      backgroundColor = const Color(0xFFDDFAF2);
      statusIcon = Icons.check_circle_outline;
      statusText = isRtl 
          ? 'تم سحب ${withdrawal.amount.toStringAsFixed(0)} ريال بنجاح من رصيدك'
          : 'Successfully withdrew ${withdrawal.amount.toStringAsFixed(0)} SAR from your balance';
      detailText = isRtl 
          ? 'المبلغ ${withdrawal.amount.toStringAsFixed(0)} رس'
          : 'Amount ${withdrawal.amount.toStringAsFixed(0)} SAR';
    } else if (isPending) {
      statusColor = const Color(0xFFFEAA43);
      backgroundColor = const Color(0xFFFFEED9);
      statusIcon = Icons.info_outline;
      statusText = isRtl 
          ? '${withdrawal.amount.toStringAsFixed(0)} ريال رصيد تحت التسوية ..'
          : '${withdrawal.amount.toStringAsFixed(0)} SAR balance under review..';
      detailText = isRtl 
          ? 'يتم مراجعة رصيد المعاملات من البنك لضمان سلامة المعاملات فى التطبيق'
          : 'Transaction balance is being reviewed by the bank to ensure transaction safety in the app';
    } else { // rejected
      statusColor = const Color(0xFFFF4757);
      backgroundColor = const Color(0xFFFFE5E7);
      statusIcon = Icons.close_outlined;
      statusText = isRtl 
          ? 'تم رفض طلب سحب ${withdrawal.amount.toStringAsFixed(0)} ريال'
          : 'Withdrawal request of ${withdrawal.amount.toStringAsFixed(0)} SAR was rejected';
      detailText = isRtl 
          ? withdrawal.rejectionReason ?? 'لم يتم تحديد سبب الرفض'
          : withdrawal.rejectionReason ?? 'No rejection reason specified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Main content frame
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Title and description
                      SizedBox(
                        height: 51,
                        child: Column(
                          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Main title
                            SizedBox(
                              height: 24,
                              width: double.infinity,
                              child: Text(
                                statusText,
                                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xFF1D2035),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Detail text
                            SizedBox(
                              height: 19,
                              width: double.infinity,
                              child: Text(
                                detailText,
                                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                                style: TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                  color: isCompleted ? const Color(0xFF1AB385) : const Color(0xFFF68801),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Time
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        width: 250,
                        height: 20,
                        child: Text(
                          _formatDate(withdrawal.timestamp, isRtl),
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: Color(0xFF9DA2A7),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Status Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(64),
            ),
            child: Icon(
              statusIcon,
              size: 24,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      height: 1,
      width: double.infinity,
      color: const Color(0xFFE2E6EE),
    );
  }

  Widget _buildEmptyState(bool isRtl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isRtl ? 'لا توجد عمليات سحب حتى الآن' : 'No withdrawals yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl 
                ? 'عندما تقوم بطلب سحب ستظهر هنا'
                : 'When you request a withdrawal, it will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isRtl, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            isRtl ? 'حدث خطأ في تحميل سجل السحب' : 'Error loading withdrawal history',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isRtl 
                ? 'حاول مرة أخرى أو تواصل مع الدعم'
                : 'Try again or contact support',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Trigger a rebuild to retry the stream
              });
            },
            child: Text(
              isRtl ? 'إعادة المحاولة' : 'Retry',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime, bool isRtl) {
    if (isRtl) {
      final weekdays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 
                     'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      
      final weekday = weekdays[dateTime.weekday % 7];
      final month = months[dateTime.month - 1];
      final time = DateFormat('HH:mm').format(dateTime);
      
      return 'يوم $weekday ${dateTime.day} $month ${dateTime.year} . الساعة $time';
    } else {
      return DateFormat('EEEE dd MMMM yyyy . HH:mm').format(dateTime);
    }
  }
}