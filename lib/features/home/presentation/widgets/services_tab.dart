import 'package:flutter/material.dart';
import 'package:sumi/features/services/presentation/pages/providers_list_page.dart';
import 'package:sumi/features/services/presentation/widgets/service_category_card.dart';
import 'package:sumi/features/services/services/services_service.dart';
import 'package:sumi/features/store/models/category_model.dart';

class Service {
  final String id;
  final String name;
  final String imagePath;
  final bool isAsset;

  Service({
    required this.id,
    required this.name,
    required this.imagePath,
    this.isAsset = true,
  });
}

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ServicesService servicesService = ServicesService();

    // الأقسام الثابتة
    final List<Service> staticServices = [
      Service(id: 'beauty_salons', name: 'صالونات التجميل', imagePath: 'assets/images/services/beauty_salons.png'),
      Service(id: 'beauty_centers', name: 'مراكز التجميل', imagePath: 'assets/images/services/beauty_centers.png'),
      Service(id: 'makeup_artists', name: 'الميكب أرتست', imagePath: 'assets/images/services/makeup_artists.png'),
      Service(id: 'event_coordinators', name: 'منسقي المناسبات', imagePath: 'assets/images/services/event_coordinators.png'),
      Service(id: 'wedding_photographers', name: 'مصوري الزفاف', imagePath: 'assets/images/services/wedding_photographers.png'),
      Service(id: 'tailoring_fashion', name: 'الخياطة والأزياء', imagePath: 'assets/images/services/tailoring_fashion.png'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 70), // For status bar
              Container(
                width: double.infinity,
                alignment: Alignment.centerRight,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'خدمات سومي 🎀',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1D2035),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // عرض الأقسام (الثابتة والديناميكية)
              StreamBuilder<List<Category>>(
                stream: servicesService.getDynamicServiceCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  // دمج الأقسام الديناميكية مع الثابتة
                  List<Service> allServices = [...staticServices];
                  if (snapshot.hasData) {
                    final dynamicCategories = snapshot.data!;
                    allServices.addAll(dynamicCategories.map((category) => Service(
                      id: category.id,
                      name: category.name,
                      imagePath: category.imageUrl,
                      isAsset: false, //  تحديد أن الصورة من الشبكة
                    )));
                  }
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 22,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: allServices.length,
                    itemBuilder: (context, index) {
                      final service = allServices[index];
                      return ServiceCategoryCard(
                        imagePath: service.imagePath,
                        label: service.name,
                        isAsset: service.isAsset,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProvidersListPage(
                                categoryId: service.id,
                                categoryName: service.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
} 