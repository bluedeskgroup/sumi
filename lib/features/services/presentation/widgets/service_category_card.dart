import 'package:flutter/material.dart';

class ServiceCategoryCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;
  final bool isAsset;

  const ServiceCategoryCard({
    super.key,
    required this.imagePath,
    required this.label,
    required this.onTap,
    this.isAsset = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 75,
            height: 75,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: isAsset
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Color(0xFF353A62),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 