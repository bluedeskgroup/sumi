import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumi/features/services/models/service_provider_model.dart';
import 'package:sumi/features/services/presentation/pages/service_provider_profile_page.dart';
import 'package:sumi/features/services/presentation/widgets/provider_card.dart';
import 'package:sumi/features/services/services/services_service.dart';
import 'package:sumi/l10n/app_localizations.dart';

class ProvidersListPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ProvidersListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  final ServicesService _servicesService = ServicesService();
  late Future<List<ServiceProvider>> _providersFuture;
  final TextEditingController _searchController = TextEditingController();
  List<ServiceProvider> _allProviders = [];
  List<ServiceProvider> _filteredProviders = [];
  String _selectedFilter = 'تسويق 🔎';
  bool _isSearching = false;

  final List<String> _filters = [
    'تسويق 🔎',
    'الميكب أرتست',
    'مراكز التجميل',
    'صالونات التجميل',
    'الكل',
  ];

  @override
  void initState() {
    super.initState();
    _providersFuture = _servicesService.getProvidersByCategory(widget.categoryId);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredProviders = _allProviders;
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredProviders = _allProviders
            .where((provider) =>
                provider.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                provider.specialty.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'الكل') {
        _filteredProviders = _allProviders;
      } else {
        // إزالة الإيموجي من الفلتر للبحث
        String cleanFilter = filter.replaceAll(' 🔎', '');
        _filteredProviders = _allProviders
            .where((provider) => 
                provider.specialty.contains(cleanFilter) ||
                provider.category.contains(cleanFilter))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header مع شريط البحث والعنوان
            _buildHeader(isArabic),
            
            // فلاتر الفئات
            _buildCategoryFilters(isArabic),
            
            const SizedBox(height: 16),
            
            // قائمة مقدمي الخدمات
            Expanded(
              child: FutureBuilder<List<ServiceProvider>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                      ),
                    );
          }
          if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic ? 'حدث خطأ في تحميل البيانات' : 'Error loading data',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 16,
                              color: Color(0xFF637D92),
                            ),
                          ),
                        ],
                      ),
                    );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic ? 'لا يوجد مقدمي خدمات في هذا القسم حالياً' : 'No service providers found',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 16,
                              color: Color(0xFF637D92),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  _allProviders = snapshot.data!;
                  if (!_isSearching) {
                    if (_selectedFilter == 'الكل') {
                      _filteredProviders = _allProviders;
                    } else if (_selectedFilter == 'تسويق 🔎') {
                      // تطبيق فلتر التسويق كافتراضي
                      _filteredProviders = _allProviders
                          .where((provider) => 
                              provider.specialty.contains('تسويق') ||
                              provider.category.contains('تسويق'))
                          .toList();
                      // إذا لم توجد نتائج للتسويق، اعرض الكل
                      if (_filteredProviders.isEmpty) {
                        _filteredProviders = _allProviders;
                      }
                    }
                  }

                  return _buildProvidersList(isArabic);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isArabic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: Column(
        children: [
          // شريط العلوي مع العنوان والبحث
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // العنوان والأقرب لك
              Row(
                children: [
                  Text(
                    isArabic ? 'الاقرب لك' : 'Nearest to you',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A46D7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.search,
                    size: 19,
                    color: Color(0xFF9A46D7),
                  ),
                ],
              ),
              
              // العنوان الرئيسي
              Text(
                isArabic ? '🌟 مقدمي الخدمات' : '🌟 Service Providers',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D2035),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // شريط البحث مع الفلتر والرجوع
          Row(
            children: [
              // زر الرجوع
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7EBEF)),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: Color(0xFF1D2035),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // شريط البحث
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7EBEF)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Color(0xFF9A46D7),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: isArabic ? 'ابحثي عن الخدمة المناسبة' : 'Search for the right service',
                            hintStyle: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFCED7DE),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF4A5E6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(bool isArabic) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: isArabic,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: GestureDetector(
              onTap: () => _onFilterChanged(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF9A46D7) : Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFFE7EBEF),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF7991A4),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProvidersList(bool isArabic) {
    final providers = _filteredProviders.isEmpty ? _allProviders : _filteredProviders;
    
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد نتائج للبحث' : 'No search results',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                color: Color(0xFF637D92),
              ),
            ),
          ],
        ),
      );
    }
    
          return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
        return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceProviderProfilePage(provider: provider),
                    ),
                  );
                },
          child: _buildFigmaProviderCard(provider, isArabic),
              );
            },
          );
  }

  Widget _buildFigmaProviderCard(ServiceProvider provider, bool isArabic) {
    // حالة المتجر (مفتوح/مغلق) - محاكاة
    final isOpen = provider.rating > 4.0; // مجرد مثال
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصورة مع التقييم (على اليسار في العربية)
          Container(
            width: 178,
            height: 110,
            margin: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // الصورة
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 178,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF9A46D7).withOpacity(0.3),
                          const Color(0xFFBDBDBD),
                        ],
                      ),
                    ),
                    child: provider.imageUrl.isNotEmpty
                        ? Image.network(
                            provider.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImageFallback();
                            },
                          )
                        : _buildImageFallback(),
                  ),
                ),
                
                // التقييم
                Positioned(
                  bottom: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEED9),
                      borderRadius: BorderRadius.circular(48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 10,
                          color: Color(0xFFFFAA43),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          provider.rating.toString(),
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF313131),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // شارة "مميز" (للمقدمين المميزين)
                if (provider.rating >= 4.8)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEBB69), Color(0xFFF68801)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(11),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            offset: const Offset(0, 8),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Text(
                        isArabic ? 'مميز' : 'Featured',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // النص والتفاصيل (على اليمين في العربية)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // اسم مقدم الخدمة
                  Text(
                    provider.name,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2035),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  
                  const SizedBox(height: 5),
                  
                  // الوصف
                  Text(
                    provider.specialty,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFAAB9C5),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 5),
                  
                  // حالة المتجر والموقع
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // الموقع
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                provider.location,
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9A46D7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFF9A46D7),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 6),
                      
                      // حالة المتجر
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isOpen ? (isArabic ? 'مفتوح الان' : 'Open now') : (isArabic ? 'مغلق الان' : 'Closed now'),
                                  style: TextStyle(
                                    fontFamily: 'Ping AR + LT',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: isOpen ? const Color(0xFF1AB385) : const Color(0xFFE32B3D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: isOpen ? const Color(0xFF1AB385) : const Color(0xFFE32B3D),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 5),
                  
                  // المسافة والفئة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // فئة الخدمة
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF6FE),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                offset: const Offset(0, 8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Text(
                            provider.category,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 7,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9A46D7),
                              height: 1.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // المسافة
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '16.5 كم',
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 7,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF637D92),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isArabic ? 'الاقرب لك' : 'Nearest to you',
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 7,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9A46D7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      width: 178,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9A46D7).withOpacity(0.3),
            const Color(0xFFBDBDBD),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 32,
            color: Colors.white70,
          ),
          SizedBox(height: 4),
          Text(
            'صورة المقدم',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
  }
} 