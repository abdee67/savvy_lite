class CompanySubscription {
  final int? id;
  final int? companyId;
  final int? subscriptionId;
  final DateTime? dateSubscribed;
  final DateTime? dateEffective;
  final DateTime? dateExpire;
  final String? status;

  const CompanySubscription({
    this.id,
    this.companyId,
    this.subscriptionId,
    this.dateSubscribed,
    this.dateEffective,
    this.dateExpire,
    this.status,
  });

  factory CompanySubscription.fromMap(Map<String, dynamic> map) {
    return CompanySubscription(
      id: map['id'],
      companyId: map['company_id'],
      subscriptionId: map['subscription_id'],
      dateSubscribed: map['date_subscribed'] != null
          ? DateTime.tryParse(map['date_subscribed'])
          : null,
      dateEffective: map['date_effective'] != null
          ? DateTime.tryParse(map['date_effective'])
          : null,
      dateExpire: map['date_expire'] != null
          ? DateTime.tryParse(map['date_expire'])
          : null,
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'subscription_id': subscriptionId,
      'date_subscribed': dateSubscribed?.toIso8601String(),
      'date_effective': dateEffective?.toIso8601String(),
      'date_expire': dateExpire?.toIso8601String(),
      'status': status,
    };
  }

  CompanySubscription copyWith({
    int? id,
    int? companyId,
    int? subscriptionId,
    DateTime? dateSubscribed,
    DateTime? dateEffective,
    DateTime? dateExpire,
    String? status,
  }) {
    return CompanySubscription(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      dateSubscribed: dateSubscribed ?? this.dateSubscribed,
      dateEffective: dateEffective ?? this.dateEffective,
      dateExpire: dateExpire ?? this.dateExpire,
      status: status ?? this.status,
    );
  }
}
