import 'package:equatable/equatable.dart';

class Company extends Equatable {
  final int? id;
  final String companyName;
  final String? tinNumber;
  final String? phoneNumber1;
  final String? phoneNumber2;
  final String? phoneNumber3;
  final String? emailAddress1;
  final String? emailAddress2;
  final String? city;
  final String? region;
  final String? state;
  final String? country;
  final String? addressLine;
  final String? logoCompany;
  final double? subscriptionFee;
  final int? userLimmit;
  final int? branchLimmit;
  final int? daysLeft;
  final String? woreda;
  final int? categoryCode;
  final int? referredBySalespersonId;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;
  final double? marginRate;
  final String? marginType;
  final int? reorderPoint;
  final int? inventoryPlanner;
  //final bool? isActive;

  const Company({
    this.id,
    required this.companyName,
    this.tinNumber,
    this.phoneNumber1,
    this.phoneNumber2,
    this.phoneNumber3,
    this.emailAddress1,
    this.emailAddress2,
    this.city,
    this.region,
    this.state,
    this.country,
    this.addressLine,
    this.logoCompany,
    this.subscriptionFee,
    this.userLimmit,
    this.branchLimmit,
    this.daysLeft,
    this.woreda,
    this.categoryCode,
    this.referredBySalespersonId,
    this.dateCreated,
    this.dateUpdated,
    this.marginRate,
    this.marginType,
    this.reorderPoint,
    this.inventoryPlanner,
    //this.isActive = true,
  });

  static Company empty() {
    return Company(
      id: 0,
      companyName: '',
      tinNumber: '',
      phoneNumber1: '',
      phoneNumber2: '',
      phoneNumber3: '',
      emailAddress1: '',
      emailAddress2: '',
      city: '',
      region: '',
      state: '',
      addressLine: '',
      logoCompany: '',
      subscriptionFee: 0,
      userLimmit: 0,
      branchLimmit: 0,
      daysLeft: 0,
      woreda: '',
      categoryCode: 0,
      referredBySalespersonId: 0,
      dateCreated: DateTime.now(),
      dateUpdated: DateTime.now(),
      marginRate: 0,
      marginType: '',
      reorderPoint: 0,
      inventoryPlanner: 0,
      // isActive: true,
    );
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    // Helper function to parse dates that could be TEXT or INTEGER
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Company(
      id: map['id'] as int?,
      companyName: map['company_name'] as String,
      tinNumber: map['tin_number'] as String?,
      phoneNumber1: map['phone_number_1'] as String?,
      phoneNumber2: map['phone_number_2'] as String?,
      phoneNumber3: map['phone_number_3'] as String?,
      emailAddress1: map['email_address_1'] as String?,
      emailAddress2: map['email_address_2'] as String?,
      city: map['city'] as String?,
      region: map['region'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      addressLine: map['address_line'] as String?,
      logoCompany: map['logo_company'] as String?,
      subscriptionFee: map['subscription_fee']?.toDouble(),
      userLimmit: map['user_limmit'] as int?,
      branchLimmit: map['branch_limmit'] as int?,
      daysLeft: map['days_left'] as int?,
      woreda: map['woreda'] as String?,
      categoryCode: map['category_code'] as int?,
      referredBySalespersonId: map['referred_by_salesperson_id'] as int?,
      dateCreated: parseDate(map['date_created']),
      dateUpdated: parseDate(map['date_updated']),
      marginRate: map['margin_rate']?.toDouble(),
      marginType: map['margin_type'] as String?,
      reorderPoint: map['reorder_point'] as int?,
      inventoryPlanner: map['inventory_planner'] as int?,
      //  isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'tin_number': tinNumber,
      'phone_number_1': phoneNumber1,
      'phone_number_2': phoneNumber2,
      'phone_number_3': phoneNumber3,
      'email_address_1': emailAddress1,
      'email_address_2': emailAddress2,
      'city': city,
      'region': region,
      'state': state,
      'country': country ?? 'Ethiopia',
      'address_line': addressLine,
      'logo_company': logoCompany,
      'subscription_fee': subscriptionFee,
      'user_limmit': userLimmit,
      'branch_limmit': branchLimmit,
      'days_left': daysLeft,
      'woreda': woreda,
      'category_code': categoryCode,
      'referred_by_salesperson_id': referredBySalespersonId,
      'date_created': dateCreated?.millisecondsSinceEpoch,
      'date_updated': dateUpdated?.millisecondsSinceEpoch,
      'margin_rate': marginRate,
      'margin_type': marginType,
      'reorder_point': reorderPoint,
      'inventory_planner': inventoryPlanner,
      // 'is_active': isActive == true ? 1 : 0,
    };
  }

  Company copyWith({
    int? id,
    String? companyName,
    String? tinNumber,
    String? phoneNumber1,
    String? phoneNumber2,
    String? phoneNumber3,
    String? emailAddress1,
    String? emailAddress2,
    String? city,
    String? region,
    String? state,
    String? country,
    String? addressLine,
    String? logoCompany,
    double? subscriptionFee,
    int? userLimmit,
    int? branchLimmit,
    int? daysLeft,
    String? woreda,
    int? categoryCode,
    int? referredBySalespersonId,
    DateTime? dateCreated,
    DateTime? dateUpdated,
    double? marginRate,
    String? marginType,
    int? reorderPoint,
    int? inventoryPlanner,
    //bool? isActive,
  }) {
    return Company(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      tinNumber: tinNumber ?? this.tinNumber,
      phoneNumber1: phoneNumber1 ?? this.phoneNumber1,
      phoneNumber2: phoneNumber2 ?? this.phoneNumber2,
      phoneNumber3: phoneNumber3 ?? this.phoneNumber3,
      emailAddress1: emailAddress1 ?? this.emailAddress1,
      emailAddress2: emailAddress2 ?? this.emailAddress2,
      city: city ?? this.city,
      region: region ?? this.region,
      state: state ?? this.state,
      country: country ?? this.country,
      addressLine: addressLine ?? this.addressLine,
      logoCompany: logoCompany ?? this.logoCompany,
      subscriptionFee: subscriptionFee ?? this.subscriptionFee,
      userLimmit: userLimmit ?? this.userLimmit,
      branchLimmit: branchLimmit ?? this.branchLimmit,
      daysLeft: daysLeft ?? this.daysLeft,
      woreda: woreda ?? this.woreda,
      categoryCode: categoryCode ?? this.categoryCode,
      referredBySalespersonId:
          referredBySalespersonId ?? this.referredBySalespersonId,
      dateCreated: dateCreated ?? this.dateCreated,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      marginRate: marginRate ?? this.marginRate,
      marginType: marginType ?? this.marginType,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      inventoryPlanner: inventoryPlanner ?? this.inventoryPlanner,
      // isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods
  String get fullAddress {
    final addressParts = [
      addressLine,
      city,
      region,
      state,
      country,
      woreda,
    ].where((part) => part != null && part.isNotEmpty).toList();

    return addressParts.join(', ');
  }

  String get primaryContact {
    return phoneNumber1 ?? emailAddress1 ?? '';
  }

  bool get hasActiveSubscription {
    return daysLeft != null && daysLeft! > 0;
  }

  bool get isNearSubscriptionEnd {
    return daysLeft != null && daysLeft! > 0 && daysLeft! <= 7;
  }

  @override
  List<Object?> get props => [
    id,
    companyName,
    tinNumber,
    phoneNumber1,
    phoneNumber2,
    phoneNumber3,
    emailAddress1,
    emailAddress2,
    city,
    region,
    state,
    country,
    addressLine,
    logoCompany,
    subscriptionFee,
    userLimmit,
    branchLimmit,
    daysLeft,
    woreda,
    categoryCode,
    referredBySalespersonId,
    dateCreated,
    dateUpdated,
    marginRate,
    marginType,
    reorderPoint,
    inventoryPlanner,
    //isActive,
  ];

  @override
  String toString() {
    return 'Company(id: $id, companyName: $companyName, tinNumber: $tinNumber, phoneNumber1: $phoneNumber1, emailAddress1: $emailAddress1, city: $city, country: $country)';
  }
}

// Extension for additional functionality
extension CompanyExtensions on Company {
  Map<String, dynamic> toJson() => toMap();

  // Validation methods
  bool get isValidCompanyName =>
      companyName.isNotEmpty && companyName.length >= 2;

  bool get isValidTinNumber =>
      tinNumber == null || tinNumber!.isEmpty || tinNumber!.length >= 9;

  bool get isValidEmail =>
      emailAddress1 == null ||
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailAddress1!);

  // Business logic methods
  bool canAddMoreUsers(int currentUserCount) {
    return userLimmit == null || currentUserCount < userLimmit!;
  }

  bool canAddMoreBranches(int currentBranchCount) {
    return branchLimmit == null || currentBranchCount < branchLimmit!;
  }

  double? calculateMargin(double costPrice) {
    if (marginRate == null) return null;

    return marginType == 'P'
        ? costPrice *
              (marginRate! / 100) // Percentage
        : marginRate!; // Fixed amount
  }
}

// For creating new companies
class CompanyCreateRequest {
  final String companyName;
  final String? tinNumber;
  final String? phoneNumber1;
  final String? emailAddress1;
  final String? addressLine;
  final String? city;
  final String? country;

  CompanyCreateRequest({
    required this.companyName,
    this.tinNumber,
    this.phoneNumber1,
    this.emailAddress1,
    this.addressLine,
    this.city,
    this.country,
  });

  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'tin_number': tinNumber,
      'phone_number_1': phoneNumber1,
      'email_address_1': emailAddress1,
      'address_line': addressLine,
      'city': city,
      'country': country,
    };
  }
}
