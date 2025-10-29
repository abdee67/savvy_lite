class FormValidators {
  static String? validateEmail(String? value, bool isEnglish) {
    if (value == null || value.isEmpty) {
      return isEnglish ? 'Email is required' : 'البريد الإلكتروني مطلوب';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return isEnglish ? 'Enter a valid email' : 'أدخل بريد إلكتروني صحيح';
    }
    
    return null;
  }
  
  static String? validatePhone(String? value, bool isEnglish) {
    if (value == null || value.isEmpty) {
      return isEnglish ? 'Phone number is required' : 'رقم الهاتف مطلوب';
    }
    
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-()]'), ''))) {
      return isEnglish ? 'Enter a valid phone number' : 'أدخل رقم هاتف صحيح';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName, bool isEnglish) {
    if (value == null || value.isEmpty) {
      return isEnglish 
          ? '$fieldName is required' 
          : '$fieldName مطلوب';
    }
    return null;
  }
  
  static String? validatePassword(String? value, bool isEnglish) {
    if (value == null || value.isEmpty) {
      return isEnglish ? 'Password is required' : 'كلمة المرور مطلوبة';
    }
    
    if (value.length < 6) {
      return isEnglish 
          ? 'Password must be at least 6 characters' 
          : 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    
    return null;
  }
  
  static String? validateConfirmPassword(String? value, String password, bool isEnglish) {
    if (value == null || value.isEmpty) {
      return isEnglish ? 'Confirm password is required' : 'تأكيد كلمة المرور مطلوب';
    }
    
    if (value != password) {
      return isEnglish ? 'Passwords do not match' : 'كلمات المرور غير متطابقة';
    }
    
    return null;
  }
  
  static String? validateUsername(String? value, bool isEnglish) {
    if (value == null || value.isEmpty) {
      return isEnglish ? 'Username is required' : 'اسم المستخدم مطلوب';
    }
    
    if (value.length < 3) {
      return isEnglish 
          ? 'Username must be at least 3 characters' 
          : 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return isEnglish 
          ? 'Username can only contain letters, numbers, and underscores' 
          : 'اسم المستخدم يمكن أن يحتوي على أحرف وأرقام وشرطات سفلية فقط';
    }
    
    return null;
  }
}
