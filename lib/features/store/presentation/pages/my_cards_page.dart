import 'package:flutter/material.dart';
import 'package:sumi/features/store/models/card_model.dart';
import 'package:sumi/features/store/services/cards_service.dart';
import 'package:intl/intl.dart';

class MyCardsPage extends StatefulWidget {
  const MyCardsPage({super.key});

  @override
  State<MyCardsPage> createState() => _MyCardsPageState();
}

class _MyCardsPageState extends State<MyCardsPage> {
  final CardsService _cardsService = CardsService();
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                child: Column(
                  children: [
                    // Action Buttons
                    _buildActionButtons(isRtl),
                    
                    const SizedBox(height: 24),
                    
                    // Available Cards
                    _buildAvailableCards(isRtl),
                    
                    const SizedBox(height: 24),
                    
                    // User's Cards
                    _buildUserCards(isRtl),
                    
                    const SizedBox(height: 24),
                    
                    // Pending Requests
                    _buildPendingRequests(isRtl),
                    
                    const SizedBox(height: 100), // Bottom padding
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
                isRtl ? 'بطاقاتي' : 'My Cards',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1D2035),
                ),
              ),
            ),
            
            // Space for balance
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isRtl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Add Card Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.26),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRtl ? 'أضافة بطاقة' : 'Add Card',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Close Button
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.24),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCards(bool isRtl) {
    return StreamBuilder<List<CardModel>>(
      stream: _cardsService.getAvailableCardsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            isRtl ? 'لا توجد بطاقات متاحة حالياً' : 'No cards available',
            Icons.credit_card_outlined,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                isRtl ? 'البطاقات المتاحة' : 'Available Cards',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF2B2F4E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _pageController,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final card = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCardWidget(card, isRtl),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCards(bool isRtl) {
    return StreamBuilder<List<UserCard>>(
      stream: _cardsService.getUserCardsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                isRtl ? 'بطاقاتي الحالية' : 'My Current Cards',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF2B2F4E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final userCard = snapshot.data![index];
                return _buildUserCardItem(userCard, isRtl);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingRequests(bool isRtl) {
    return StreamBuilder<List<UserCardRequest>>(
      stream: _cardsService.getUserCardRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final pendingRequests = snapshot.data!
            .where((request) => request.status == 'pending')
            .toList();

        if (pendingRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                isRtl ? 'الطلبات المعلقة' : 'Pending Requests',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF2B2F4E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: pendingRequests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return _buildPendingRequestItem(request, isRtl);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardWidget(CardModel card, bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCardGradientColors(card.cardDesign),
        ),
      ),
      child: Stack(
        children: [
          // Background pattern (optional)
          if (card.cardDesign['hasPattern'] == true)
            _buildCardPattern(),
          
          // Card content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Card title and description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: Color(0xFFFAF6FE),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.description,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        color: Color(0xFFE7EBEF),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Card features and request button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Request button
                    FutureBuilder<String?>(
                      future: _cardsService.getCardRequestStatus(card.id),
                      builder: (context, statusSnapshot) {
                        return FutureBuilder<bool>(
                          future: _cardsService.userHasCard(card.id),
                          builder: (context, hasCardSnapshot) {
                            return _buildCardActionButton(
                              card, 
                              isRtl, 
                              statusSnapshot.data,
                              hasCardSnapshot.data ?? false,
                            );
                          },
                        );
                      },
                    ),
                    
                    // Free badge
                    if (card.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6FE),
                          borderRadius: BorderRadius.circular(49),
                        ),
                        child: Text(
                          isRtl ? 'مجاني' : 'Free',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF9A46D7),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButton(CardModel card, bool isRtl, String? requestStatus, bool hasCard) {
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    if (hasCard) {
      buttonText = isRtl ? 'مملوكة' : 'Owned';
      buttonColor = const Color(0xFF1ED29C);
      onPressed = null;
    } else if (requestStatus == 'pending') {
      buttonText = isRtl ? 'معلقة' : 'Pending';
      buttonColor = const Color(0xFFFEAA43);
      onPressed = null;
    } else if (requestStatus == 'rejected') {
      buttonText = isRtl ? 'مرفوضة' : 'Rejected';
      buttonColor = const Color(0xFFFF4757);
      onPressed = () => _requestCard(card);
    } else {
      buttonText = isRtl ? 'طلب البطاقة' : 'Request Card';
      buttonColor = const Color(0xFF9A46D7);
      onPressed = () => _requestCard(card);
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(
          fontFamily: 'Ping AR + LT',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildUserCardItem(UserCard userCard, bool isRtl) {
    return FutureBuilder<CardModel?>(
      future: _cardsService.getCard(userCard.cardId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        final card = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7EBEF)),
          ),
          child: Row(
            children: [
              // Card icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF68801).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFFF68801),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Card info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1D2035),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRtl 
                        ? 'صدرت في ${DateFormat('dd/MM/yyyy').format(userCard.issuedAt)}'
                        : 'Issued on ${DateFormat('dd/MM/yyyy').format(userCard.issuedAt)}',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xFF637D92),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: userCard.isValid 
                    ? const Color(0xFF1ED29C).withOpacity(0.1)
                    : const Color(0xFFFF4757).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  userCard.isValid 
                    ? (isRtl ? 'نشطة' : 'Active')
                    : (isRtl ? 'منتهية' : 'Expired'),
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: userCard.isValid 
                      ? const Color(0xFF1ED29C)
                      : const Color(0xFFFF4757),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestItem(UserCardRequest request, bool isRtl) {
    return FutureBuilder<CardModel?>(
      future: _cardsService.getCard(request.cardId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        final card = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFEAA43).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Pending icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEAA43).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_outlined,
                  color: Color(0xFFFEAA43),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Request info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1D2035),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRtl 
                        ? 'طُلبت في ${DateFormat('dd/MM/yyyy').format(request.requestedAt)}'
                        : 'Requested on ${DateFormat('dd/MM/yyyy').format(request.requestedAt)}',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xFF637D92),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cancel button
              TextButton(
                onPressed: () => _cancelRequest(request),
                child: Text(
                  isRtl ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFFFF4757),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardPattern() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getCardGradientColors(Map<String, dynamic> cardDesign) {
    final gradientType = cardDesign['gradientType'] ?? 'golden';
    
    switch (gradientType) {
      case 'golden':
        return [
          const Color(0xFFD17401),
          const Color(0xFFF68801),
        ];
      case 'purple':
        return [
          const Color(0xFF9A46D7),
          const Color(0xFF7B2CBF),
        ];
      case 'green':
        return [
          const Color(0xFF1ED29C),
          const Color(0xFF1AB385),
        ];
      default:
        return [
          const Color(0xFFD17401),
          const Color(0xFFF68801),
        ];
    }
  }

  Future<void> _requestCard(CardModel card) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _cardsService.requestCard(card.id);
    
    // Hide loading
    if (mounted) Navigator.of(context).pop();

    // Show result
    if (mounted) {
      final isRtl = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? (isRtl ? 'تم إرسال طلب البطاقة بنجاح' : 'Card request sent successfully')
              : (isRtl ? 'فشل في إرسال طلب البطاقة' : 'Failed to send card request'),
          ),
          backgroundColor: success 
            ? const Color(0xFF1ED29C)
            : const Color(0xFFFF4757),
        ),
      );
    }
  }

  Future<void> _cancelRequest(UserCardRequest request) async {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRtl ? 'إلغاء الطلب' : 'Cancel Request'),
        content: Text(isRtl 
          ? 'هل تريد إلغاء طلب البطاقة؟'
          : 'Do you want to cancel the card request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isRtl ? 'لا' : 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isRtl ? 'نعم' : 'Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _cardsService.cancelCardRequest(request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? (isRtl ? 'تم إلغاء الطلب بنجاح' : 'Request cancelled successfully')
                : (isRtl ? 'فشل في إلغاء الطلب' : 'Failed to cancel request'),
            ),
            backgroundColor: success 
              ? const Color(0xFF1ED29C)
              : const Color(0xFFFF4757),
          ),
        );
      }
    }
  }
}