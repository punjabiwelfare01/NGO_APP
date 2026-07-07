class NGOProfile {
  final String name;
  final String? tagline;
  final String? registrationNumber;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String? logoUrl;

  const NGOProfile({
    required this.name,
    this.tagline,
    this.registrationNumber,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.logoUrl,
  });

  static const NGOProfile fallback = NGOProfile(
    name: 'Punjabi Welfare Trust',
    tagline: 'Empowering Communities Through Service',
    registrationNumber: '736',
    email: 'Punjabiwelfaretrust99@gmail.com',
    phone: '9211772333, 7834992799',
    address: 'Near Bus Stand, Fatehgarh Sahib, Punjab - 140406',
    website: 'www.punjabihelp.org',
  );

  factory NGOProfile.fromJson(Map<String, dynamic> j) => NGOProfile(
    name: j['name'] as String? ?? 'Punjabi Welfare Trust',
    tagline: j['tagline'] as String?,
    registrationNumber: j['registration_number'] as String?,
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    address: j['address'] as String?,
    website: j['website'] as String?,
    logoUrl: j['logo_url'] as String?,
  );
}
