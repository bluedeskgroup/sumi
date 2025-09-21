class CountryModel {
  final String code;
  final String nameAr;
  final String nameEn;
  final String flag;

  const CountryModel({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.flag,
  });

  @override
  String toString() => nameAr;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

class CountryData {
  static const List<CountryModel> arabCountries = [
    CountryModel(
      code: 'SA',
      nameAr: 'السعودية',
      nameEn: 'Saudi Arabia',
      flag: '🇸🇦',
    ),
    CountryModel(
      code: 'AE',
      nameAr: 'الإمارات العربية المتحدة',
      nameEn: 'United Arab Emirates',
      flag: '🇦🇪',
    ),
    CountryModel(
      code: 'QA',
      nameAr: 'قطر',
      nameEn: 'Qatar',
      flag: '🇶🇦',
    ),
    CountryModel(
      code: 'KW',
      nameAr: 'الكويت',
      nameEn: 'Kuwait',
      flag: '🇰🇼',
    ),
    CountryModel(
      code: 'BH',
      nameAr: 'البحرين',
      nameEn: 'Bahrain',
      flag: '🇧🇭',
    ),
    CountryModel(
      code: 'OM',
      nameAr: 'عُمان',
      nameEn: 'Oman',
      flag: '🇴🇲',
    ),
    CountryModel(
      code: 'JO',
      nameAr: 'الأردن',
      nameEn: 'Jordan',
      flag: '🇯🇴',
    ),
    CountryModel(
      code: 'LB',
      nameAr: 'لبنان',
      nameEn: 'Lebanon',
      flag: '🇱🇧',
    ),
    CountryModel(
      code: 'EG',
      nameAr: 'مصر',
      nameEn: 'Egypt',
      flag: '🇪🇬',
    ),
    CountryModel(
      code: 'MA',
      nameAr: 'المغرب',
      nameEn: 'Morocco',
      flag: '🇲🇦',
    ),
    CountryModel(
      code: 'TN',
      nameAr: 'تونس',
      nameEn: 'Tunisia',
      flag: '🇹🇳',
    ),
    CountryModel(
      code: 'DZ',
      nameAr: 'الجزائر',
      nameEn: 'Algeria',
      flag: '🇩🇿',
    ),
    CountryModel(
      code: 'IQ',
      nameAr: 'العراق',
      nameEn: 'Iraq',
      flag: '🇮🇶',
    ),
    CountryModel(
      code: 'SY',
      nameAr: 'سوريا',
      nameEn: 'Syria',
      flag: '🇸🇾',
    ),
    CountryModel(
      code: 'YE',
      nameAr: 'اليمن',
      nameEn: 'Yemen',
      flag: '🇾🇪',
    ),
    CountryModel(
      code: 'PS',
      nameAr: 'فلسطين',
      nameEn: 'Palestine',
      flag: '🇵🇸',
    ),
    CountryModel(
      code: 'LY',
      nameAr: 'ليبيا',
      nameEn: 'Libya',
      flag: '🇱🇾',
    ),
    CountryModel(
      code: 'SD',
      nameAr: 'السودان',
      nameEn: 'Sudan',
      flag: '🇸🇩',
    ),
  ];

  // Get country by name
  static CountryModel? getCountryByName(String name) {
    try {
      return arabCountries.firstWhere(
        (country) => country.nameAr == name || country.nameEn == name,
      );
    } catch (e) {
      return null;
    }
  }

  // Get country by code
  static CountryModel? getCountryByCode(String code) {
    try {
      return arabCountries.firstWhere(
        (country) => country.code == code,
      );
    } catch (e) {
      return null;
    }
  }

  // Get default country (Saudi Arabia)
  static CountryModel get defaultCountry => arabCountries.first;

  // Get country names list
  static List<String> get countryNames => 
      arabCountries.map((country) => country.nameAr).toList();
}
