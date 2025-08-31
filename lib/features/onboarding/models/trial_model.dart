class TrialFormData {
  // Personal Information
  String fullName;
  String email;
  String phoneNumber;
  
  // Account Setup
  String username;
  String password;
  String confirmPassword;
  
  // Business Information
  String businessName;
  String businessType;
  String industry;
  
  // User Type
  String? userType;
  
  TrialFormData({
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.username = '',
    this.password = '',
    this.confirmPassword = '',
    this.businessName = '',
    this.businessType = '',
    this.industry = '',
    this.userType,
  });
  
  // Validation methods
  bool get isPersonalInfoValid => 
      fullName.isNotEmpty && 
      email.isNotEmpty && 
      phoneNumber.isNotEmpty;
  
  bool get isAccountSetupValid => 
      username.isNotEmpty && 
      password.isNotEmpty && 
      confirmPassword.isNotEmpty &&
      password == confirmPassword;
  
  bool get isBusinessInfoValid => 
      businessName.isNotEmpty && 
      businessType.isNotEmpty && 
      industry.isNotEmpty;
  
  bool get isComplete => 
      isPersonalInfoValid && 
      isAccountSetupValid && 
      isBusinessInfoValid &&
      userType != null;
  
  // Copy method for immutable updates
  TrialFormData copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? username,
    String? password,
    String? confirmPassword,
    String? businessName,
    String? businessType,
    String? industry,
    String? userType,
  }) {
    return TrialFormData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      industry: industry ?? this.industry,
      userType: userType ?? this.userType,
    );
  }
  
  // Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password,
      'businessName': businessName,
      'businessType': businessType,
      'industry': industry,
      'userType': userType,
    };
  }
}
