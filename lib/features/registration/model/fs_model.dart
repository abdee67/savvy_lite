class FSModel {
  final int? id;
  final int? fsNumber;
  final int? branch;
  final String? mrcNumber;
  final int? company;
  final String? machineModel;
  final String? tableNumber;
  final String? postfixUpToFour;
  final String? prefixUpToThree;

  const FSModel({
    this.id,
    this.fsNumber,
    this.branch,
    this.mrcNumber,
    this.company,
    this.machineModel,
    this.tableNumber,
    this.postfixUpToFour,
    this.prefixUpToThree,
  });

  factory FSModel.fromMap(Map<String, dynamic> json) {
    return FSModel(
      id: json['id'] as int?,
      fsNumber: json['fs_number'] as int?,
      branch: json['branch'] as int?,
      mrcNumber: json['mrc_number'] as String?,
      company: json['company'] as int?,
      machineModel: json['machine_model'] as String?,
      tableNumber: json['table_number'] as String?,
      postfixUpToFour: json['postfix_up_to_four'] as String?,
      prefixUpToThree: json['prefix_up_to_three'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fs_number': fsNumber,
      'branch': branch,
      'mrc_number': mrcNumber,
      'company': company,
      'machine_model': machineModel,
      'table_number': tableNumber,
      'postfix_up_to_four': postfixUpToFour,
      'prefix_up_to_three': prefixUpToThree,
    };
  }

  FSModel copyWith({
    int? id,
    int? fsNumber,
    int? branch,
    String? mrcNumber,
    int? company,
    String? machineModel,
    String? tableNumber,
    String? postfixUpToFour,
    String? prefixUpToThree,
  }) {
    return FSModel(
      id: id ?? this.id,
      fsNumber: fsNumber ?? this.fsNumber,
      branch: branch ?? this.branch,
      mrcNumber: mrcNumber ?? this.mrcNumber,
      company: company ?? this.company,
      machineModel: machineModel ?? this.machineModel,
      tableNumber: tableNumber ?? this.tableNumber,
      postfixUpToFour: postfixUpToFour ?? this.postfixUpToFour,
      prefixUpToThree: prefixUpToThree ?? this.prefixUpToThree,
    );
  }
}
