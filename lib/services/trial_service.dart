import '../models/trial_form_data.dart';

class TrialService {
  static const String _baseUrl = 'https://api.savvystock.com'; // Replace with your API URL
  
  /// Submit trial application to the server
  Future<bool> submitTrialApplication(TrialFormData formData) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Here you would make the actual HTTP request
      // Example using http package:
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl/trial/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData.toJson()),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to submit application: ${response.statusCode}');
      }
      */
      
      // For now, simulate success
      print('Submitting trial application: ${formData.toJson()}');
      return true;
      
    } catch (e) {
      print('Error submitting trial application: $e');
      return false;
    }
  }
  
  /// Validate if email is already registered
  Future<bool> isEmailAvailable(String email) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Here you would check with your backend
      // For now, simulate that some emails are taken
      final unavailableEmails = [
        'test@example.com',
        'admin@savvystock.com',
        'user@test.com',
      ];
      
      return !unavailableEmails.contains(email.toLowerCase());
      
    } catch (e) {
      print('Error checking email availability: $e');
      return true; // Default to available if check fails
    }
  }
  
  /// Validate if username is already taken
  Future<bool> isUsernameAvailable(String username) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Here you would check with your backend
      // For now, simulate that some usernames are taken
      final unavailableUsernames = [
        'admin',
        'test',
        'user',
        'savvystock',
      ];
      
      return !unavailableUsernames.contains(username.toLowerCase());
      
    } catch (e) {
      print('Error checking username availability: $e');
      return true; // Default to available if check fails
    }
  }
  
  /// Get list of available business types
  List<String> getBusinessTypes(bool isEnglish) {
    if (isEnglish) {
      return [
        'Retail',
        'Wholesale',
        'Manufacturing',
        'Services',
        'Restaurant',
        'E-commerce',
        'Healthcare',
        'Education',
        'Technology',
        'Other',
      ];
    } else {
      return [
        'تجارة تجزئة',
        'تجارة جملة',
        'تصنيع',
        'خدمات',
        'مطعم',
        'تجارة إلكترونية',
        'رعاية صحية',
        'تعليم',
        'تكنولوجيا',
        'أخرى',
      ];
    }
  }
  
  /// Get list of available industries
  List<String> getIndustries(bool isEnglish) {
    if (isEnglish) {
      return [
        'Food & Beverage',
        'Fashion & Apparel',
        'Electronics',
        'Automotive',
        'Construction',
        'Healthcare',
        'Education',
        'Technology',
        'Finance',
        'Real Estate',
        'Other',
      ];
    } else {
      return [
        'الأغذية والمشروبات',
        'الأزياء والملابس',
        'الإلكترونيات',
        'السيارات',
        'البناء',
        'الرعاية الصحية',
        'التعليم',
        'التكنولوجيا',
        'المالية',
        'العقارات',
        'أخرى',
      ];
    }
  }
  
  /// Save form data locally (for offline support)
  Future<void> saveFormDataLocally(TrialFormData formData) async {
    try {
      // Here you would use SharedPreferences or local database
      // to save form data for offline access
      print('Saving form data locally: ${formData.toJson()}');
    } catch (e) {
      print('Error saving form data locally: $e');
    }
  }
  
  /// Load saved form data from local storage
  Future<TrialFormData?> loadSavedFormData() async {
    try {
      // Here you would load from SharedPreferences or local database
      // For now, return null (no saved data)
      return null;
    } catch (e) {
      print('Error loading saved form data: $e');
      return null;
    }
  }
}
