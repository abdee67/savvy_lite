class SubscriptionManagement {
  final int? id;
  final int? initialSubscriptionBranches;
  final int? initialSubscriptionUsers;
  final double? initialPayment;
  final int? initialSubscriptionDays;
  final int? updatedBy;
  final DateTime? dateUpdated;
  final String? status;
  final String? name;
  final String? description;
  final int? maxStorage;
  final String? features;

  const SubscriptionManagement({
    this.id,
    this.initialSubscriptionBranches,
    this.initialSubscriptionUsers,
    this.initialPayment,
    this.initialSubscriptionDays,
    this.updatedBy,
    this.dateUpdated,
    this.status,
    this.name,
    this.description,
    this.maxStorage,
    this.features,
  });

  factory SubscriptionManagement.fromMap(Map<String, dynamic> map) {
    return SubscriptionManagement(
      id: map['id'],
      initialSubscriptionBranches: map['initial_subscription_branches'],
      initialSubscriptionUsers: map['initial_subscription_users'],
      initialPayment: (map['initial_payment'] as num?)?.toDouble(),
      initialSubscriptionDays: map['initial_subscription_days'],
      updatedBy: map['updated_by'],
      dateUpdated: map['date_updated'] != null
          ? DateTime.tryParse(map['date_updated'])
          : null,
      status: map['status'],
      name: map['name'],
      description: map['description'],
      maxStorage: map['max_storage'],
      features: map['features'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'initial_subscription_branches': initialSubscriptionBranches,
      'initial_subscription_users': initialSubscriptionUsers,
      'initial_payment': initialPayment,
      'initial_subscription_days': initialSubscriptionDays,
      'updated_by': updatedBy,
      'date_updated': dateUpdated?.toIso8601String(),
      'status': status,
      'name': name,
      'description': description,
      'max_storage': maxStorage,
      'features': features,
    };
  }

  SubscriptionManagement copyWith({
    int? id,
    int? initialSubscriptionBranches,
    int? initialSubscriptionUsers,
    double? initialPayment,
    int? initialSubscriptionDays,
    int? updatedBy,
    DateTime? dateUpdated,
    String? status,
    String? name,
    String? description,
    int? maxStorage,
    String? features,
  }) {
    return SubscriptionManagement(
      id: id ?? this.id,
      initialSubscriptionBranches:
          initialSubscriptionBranches ?? this.initialSubscriptionBranches,
      initialSubscriptionUsers:
          initialSubscriptionUsers ?? this.initialSubscriptionUsers,
      initialPayment: initialPayment ?? this.initialPayment,
      initialSubscriptionDays:
          initialSubscriptionDays ?? this.initialSubscriptionDays,
      updatedBy: updatedBy ?? this.updatedBy,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      maxStorage: maxStorage ?? this.maxStorage,
      features: features ?? this.features,
    );
  }
}
