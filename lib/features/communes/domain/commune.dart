class Commune {
  const Commune({
    required this.code,
    required this.name,
    required this.province,
    required this.region,
  });

  final String code;
  final String name;
  final String province;
  final String region;

  factory Commune.fromJson(Map<String, dynamic> json) => Commune(
    code: json['code'] as String,
    name: json['name'] as String,
    province: json['province'] as String,
    region: json['region'] as String,
  );
}
