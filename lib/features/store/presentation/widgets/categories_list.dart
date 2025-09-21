import 'package:flutter/material.dart';
import 'package:sumi/features/store/models/category_model.dart';
import 'package:sumi/features/store/services/store_service.dart';

class CategoriesList extends StatelessWidget {
  final Function(String?) onCategorySelected;
  final String? selectedCategoryId;

  const CategoriesList({
    Key? key,
    required this.onCategorySelected,
    this.selectedCategoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StoreService storeService = StoreService();

    return StreamBuilder<List<Category>>(
      stream: storeService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // لا تعرض شيئًا إذا لم تكن هناك أقسام
        }

        final categories = snapshot.data!;
        
        // إضافة "الكل" كخيار أول
        final allCategory = Category(
          id: '', // استخدام معرف فارغ ليمثل "الكل"
          name: 'الكل',
          imageUrl: '', // لا توجد صورة لـ "الكل"
          description: '',
          type: CategoryType.product,
        );
        
        final displayCategories = [allCategory, ...categories];

        return Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              final isSelected = selectedCategoryId == category.id;
              
              return GestureDetector(
                onTap: () => onCategorySelected(category.id),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                              : null,
                        ),
                        child: category.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  category.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.category, color: Colors.grey);
                                  },
                                ),
                              )
                            : const Icon(Icons.apps, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
} 