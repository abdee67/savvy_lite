// features/sales/services/customer_address_service.dart
import 'package:savvy_stock/features/sales/customer/models/customer_model.dart';

class CustomerAddressService {
  Customer getCustomer(Customer customer) {
    // Combine phone numbers
    final phoneNumbers = _combinePhoneNumbers(customer);

    // Build full address
    final fullAddress = _buildFullAddress(customer);

    return Customer(
      tinNumber: customer.tinNumber ?? '',
      phoneNumber: phoneNumbers,
      country: customer.country ?? '',
      state: customer.state ?? '',
      region: customer.region ?? '',
      city: customer.city ?? '',
      address: fullAddress,
    );
  }

  String _combinePhoneNumbers(Customer customer) {
    final phones = <String>[];

    if (customer.phoneNumber?.isNotEmpty == true) {
      phones.add(customer.phoneNumber!);
    }

    if (customer.phone2?.isNotEmpty == true) {
      phones.add(customer.phone2!);
    }

    return phones.join(', ');
  }

  String _buildFullAddress(Customer customer) {
    final addressParts = <String>[];

    if (customer.address?.isNotEmpty == true) {
      addressParts.add(customer.address!);
    }

    if (customer.city?.isNotEmpty == true) {
      addressParts.add(customer.city!);
    }

    if (customer.region?.isNotEmpty == true) {
      addressParts.add(customer.region!);
    }

    if (customer.state?.isNotEmpty == true) {
      addressParts.add(customer.state!);
    }

    if (customer.country?.isNotEmpty == true) {
      addressParts.add(customer.country!);
    }

    return addressParts.join(', ');
  }

  // Validate customer address completeness
  bool validateAddressCompleteness(Customer customer) {
    return customer.address?.isNotEmpty == true &&
        customer.city?.isNotEmpty == true &&
        customer.country?.isNotEmpty == true;
  }

  // Get shipping address (could be different from billing)
  Customer getShippingAddress({
    required Customer customer,
    Customer? shipToCustomer,
  }) {
    if (shipToCustomer != null) {
      return getCustomer(shipToCustomer);
    }

    // Default to billing address
    return getCustomer(customer);
  }
}
