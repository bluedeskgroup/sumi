import 'package:flutter/material.dart';
import 'package:sumi/features/services/models/review_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.userAvatarUrl.isNotEmpty
                      ? NetworkImage(review.userAvatarUrl)
                      : null,
                  backgroundColor: Colors.grey[200],
                  radius: 20,
                  child: review.userAvatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeago.format(review.createdAt.toDate(), locale: 'ar'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 18.0,
                  direction: Axis.horizontal,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4
              ),
            ),
          ],
        ),
      ),
    );
  }
} 