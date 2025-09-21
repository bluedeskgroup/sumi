class Challenge {
  final String id;
  final String title;
  final String description;
  final int reward;
  final String imagePath; // Placeholder for now

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.imagePath,
  });

  factory Challenge.fromMap(String id, Map<String, dynamic> data) {
    return Challenge(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reward: data['reward'] ?? 0,
      imagePath: data['imagePath'] ?? '',
    );
  }
}

class UserChallenge {
  final String challengeId;
  final bool isCompleted;
  final DateTime? completedAt;

  UserChallenge({
    required this.challengeId,
    required this.isCompleted,
    this.completedAt,
  });

   factory UserChallenge.fromMap(Map<String, dynamic> data) {
    return UserChallenge(
      challengeId: data['challengeId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt']?.toDate(),
    );
  }
} 