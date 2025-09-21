import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sumi/features/services/models/review_model.dart';
import 'package:sumi/features/store/models/product_model.dart';
import 'package:sumi/features/store/presentation/pages/cart_page.dart';
import 'package:sumi/features/store/presentation/widgets/product_card.dart';
import 'package:sumi/features/store/services/cart_service.dart';
import 'package:sumi/features/store/services/store_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  final _pageController = PageController();
  bool _isFavorite = false;
  late final _PageNotifier _pageNotifier;
  int _selectedColorIndex = 0;
  int _selectedSizeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageNotifier = _PageNotifier(_pageController);
    _pageController.addListener(() {
      _pageNotifier.value = _pageController.page ?? 0.0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(() {});
    _pageController.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Consumer<CartService>(
            builder: (context, cart, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Share.share('Check out this amazing product: ${widget.product.name}\nFind it on Sumi!');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            _buildProductDetails(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageGallery() {
    return Stack(
      children: [
        SizedBox(
          height: 400,
          child: widget.product.imageUrls.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: widget.product.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Hero(
                      tag: 'product-image-${widget.product.id}',
                      child: Image.network(
                        widget.product.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Image not available', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Images Available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.white54),
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white54),
                    icon: Icon(_isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border),
                    color: _isFavorite ? Colors.red : Colors.black,
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white54),
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      Share.share(
                          'Check out this amazing product: ${widget.product.name}\nFind it on Sumi!');
                    },
                  ),
                ],
              )
            ],
          ),
        ),
        if (widget.product.imageUrls.isNotEmpty && widget.product.imageUrls.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable: _pageNotifier,
                  builder: (context, page, _) {
                    final currentPage = (page.round() + 1)
                        .clamp(1, widget.product.imageUrls.length);
                    return Text(
                      '$currentPage / ${widget.product.imageUrls.length}',
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Container(
      transform: Matrix4.translationValues(0.0, -20.0, 0.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _buildTabs(),
      ),
    );
  }

  Widget _buildTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'نظرة عامة'),
              Tab(text: 'التقييمات'),
            ],
          ),
          SizedBox(
            // Needs a fixed height or to be wrapped in an Expanded
            height: 1200, // Adjust height as needed
            child: TabBarView(
              children: [
                _buildOverviewTab(),
                _buildReviewsSection(), // This will be built out in the next step
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProductHeader(),
          const SizedBox(height: 24),
          _buildColorSelector(),
          const SizedBox(height: 24),
          _buildSizeSelector(),
          const SizedBox(height: 24),
          _buildProductMeta(),
          const SizedBox(height: 24),
          _buildVendorInfo(),
          const SizedBox(height: 24),
          _buildDescription(),
            const SizedBox(height: 24),
          _buildRelatedProducts(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
              widget.product.name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${widget.product.price.toStringAsFixed(2)} ر.س',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.product.oldPrice != null)
                      Text(
                        '${widget.product.oldPrice?.toStringAsFixed(2)} ر.س',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '4.8 (23 التقييم)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              ],
            ),
            _buildQuantitySelector(),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    // Using product data
    final List<int> colorsAsInts = widget.product.colors;
    if (colorsAsInts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اللون:',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colorsAsInts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = Color(colorsAsInts[index]);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorIndex = index;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _selectedColorIndex == index
                        ? Border.all(
                            color: Theme.of(context).primaryColor, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 2))
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    // Using product data
    final List<String> sizes = widget.product.sizes;
    if (sizes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الحجم:',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sizes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSizeIndex = index;
                  });
                },
                child: Container(
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedSizeIndex == index
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedSizeIndex == index
                        ? Border.all(color: Theme.of(context).primaryColor)
                        : null,
                  ),
                  child: Text(
                    sizes[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedSizeIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductMeta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              '673 منتج فى المخزن',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ],
        ),
        TextButton.icon(
          icon:
              Icon(Icons.straighten_outlined, color: Colors.grey.shade700),
          label: Text(
            'دليل المقاسات',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          onPressed: () {},
        )
      ],
    );
  }

  Widget _buildVendorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: widget.product.imageUrls.isNotEmpty
                ? NetworkImage(widget.product.imageUrls.first)
                : null,
            child: widget.product.imageUrls.isEmpty
                ? const Icon(Icons.store, size: 24, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'متجر الفن والجمال',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
            Text(
                            '5.0',
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          Icon(Icons.star, color: Colors.amber, size: 14),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'متجر موثوق به! معدل تقييم مرتفع',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey)
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
          'حول المنتج',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Badges like in Figma
        Wrap(
          spacing: 8.0, // gap between adjacent chips
          runSpacing: 4.0, // gap between lines
          children: [
            Chip(
              avatar: Icon(Icons.verified_outlined,
                  color: Colors.green.shade700),
              label: Text(
                'ضمان الرضا بنسبة 100%',
                style: TextStyle(color: Colors.green.shade800),
              ),
              backgroundColor: Colors.green.shade100,
            ),
            Chip(
              avatar:
                  Icon(Icons.whatshot_outlined, color: Colors.orange.shade700),
              label: Text(
                'المنتج الأكثر مبيعًا',
                style: TextStyle(color: Colors.orange.shade800),
              ),
              backgroundColor: Colors.orange.shade100,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.description,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.remove, size: 20),
          onPressed: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
          ),
          Text('$_quantity', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final reviews = widget.product.reviews;
    if (reviews.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildRatingSummary(),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 32, thickness: 1),
            itemBuilder: (context, index) {
              return _buildReviewCard(reviews[index]);
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            child: const Text('تحميل المزيد'),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRatingRow('5', 0.8),
              _buildRatingRow('4', 0.6),
              _buildRatingRow('3', 0.3),
              _buildRatingRow('2', 0.2),
              _buildRatingRow('1', 0.1),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Text('4.8',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Text('من 5'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(String star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(star),
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(review.userAvatarUrl),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Chip(
                label: const Text('طلبية مؤكدة'),
                backgroundColor: Colors.green.shade100,
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(color: Colors.grey.shade800),
          ),
          const SizedBox(height: 12),
          if (review.imageUrls.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(review.imageUrls[index]),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                label: Text('${review.likes}'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                label: Text('${review.dislikes}'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    return FutureBuilder<List<Product>>(
      future: StoreService().getProducts(limit: 4), // Fetch related products
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final relatedProducts = snapshot.data!
            .where((p) => p.id != widget.product.id)
            .toList();
        
        if (relatedProducts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'منتجات قد تعجبك',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: relatedProducts.length,
                itemBuilder: (context, index) {
                  final product = relatedProducts[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(left: 4, right: 4),
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(product: product),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuantitySelector(),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('أضف للسلة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final cart = Provider.of<CartService>(context, listen: false);
                  cart.addToCart(widget.product, quantity: _quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'تمت إضافة ${widget.product.name} إلى السلة بنجاح!'),
                      action: SnackBarAction(
                        label: 'عرض السلة',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CartPage()),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to convert PageController to a ValueListenable<double>
class _PageNotifier extends ValueNotifier<double> {
  final PageController _pageController;
  _PageNotifier(this._pageController) : super(_pageController.initialPage.toDouble()) {
    attach();
  }

  @override
  void dispose() {
    _pageController.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    value = _pageController.page ?? 0.0;
  }

  void attach() {
    _pageController.addListener(_listener);
  }
}

// Extend PageController to have a ValueListenable<int> for the page
extension on PageController {
  ValueNotifier<double> get pageNotifier => _PageNotifier(this);
} 