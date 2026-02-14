class Claim {
  final String? id;
  final String status;
  final String?
      questionsAndAnswers; // JSON string: [{"question":"...", "answer":"..."}]
  final String? adminNotes;
  final String? reviewedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? reviewedAt;
  final ClaimItem? item;
  final ClaimUser? claimant;

  Claim({
    this.id,
    required this.status,
    this.questionsAndAnswers,
    this.adminNotes,
    this.reviewedBy,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.item,
    this.claimant,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id']?.toString(),
      status: json['status'] ?? 'PENDING',
      questionsAndAnswers: json['questionsAndAnswers'],
      adminNotes: json['adminNotes'],
      reviewedBy: json['reviewedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      reviewedAt: json['reviewedAt'],
      item: json['item'] != null ? ClaimItem.fromJson(json['item']) : null,
      claimant: json['claimant'] != null
          ? ClaimUser.fromJson(json['claimant'])
          : null,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending Review';
      case 'UNDER_REVIEW':
        return 'Under Review';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'READY_TO_COLLECT':
        return 'Ready to Collect';
      case 'COLLECTED':
        return 'Item Given';
      default:
        return status;
    }
  }
}

class ClaimItem {
  final String? id;
  final String title;
  final String? category;
  final String? imageUrl;
  final String? type;
  final String? lostFoundLocation;
  final String? description;

  ClaimItem({
    this.id,
    required this.title,
    this.category,
    this.imageUrl,
    this.type,
    this.lostFoundLocation,
    this.description,
  });

  factory ClaimItem.fromJson(Map<String, dynamic> json) {
    return ClaimItem(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      category: json['category']?.toString(),
      imageUrl: json['imageUrl'],
      type: json['type']?.toString(),
      lostFoundLocation: json['lostFoundLocation'],
      description: json['description'],
    );
  }
}

class ClaimUser {
  final int? id;
  final String username;
  final String fullName;
  final String email;
  final String phoneNumber;

  ClaimUser({
    this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory ClaimUser.fromJson(Map<String, dynamic> json) {
    int? userId;
    if (json['id'] is int) {
      userId = json['id'];
    } else if (json['id'] is String) {
      userId = int.tryParse(json['id']);
    }

    return ClaimUser(
      id: userId,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}
