import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/category_unified_model.dart';

class CategoryCardWidget extends StatelessWidget {
  final CategoryUnifiedModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onToggleFeatured;

  const CategoryCardWidget({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onToggleFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.status == CategoryStatus.active 
                ? const Color(0xFF9A46D7).withOpacity(0.2)
                : const Color(0xFFE7EBEF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Header with status badges
            Row(
              children: [
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFE32B3D),
                      onTap: onDelete,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF9A46D7),
                      onTap: onEdit,
                    ),
                  ],
                ),
                const Spacer(),
                // Status badges
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFFF9800),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'مميز',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (category.isFeatured) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.status == CategoryStatus.active
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : const Color(0xFFE32B3D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.status == CategoryStatus.active ? 'نشط' : 'غير نشط',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: category.status == CategoryStatus.active
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE32B3D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Category info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Category name
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1D2035),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Category description
                      if (category.description.isNotEmpty)
                        Text(
                          category.description,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFF637D92),
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Category type
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: category.type == CategoryType.product
                              ? const Color(0xFF2196F3).withOpacity(0.1)
                              : const Color(0xFF9A46D7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.type == CategoryType.product ? 'منتجات' : 'خدمات',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: category.type == CategoryType.product
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFF9A46D7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              category.type == CategoryType.product
                                  ? Icons.inventory_2
                                  : Icons.build,
                              size: 12,
                              color: category.type == CategoryType.product
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFF9A46D7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Category icon/image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: category.color.isNotEmpty
                        ? Color(int.parse(category.color.replaceAll('#', '0xff')))
                            .withOpacity(0.1)
                        : const Color(0xFF9A46D7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: category.iconUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            category.iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultIcon();
                            },
                          ),
                        )
                      : _buildDefaultIcon(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats row
            Row(
              children: [
                // Quick actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onToggleFeatured,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category.isFeatured ? Icons.star : Icons.star_border,
                          size: 16,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onToggleStatus,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: category.status == CategoryStatus.active
                              ? const Color(0xFFE32B3D).withOpacity(0.1)
                              : const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category.status == CategoryStatus.active
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 16,
                          color: category.status == CategoryStatus.active
                              ? const Color(0xFFE32B3D)
                              : const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Item counts
                Text(
                  '${category.type == CategoryType.product ? category.productCount : category.serviceCount} عنصر',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF637D92),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      category.type == CategoryType.product ? Icons.inventory_2 : Icons.build,
      size: 24,
      color: category.color.isNotEmpty
          ? Color(int.parse(category.color.replaceAll('#', '0xff')))
          : const Color(0xFF9A46D7),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}
