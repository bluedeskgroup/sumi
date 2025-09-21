import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sumi/features/wallet/services/wallet_service.dart';
import 'package:sumi/features/wallet/models/wallet_transaction.dart';
import 'package:sumi/features/auth/presentation/pages/withdrawal_request_page.dart';
import 'package:sumi/features/auth/presentation/pages/my_points_page.dart';
import 'package:sumi/features/store/presentation/pages/my_cards_page.dart';
import 'package:sumi/features/auth/services/points_service.dart';
import 'package:sumi/features/store/presentation/pages/my_orders_page.dart';
import 'package:sumi/features/store/presentation/pages/favorites_page.dart';
import 'package:sumi/features/store/presentation/pages/reviews_page.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.walletAndRewardPoints,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3E115A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRtl ? Icons.arrow_forward : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Header with gradient background
          _buildHeader(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 22),
                  
                  // Transaction filters and More section
                  _buildMoreSection(),
                  
                  const SizedBox(height: 22),
                  
                  // Recent transactions section 
                  _buildTransactionsSection(),
                  
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3E115A), Color(0xFF692C91)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Balance and Points section
            Row(

              children: [
                // Balance section
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.currentBalance,
                        style: const TextStyle(
                          color: Color(0xFFCED7DE),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 14),
                      StreamBuilder<double>(
                        stream: Provider.of<WalletService>(context).balanceStream(),
                        builder: (context, snapshot) {
                          final balance = snapshot.data ?? 1800.0;
                          return Text(
                            '${balance.toStringAsFixed(0)} ${l10n.sar}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 97),
                
                // Points section
                Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.yourRewardPoints,
                      style: const TextStyle(
                        color: Color(0xFFCED7DE),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: isRtl ? MainAxisAlignment.start : MainAxisAlignment.end,
        
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/wallet/coin.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StreamBuilder<int>(
                          stream: Provider.of<PointsService>(context).userPointsStream,
                          builder: (context, snapshot) {
                            final points = snapshot.data ?? 2160;
                            return Text(
                              '$points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,


              children: [
                _buildActionButton(
                  iconAsset: 'assets/images/wallet/table-list-alt.svg',
                  label: l10n.withdrawBalance,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WithdrawalRequestPage()),
                  ),
                ),
                _buildActionButton(
                  iconAsset: 'assets/images/wallet/coin.svg',
                  label: l10n.rewardPoints,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPointsPage()),
                  ),
                ),
                _buildActionButton(
                  iconAsset: 'assets/images/wallet/credit-card.svg',
                  label: l10n.paymentCards,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyCardsPage()),
                  ),
                ),
                _buildActionButton(
                  iconAsset: 'assets/images/wallet/wallet-plus.svg',
                  label: l10n.topUpWallet,
                  onTap: () => _showTopUpSheet(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String iconAsset,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF5C277C),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFAF6FE), width: 1),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFFAF6FE),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFAF6FE),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSection() {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.more,
            style: const TextStyle(
              color: Color(0xFF7991A4),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              _buildMoreItem(
                title: l10n.purchaseOrders,
                subtitle: l10n.trackShipping,
                iconAsset: 'assets/images/wallet/cart-shopping-fast.svg',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                ),
              ),
              const SizedBox(height: 24),
              _buildMoreItem(
                title: l10n.favorites,
                subtitle: l10n.browseFavorites,
                iconAsset: 'assets/images/wallet/heart-alt.svg',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesPage()),
                ),
              ),
              const SizedBox(height: 24),
              _buildMoreItem(
                title: l10n.reviews,
                subtitle: l10n.yourReviews,
                iconAsset: 'assets/images/wallet/star-sharp.svg',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReviewsPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreItem({
    required String title,
    required String subtitle,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: isRtl ? [
          // Arrow icon (first in RTL)
          Container(
            width: 16,
            height: 16,
            child: Transform.flip(
              flipX: true,
              child: SvgPicture.asset(
                'assets/images/wallet/arrow-sm-right.svg',
                width: 3.33,
                height: 8,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFC6C8CB),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1D2035),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9DA2A7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Icon (last in RTL)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6FE),
              borderRadius: BorderRadius.circular(48),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF9A46D7),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ] : [
          // Icon (first in LTR)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6FE),
              borderRadius: BorderRadius.circular(48),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF9A46D7),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1D2035),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9DA2A7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Arrow icon (last in LTR)
          Container(
            width: 16,
            height: 16,
            child: SvgPicture.asset(
              'assets/images/wallet/arrow-sm-right.svg',
              width: 3.33,
              height: 8,
              colorFilter: const ColorFilter.mode(
                Color(0xFFC6C8CB),
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentTransactions,
            style: const TextStyle(
              color: Color(0xFF7991A4),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 14),
          
          // Mock transaction items
          _buildTransactionItem(
            title: l10n.transactionCancelled,
            subtitle: '460 ${l10n.transactionCost}',
            time: '6 ${l10n.minutes}',
            iconType: 'info',
            amountColor: const Color(0xFFF68801),
          ),
          const SizedBox(height: 10),
          _buildTransactionItem(
            title: l10n.bookingCancelled,
            subtitle: l10n.refundProcessed,
            time: '${l10n.wednesday} 15 March 2024 . 02:24',
            iconType: 'error',
            amountColor: const Color(0xFFD01B2D),
          ),
          const SizedBox(height: 10),
          _buildTransactionItem(
            title: l10n.bookingPaid,
            subtitle: '490 ${l10n.bookingCost}',
            time: '${l10n.wednesday} 15 March 2024 . 02:24',
            iconType: 'success',
            amountColor: const Color(0xFF1AB385),
          ),
          const SizedBox(height: 10),
          _buildTransactionItem(
            title: l10n.bookingPaid,
            subtitle: '490 ${l10n.bookingCost}',
            time: '${l10n.wednesday} 15 March 2024 . 02:24',
            iconType: 'success',
            amountColor: const Color(0xFF1AB385),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String time,
    required String iconType,
    required Color amountColor,
  }) {
    String iconAsset;
    Color bgColor;
    
    switch (iconType) {
      case 'success':
        iconAsset = 'assets/images/wallet/circle-check.svg';
        bgColor = const Color(0xFFDDFAF2);
        break;
      case 'error':
        iconAsset = 'assets/images/wallet/circle-xmark.svg';
        bgColor = const Color(0xFFFADCDF);
        break;
      case 'info':
      default:
        iconAsset = 'assets/images/wallet/circle-information.svg';
        bgColor = const Color(0xFFFFEED9);
        break;
    }

    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    return Row(
      mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // Image and icon
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(64),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: SvgPicture.asset(
                iconAsset,
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1D2035),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF9DA2A7),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
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

  void _showTopUpSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.topUpWallet,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.topUpAmount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                if (amount > 0) {
                  await Provider.of<WalletService>(context, listen: false)
                      .credit(amount: amount, title: l10n.topUpWallet, reference: null);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }
}