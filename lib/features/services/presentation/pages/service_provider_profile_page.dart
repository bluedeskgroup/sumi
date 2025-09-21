import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumi/features/auth/services/auth_service.dart';
import 'package:sumi/features/services/models/review_model.dart';
import 'package:sumi/features/services/models/service_provider_model.dart';
import 'package:sumi/features/services/presentation/pages/add_review_page.dart';
import 'package:sumi/features/services/presentation/pages/portfolio_viewer_page.dart';
import 'package:sumi/features/services/presentation/widgets/review_card.dart';
import 'package:sumi/features/services/services/services_service.dart';

class ServiceProviderProfilePage extends StatefulWidget {
  final ServiceProvider provider;

  const ServiceProviderProfilePage({super.key, required this.provider});

  @override
  State<ServiceProviderProfilePage> createState() =>
      _ServiceProviderProfilePageState();
}

class _ServiceProviderProfilePageState extends State<ServiceProviderProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Review>> _reviewsFuture;
  final ServicesService _servicesService = ServicesService();
  final AuthService _authService = AuthService();

  // Portfolio pagination state
  final List<String> _portfolioImages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingPortfolio = false;
  bool _hasMorePortfolio = true;
  DocumentSnapshot? _lastPortfolioDoc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _reviewsFuture = _servicesService.getProviderReviews(widget.provider.id);
    _fetchPortfolio(); // Initial fetch

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchPortfolio();
      }
    });
  }

  Future<void> _fetchPortfolio() async {
    if (_isLoadingPortfolio || !_hasMorePortfolio) return;

    setState(() {
      _isLoadingPortfolio = true;
    });

    final portfolioData = await _servicesService.getProviderPortfolio(
        widget.provider.id,
        lastDoc: _lastPortfolioDoc);
    
    final newImages = portfolioData['imageUrls'] as List<String>;
    final lastDoc = portfolioData['lastDoc'] as DocumentSnapshot?;

    setState(() {
      _portfolioImages.addAll(newImages);
      _lastPortfolioDoc = lastDoc;
      _isLoadingPortfolio = false;
      if (newImages.isEmpty || lastDoc == null) {
        _hasMorePortfolio = false;
      }
    });
  }

  void _refreshReviews() {
    setState(() {
      _reviewsFuture = _servicesService.getProviderReviews(widget.provider.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show a simple contact dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('معلومات التواصل'),
              content: const Text('للحجز والاستفسار، يرجى التواصل عبر:\nالرقم: +966 12 345 6789\nواتساب: +966 12 345 6789'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        },
        label: const Text('احجز الآن'),
        icon: const Icon(Icons.calendar_today),
        backgroundColor: Colors.purple[700],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(widget.provider.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold
                    )),
                background: CachedNetworkImage(
                  imageUrl: widget.provider.imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withAlpha(102),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.provider.rating.toStringAsFixed(1)} (${widget.provider.reviewCount} تقييم)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.provider.specialty,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'عني'),
                Tab(text: 'معرض الأعمال'),
                Tab(text: 'التقييمات'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // About Tab
                  _buildAboutTab(),
                  
                  // Portfolio Tab
                  _buildPortfolioTab(),

                  // Reviews Tab
                  _buildReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عن ${widget.provider.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص أو العديد من النصوص الأخرى إضافة إلى زيادة عدد الحروف التى يولدها التطبيق. إذا كنت تحتاج إلى عدد أكبر من الفقرات يتيح لك مولد النص العربى زيادة عدد الفقرات كما تريد، النص لن يبدو مقسما ولا يحوي أخطاء لغوية، مولد النص العربى مفيد لمصممي المواقع على وجه الخصوص، حيث يحتاج العميل فى كثير من الأحيان أن يطلع على صورة حقيقية لتصميم الموقع.',
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 24),
           const Text(
            'ساعات العمل',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildBusinessHoursRow('الأحد - الخميس', '9:00 ص - 10:00 م'),
          _buildBusinessHoursRow('الجمعة', '2:00 م - 11:00 م'),
          _buildBusinessHoursRow('السبت', 'مغلق'),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontSize: 15, color: Colors.black54)),
          Text(hours, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    if (_portfolioImages.isEmpty && _isLoadingPortfolio) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_portfolioImages.isEmpty && !_hasMorePortfolio) {
      return const Center(child: Text('لا يوجد صور في معرض الأعمال حالياً.'));
    }

    return GridView.builder(
      controller: _scrollController,
      cacheExtent: 1000, 
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _portfolioImages.length + (_hasMorePortfolio ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _portfolioImages.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final imageUrl = _portfolioImages[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PortfolioViewerPage(
                  imageUrls: _portfolioImages,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Hero(
            tag: imageUrl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('لا يوجد تقييمات بعد.'),
                 if (_authService.isUserLoggedIn) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                     onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => AddReviewPage(providerId: widget.provider.id),
                        ),
                      );
                      if (result == true) {
                         _refreshReviews();
                      }
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('كن أول من يضيف تقييمًا'),
                     style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[100],
                      foregroundColor: Colors.purple[800],
                    ),
                  )
                ]
              ],
            ),
          );
        }

        final reviews = snapshot.data!;
        return Column(
          children: [
            if (_authService.isUserLoggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => AddReviewPage(providerId: widget.provider.id),
                      ),
                    );
                    if (result == true) {
                       _refreshReviews();
                    }
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('أضف تقييمك'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                     backgroundColor: Colors.purple[100],
                     foregroundColor: Colors.purple[800],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  return ReviewCard(review: reviews[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
} 