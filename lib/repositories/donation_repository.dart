// ignore_for_file: prefer_null_aware_elements
import '../models/donation_models.dart';
import 'api_client.dart';

class DonationRepository {
  const DonationRepository._();

  static Future<NGOPaymentDetails?> getNGOPaymentDetails() async {
    try {
      final data = await ApiClient.get('/donations/ngo-payment');
      if (data == null) return null;
      return NGOPaymentDetails.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<Donation> submitDonation({
    String? donorName,
    String? donorMobile,
    String? donorEmail,
    required DonationType donationType,
    String? category,
    double amount = 0,
    String? itemsDesc,
    String? purpose,
    String? transactionId,
    String? proofFile,
  }) async {
    final body = <String, dynamic>{
      'donation_type': donationType.name,
      'amount': amount,
    };
    if (donorName != null) body['donor_name'] = donorName;
    if (donorMobile != null) body['donor_mobile'] = donorMobile;
    if (donorEmail != null) body['donor_email'] = donorEmail;
    if (category != null) body['category'] = category;
    if (itemsDesc != null) body['items_desc'] = itemsDesc;
    if (purpose != null) body['purpose'] = purpose;
    if (transactionId != null) body['transaction_id'] = transactionId;
    if (proofFile != null) body['proof_file'] = proofFile;

    final data = await ApiClient.post('/donations', body);
    return Donation.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<Donation>> getMyDonations() async {
    final data = await ApiClient.get('/donations/me') as List<dynamic>;
    return data
        .map((e) => Donation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Donation>> getAllDonations() async {
    final data = await ApiClient.get('/donations') as List<dynamic>;
    return data
        .map((e) => Donation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<StipendRecord>> getMyStipends() async {
    final data =
        await ApiClient.get('/donations/stipends/me') as List<dynamic>;
    return data
        .map((e) => StipendRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
