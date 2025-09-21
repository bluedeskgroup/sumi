class HelpCenterSettings {
  final String? supportEmail;
  final String? supportPhone;
  final String? whatsappNumber;
  final String? telegramLink;
  final String? facebookLink;
  final String? instagramLink;

  const HelpCenterSettings({
    this.supportEmail,
    this.supportPhone,
    this.whatsappNumber,
    this.telegramLink,
    this.facebookLink,
    this.instagramLink,
  });

  factory HelpCenterSettings.fromMap(Map<String, dynamic> data) {
    return HelpCenterSettings(
      supportEmail: data['supportEmail'] as String?,
      supportPhone: data['supportPhone'] as String?,
      whatsappNumber: data['whatsappNumber'] as String?,
      telegramLink: data['telegramLink'] as String?,
      facebookLink: data['facebookLink'] as String?,
      instagramLink: data['instagramLink'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'whatsappNumber': whatsappNumber,
      'telegramLink': telegramLink,
      'facebookLink': facebookLink,
      'instagramLink': instagramLink,
    };
  }
}


