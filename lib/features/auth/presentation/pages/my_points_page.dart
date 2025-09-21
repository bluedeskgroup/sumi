import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sumi/features/auth/models/challenge_model.dart';
import 'package:sumi/features/auth/services/points_service.dart';
import 'package:sumi/features/auth/presentation/pages/challenge_completed_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyPointsPage extends StatefulWidget {
  const MyPointsPage({super.key});

  @override
  State<MyPointsPage> createState() => _MyPointsPageState();
}

class _MyPointsPageState extends State<MyPointsPage> {
  final PointsService _pointsService = PointsService();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    // Force RTL for Arabic content
    if (isRtl) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: AppBar(
              title: Text(
                isRtl ? '\u202B' + 'الجوائز والتحديات' + '\u202C' : 'Rewards & Challenges',
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 20, 
                  fontWeight: FontWeight.w700
                ),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
              centerTitle: true,
              backgroundColor: const Color(0xFF9A46D7),
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Icon(
                  isRtl ? Icons.arrow_forward : Icons.arrow_back, 
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(isRtl),
              Padding(
                padding: const EdgeInsetsDirectional.all(24.0),
                child: Column(
                  crossAxisAlignment: isRtl 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                  children: [
                    _buildRedeemPointsSection(isRtl),
                    const SizedBox(height: 24),
                    _buildChallengesSection(isRtl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isRtl) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: const Color(0xFF9A46D7),
        width: double.infinity,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 60),
          child: Column(
            children: [
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  StreamBuilder<int>(
                    stream: _pointsService.userPointsStream,
                    builder: (context, snapshot) {
                      final points = snapshot.data ?? 0;
                      return Column(
                        crossAxisAlignment: isRtl 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl ? '\u202B' + 'رصيد نقاط المكافآت' + '\u202C' : 'Rewards Points Balance',
                            style: const TextStyle(
                              fontSize: 14, 
                              color: Color(0xFF637D92)
                            ),
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isRtl ? '\u202B' + '$points نقطة' + '\u202C' : '$points Points',
                            style: const TextStyle(
                              fontSize: 28, 
                              fontWeight: FontWeight.w800, 
                              color: Color(0xFF1D2035)
                            ),
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          ),
                        ],
                      );
                    },
                  ),
                  Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                       shape: BoxShape.circle,
                       color: Color(0xFFC16BFF),
                    ),
                    child: Icon(
                      isRtl ? Icons.receipt : Icons.receipt_long, 
                      color: Colors.white, 
                      size: 35,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  )
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedeemPointsSection(bool isRtl) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: isRtl 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
        children: [
                  Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              width: double.infinity,
              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                isRtl ? '\u202B' + 'أستبدل نقاطك!' + '\u202C' : 'Redeem your points!',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w700,
                  fontFamily: isRtl ? 'Almarai' : null,
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsetsDirectional.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9A46D7)),
          ),
          child: Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Text(
                isRtl ? '\u202B' + 'أستبدال' + '\u202C' : 'Redeem',
                style: const TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w700, 
                  color: Color(0xFF9A46D7)
                ),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: isRtl 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRtl 
                      ? '\u202B' + 'أكمل بيانات ملفك الشخصي' + '\u202C'
                      : 'Complete your profile',
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w700, 
                      color: Color(0xFF1D2035)
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRtl 
                      ? '\u202B' + '500 نقطة = 50 ريال' + '\u202C'
                      : '500 points = 50 SAR',
                    style: const TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w700, 
                      color: Color(0xFF9A46D7)
                    ),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ],
              ),
              SizedBox(width: isRtl ? 16 : 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBD9FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRtl ? Icons.redeem : Icons.card_giftcard,
                  color: const Color(0xFF9A46D7),
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
  
  Widget _buildChallengesSection(bool isRtl) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: isRtl 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
        children: [
        Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            width: double.infinity,
            alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              isRtl ? '\u202B' + 'التحديات' + '\u202C' : 'Challenges',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w700,
                fontFamily: isRtl ? 'Almarai' : null,
              ),
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _pointsService.combinedChallengesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  isRtl ? '\u202B' + 'لا توجد تحديات حالياً.' + '\u202C' : 'No challenges available.',
                  textAlign: TextAlign.center,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                )
              );
            }
            final challenges = snapshot.data!;
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: (186 / 273),
                ),
              itemCount: challenges.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final challengeData = challenges[index];
                final Challenge challenge = challengeData['challenge'];
                final bool isCompleted = challengeData['isCompleted'];
                return _buildChallengeCard(
                  challenge: challenge,
                  reward: isRtl ? '${challenge.reward} نقطة' : '${challenge.reward} Points',
                  isCompleted: isCompleted,
                  imagePath: challenge.imagePath,
                  isRtl: isRtl,
                );
              },
              ),
            );
          },
        )
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required Challenge challenge,
    required String reward,
    required bool isCompleted,
    required String imagePath,
    required bool isRtl,
  }) {
    // Determine image source: Firebase Storage URL or local asset
    bool isNetworkImage = imagePath.isNotEmpty && 
        (imagePath.startsWith('http://') || imagePath.startsWith('https://'));
    
    String defaultAssetImage = isCompleted 
        ? 'assets/images/challenges/challenge_2.png'
        : 'assets/images/challenges/challenge_1.png';
    
    // Debug: print image info
    if (imagePath.isNotEmpty) {
      print('Challenge ${challenge.title}: Using ${isNetworkImage ? "network" : "asset"} image: $imagePath');
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: GestureDetector(
        onTap: isCompleted ? null : () => _showChallengeCompletedModal(challenge),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isCompleted ? const Color(0xFF1ED29C) : const Color(0xFFF6F6F6)
            ),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFDDFAF2) : const Color(0xFFFAF6FE),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    // Challenge image - Firebase Storage or local asset
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(20),
                        child: isNetworkImage
                          ? CachedNetworkImage(
                              imageUrl: imagePath,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF9A46D7),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      isRtl ? 'جاري التحميل...' : 'Loading...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9A46D7),
                                      ),
                                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                    ),
                                  ],
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                print('Error loading challenge image: $url, Error: $error');
                                return Container(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        color: Color(0xFF9A46D7),
                                        size: 32,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        isRtl ? 'تحدي' : 'Challenge',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9A46D7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                );
                              },
                              memCacheWidth: 300,
                              memCacheHeight: 300,
                            )
                          : Image.asset(
                              defaultAssetImage,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading asset image: $defaultAssetImage, Error: $error');
                                return Container(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        color: Color(0xFF9A46D7),
                                        size: 32,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        isRtl ? 'تحدي' : 'Challenge',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9A46D7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ),
                    ),
                    // Status icon
                    PositionedDirectional(
                      top: 11,
                      start: 11,
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.lock,
                        color: isCompleted ? const Color(0xFF12D18E) : const Color(0xFF9A46D7),
                        size: 24,
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(12.0),
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: isRtl 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text(
                      challenge.title,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w700, 
                        color: const Color(0xFF353A62),
                        fontFamily: isRtl ? 'Arabic' : null,
                      ),
                    ),
                    Text(
                      isCompleted 
                        ? (isRtl ? 'مكتمل' : 'Completed')
                        : (isRtl ? 'غير مكتمل بعد' : 'Not completed yet'),
                      style: TextStyle(
                        fontSize: 11, 
                        color: const Color(0xFF727880),
                        fontFamily: isRtl ? 'Arabic' : null,
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    Text(
                      isRtl ? 'الجائزة: $reward' : 'Reward: $reward',
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w700, 
                        color: const Color(0xFF9A46D7),
                        fontFamily: isRtl ? 'Arabic' : null,
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
        ),
      ),
    );
  }

  void _showChallengeCompletedModal(Challenge challenge) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => ChallengeCompletedPage(
        challenge: challenge,
        onReceiveReward: () async {
          await _pointsService.completeChallenge(challenge);
        },
      ),
    );
  }
} 