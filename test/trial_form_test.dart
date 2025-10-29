import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:savvy_stock/core/services/onboarding/trial_service.dart';
import 'package:savvy_stock/core/utils/form_validators.dart';
import 'package:savvy_stock/core/widgets/custom_text_Form.dart';
import 'package:savvy_stock/features/onboarding/models/trial_model.dart';
import 'package:savvy_stock/features/onboarding/widgets/language_toggle.dart';

void main() {
  group('TrialFormData Model Tests', () {
    test('should create empty form data', () {
      final formData = TrialFormData();

      expect(formData.fullName, '');
      expect(formData.email, '');
      expect(formData.userType, null);
      expect(formData.isComplete, false);
    });

    test('should validate personal info correctly', () {
      final formData = TrialFormData(
        fullName: 'John Doe',
        email: 'john@example.com',
        phoneNumber: '+1234567890',
      );

      expect(formData.isPersonalInfoValid, true);
    });

    test('should copy with new values', () {
      final original = TrialFormData(fullName: 'John');
      final updated = original.copyWith(email: 'john@example.com');

      expect(updated.fullName, 'John');
      expect(updated.email, 'john@example.com');
      expect(original.email, ''); // Original unchanged
    });

    test('should convert to JSON correctly', () {
      final formData = TrialFormData(
        fullName: 'John Doe',
        email: 'john@example.com',
        userType: 'Individual User',
      );

      final json = formData.toJson();

      expect(json['fullName'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['userType'], 'Individual User');
    });
  });

  group('FormValidators Tests', () {
    test('should validate email correctly', () {
      expect(FormValidators.validateEmail('test@example.com', true), null);
      expect(FormValidators.validateEmail('invalid-email', true), isNotNull);
      expect(FormValidators.validateEmail('', true), isNotNull);
      expect(FormValidators.validateEmail(null, true), isNotNull);
    });

    test('should validate phone correctly', () {
      expect(FormValidators.validatePhone('+1234567890', true), null);
      expect(FormValidators.validatePhone('123-456-7890', true), null);
      expect(FormValidators.validatePhone('invalid', true), isNotNull);
      expect(FormValidators.validatePhone('', true), isNotNull);
    });

    test('should validate password correctly', () {
      expect(FormValidators.validatePassword('password123', true), null);
      expect(
        FormValidators.validatePassword('12345', true),
        isNotNull,
      ); // Too short
      expect(FormValidators.validatePassword('', true), isNotNull);
      expect(FormValidators.validatePassword(null, true), isNotNull);
    });

    test('should validate confirm password correctly', () {
      expect(
        FormValidators.validateConfirmPassword('password', 'password', true),
        null,
      );
      expect(
        FormValidators.validateConfirmPassword('different', 'password', true),
        isNotNull,
      );
      expect(
        FormValidators.validateConfirmPassword('', 'password', true),
        isNotNull,
      );
    });

    test('should validate username correctly', () {
      expect(FormValidators.validateUsername('john_doe', true), null);
      expect(FormValidators.validateUsername('user123', true), null);
      expect(
        FormValidators.validateUsername('ab', true),
        isNotNull,
      ); // Too short
      expect(
        FormValidators.validateUsername('user@name', true),
        isNotNull,
      ); // Invalid chars
      expect(FormValidators.validateUsername('', true), isNotNull);
    });
  });

  group('TrialService Tests', () {
    late TrialService trialService;

    setUp(() {
      trialService = TrialService();
    });

    test('should get business types in English', () {
      final businessTypes = trialService.getBusinessTypes(true);

      expect(businessTypes, isNotEmpty);
      expect(businessTypes, contains('Retail'));
      expect(businessTypes, contains('Manufacturing'));
    });

    test('should get business types in Arabic', () {
      final businessTypes = trialService.getBusinessTypes(false);

      expect(businessTypes, isNotEmpty);
      expect(businessTypes, contains('تجارة تجزئة'));
      expect(businessTypes, contains('تصنيع'));
    });

    test('should get industries in both languages', () {
      final englishIndustries = trialService.getIndustries(true);
      final arabicIndustries = trialService.getIndustries(false);

      expect(englishIndustries.length, arabicIndustries.length);
      expect(englishIndustries, contains('Technology'));
      expect(arabicIndustries, contains('التكنولوجيا'));
    });

    test('should check email availability', () async {
      final isAvailable = await trialService.isEmailAvailable(
        'new@example.com',
      );
      final isUnavailable = await trialService.isEmailAvailable(
        'test@example.com',
      );

      expect(isAvailable, true);
      expect(isUnavailable, false);
    });

    test('should check username availability', () async {
      final isAvailable = await trialService.isUsernameAvailable('newuser');
      final isUnavailable = await trialService.isUsernameAvailable('admin');

      expect(isAvailable, true);
      expect(isUnavailable, false);
    });

    test('should submit trial application', () async {
      final formData = TrialFormData(
        fullName: 'John Doe',
        email: 'john@example.com',
        phoneNumber: '+1234567890',
        username: 'johndoe',
        password: 'password123',
        confirmPassword: 'password123',
        businessName: 'John\'s Business',
        businessType: 'Retail',
        industry: 'Food & Beverage',
        userType: 'Business Owner',
      );

      final result = await trialService.submitTrialApplication(formData);
      expect(result, true);
    });
  });

  group('Widget Tests', () {
    testWidgets('LanguageToggle should toggle language', (
      WidgetTester tester,
    ) async {
      bool isEnglish = true;
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageToggle(
              isEnglish: isEnglish,
              onToggle: () {
                toggleCalled = true;
                isEnglish = !isEnglish;
              },
            ),
          ),
        ),
      );

      // Find and tap the toggle
      final toggleWidget = find.byType(GestureDetector);
      expect(toggleWidget, findsOneWidget);

      await tester.tap(toggleWidget);
      await tester.pump();

      expect(toggleCalled, true);
    });

    testWidgets('CustomTextField should display correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(labelText: 'Test Field', isTablet: false),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Test Field'), findsOneWidget);
    });
  });
}
