class FSModel {
  final int? id;
  final int? fsNumber;
  final int? branch;
  final String? mrcNumber;
  final int? company;
  final String? prefixUpToThree;
  final String? postfixUpToFour;

  const FSModel({
    this.id,
    this.fsNumber,
    this.branch,
    this.mrcNumber,
    this.company,
    this.prefixUpToThree,
    this.postfixUpToFour,
  });

  factory FSModel.fromMap(Map<String, dynamic> json) {
    return FSModel(
      id: json['id'] as int?,
      fsNumber: json['fs_number'] as int?,
      branch: json['branch'] as int?,
      mrcNumber: json['mrc_number'] as String?,
      company: json['company'] as int?,
      prefixUpToThree: json['prefix_up_to_three'] as String?,
      postfixUpToFour: json['postfix_up_to_four'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fs_number': fsNumber,
      'branch': branch,
      'mrc_number': mrcNumber,
      'company': company,
      'prefix_up_to_three': prefixUpToThree,
      'postfix_up_to_four': postfixUpToFour,
    };
  }

  FSModel copyWith({
    int? id,
    int? fsNumber,
    int? branch,
    String? mrcNumber,
    int? company,
    String? prefixUpToThree,
    String? postfixUpToFour,
  }) {
    return FSModel(
      id: id ?? this.id,
      fsNumber: fsNumber ?? this.fsNumber,
      branch: branch ?? this.branch,
      mrcNumber: mrcNumber ?? this.mrcNumber,
      company: company ?? this.company,
      prefixUpToThree: prefixUpToThree ?? this.prefixUpToThree,
      postfixUpToFour: postfixUpToFour ?? this.postfixUpToFour,
    );
  }
}
