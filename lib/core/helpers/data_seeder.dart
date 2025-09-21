import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sumi/core/helpers/search_helpers.dart';

class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedData() async {
    // To prevent this from running in production or repeatedly,
    // you might want to add more checks here.
    if (!kDebugMode) {
      debugPrint("Data seeding is only allowed in debug mode.");
      return;
    }
    
    debugPrint("Starting data seeding...");
    await _seedServiceProviders();
    await _seedProducts();
    debugPrint("Data seeding finished.");
  }

  Future<void> _seedServiceProviders() async {
    final collectionRef = _firestore.collection('serviceProviders');
    final snapshot = await collectionRef.limit(1).get();
    
    // Only seed if the collection is empty
    if (snapshot.docs.isNotEmpty) {
      debugPrint("Service providers collection is not empty. Skipping seeding.");
      return;
    }

    debugPrint("Seeding service providers...");
    final List<Map<String, dynamic>> providers = [
      {
        'id': 'sp1',
        'name': 'صالون الجمال الراقي',
        'name_en': 'Elegant Beauty Salon',
        'category': 'beauty_salons',
        'specialty': 'قصات شعر وصبغات عصرية',
        'specialty_en': 'Modern haircuts and hair coloring',
        'rating': 4.8,
        'reviewCount': 120,
        'location': 'الرياض، حي العليا',
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/sumi-43979.appspot.com/o/seed%2Fsp1.jpg?alt=media&token=809a4734-70e6-4927-b50a-e245a49930f4'
      },
      {
        'id': 'sp2',
        'name': 'مركز اللمسة المخملية',
        'name_en': 'Velvet Touch Center',
        'category': 'beauty_centers',
        'specialty': 'عناية بالبشرة ومكياج احترافي',
        'specialty_en': 'Skincare and professional makeup',
        'rating': 4.9,
        'reviewCount': 250,
        'location': 'جدة، شارع التحلية',
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/sumi-43979.appspot.com/o/seed%2Fsp2.jpg?alt=media&token=9634d289-4977-44a6-8987-a00632230113'
      },
      {
        'id': 'sp3',
        'name': 'خياطة أم عبدالله',
        'name_en': 'Um Abdullah Tailoring',
        'category': 'tailoring_fashion',
        'specialty': 'تصميم وخياطة فساتين سهرة',
        'specialty_en': 'Designing and tailoring evening dresses',
        'rating': 4.7,
        'reviewCount': 85,
        'location': 'الدمام، حي الشاطئ',
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/sumi-43979.appspot.com/o/seed%2Fsp3.jpg?alt=media&token=1d7a3d9b-136b-4e11-89d1-c30c8227b4f5'
      },
       {
        'id': 'sp4',
        'name': 'نقوش حناء فاطمة',
        'name_en': 'Fatima Henna Arts',
        'category': 'henna_artists',
        'specialty': 'أجمل نقوش الحناء الخليجية والهندية',
        'specialty_en': 'The most beautiful Gulf and Indian henna designs',
        'rating': 4.9,
        'reviewCount': 150,
        'location': 'مكة المكرمة، حي العزيزية',
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/sumi-43979.appspot.com/o/seed%2Fsp4.jpg?alt=media&token=9f582ecb-4890-48e0-a7d1-094d2105156a'
      }
    ];

    for (var providerData in providers) {
      final textForKeywords = '${providerData['name']} ${providerData['name_en']} ${providerData['specialty']} ${providerData['specialty_en']}';
      providerData['searchKeywords'] = generateKeywords(textForKeywords);
      await collectionRef.doc(providerData['id']).set(providerData);
    }
  }

  Future<void> _seedProducts() async {
    final collectionRef = _firestore.collection('products');
    final snapshot = await collectionRef.limit(1).get();
    
    // Only seed if the collection is empty
    if (snapshot.docs.isNotEmpty) {
      debugPrint("Products collection is not empty. Skipping seeding.");
      return;
    }
    
    debugPrint("Seeding products...");
    final List<Map<String, dynamic>> products = [
       {
        'id': 'prod1',
        'name': 'فستان سهرة فاخر',
        'name_en': 'Red Evening Dress',
        'description': 'فستان سهرة طويل بتصميم أنيق ومطرز يدويًا.',
        'description_en': 'A long evening dress in red, elegant design suitable for parties and special occasions.',
        'price': 1200.00,
        'oldPrice': 1500.00,
        'imageUrls': [
            'https://via.placeholder.com/400x400.png?text=Product+1',
            'https://via.placeholder.com/400x400.png?text=Product+2',
          ],
        'category': 'فساتين سهرة',
        'category_en': 'Dresses',
        'merchantId': 'store123',
        'merchantName': 'بوتيك الأناقة',
        'createdAt': Timestamp.now(),
        'stock': 15,
      },
      {
        'id': 'prod2',
        'name': 'حقيبة يد جلدية',
        'name_en': 'Leather Handbag',
        'description': 'حقيبة يد من الجلد الطبيعي مع تفاصيل معدنية ذهبية.',
        'description_en': 'A women\'s handbag made of genuine black leather, medium size and practical for daily use.',
        'price': 450.00,
        'imageUrls': [
            'https://via.placeholder.com/400x400.png?text=Product+3',
          ],
        'category': 'حقائب',
        'category_en': 'Bags',
        'merchantId': 'merchant456',
        'merchantName': 'عالم الحقائب',
        'createdAt': Timestamp.now(),
        'stock': 30,
      },
      {
        'id': 'prod3',
        'name': 'ساعة يد ذهبية',
        'name_en': 'Gold Wristwatch',
        'description': 'ساعة يد نسائية فاخرة بإطار ذهبي وسوار من الستانلس ستيل، مقاومة للماء.',
        'description_en': 'A luxurious women\'s wristwatch with a gold frame and stainless steel strap, water-resistant.',
        'price': 850.0,
        'imageUrls': ['https://firebasestorage.googleapis.com/v0/b/sumi-43979.appspot.com/o/seed%2Fprod3.jpg?alt=media&token=e9f3b589-9a2c-4b68-80f0-8c2020216669'],
        'category': 'اكسسوارات',
        'category_en': 'Accessories',
        'merchantId': 'store789',
        'merchantName': 'بيت الساعات',
        'createdAt': Timestamp.now(),
        'stock': 10,
      }
    ];

    for (var productData in products) {
      final textForKeywords = '${productData['name']} ${productData['name_en']} ${productData['description']} ${productData['description_en']} ${productData['category']} ${productData['category_en']}';
      productData['searchKeywords'] = generateKeywords(textForKeywords);
      await collectionRef.doc(productData['id']).set(productData);
    }
  }
} 