/// HealthRecord model
class HealthRecord {
  String? id;
  String memberName;
  String recordType; // checkup, vaccination, medication, etc.
  DateTime date;
  String? description;
  String? doctorName;
  String? medication;
  DateTime? nextVisit;
  List<String>? attachments;

  HealthRecord({
    this.id,
    required this.memberName,
    required this.recordType,
    required this.date,
    this.description,
    this.doctorName,
    this.medication,
    this.nextVisit,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'memberName': memberName,
      'recordType': recordType,
      'date': date.toIso8601String(),
      if (description != null) 'description': description,
      if (doctorName != null) 'doctorName': doctorName,
      if (medication != null) 'medication': medication,
      if (nextVisit != null) 'nextVisit': nextVisit!.toIso8601String(),
      if (attachments != null) 'attachments': attachments,
    };
  }

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['_id'] ?? json['id'],
      memberName: json['memberName'] ?? '',
      recordType: json['recordType'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      description: json['description'],
      doctorName: json['doctorName'],
      medication: json['medication'],
      nextVisit: json['nextVisit'] != null
          ? DateTime.parse(json['nextVisit'])
          : null,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
    );
  }

  HealthRecord copyWith({
    String? id,
    String? memberName,
    String? recordType,
    DateTime? date,
    String? description,
    String? doctorName,
    String? medication,
    DateTime? nextVisit,
    List<String>? attachments,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      memberName: memberName ?? this.memberName,
      recordType: recordType ?? this.recordType,
      date: date ?? this.date,
      description: description ?? this.description,
      doctorName: doctorName ?? this.doctorName,
      medication: medication ?? this.medication,
      nextVisit: nextVisit ?? this.nextVisit,
      attachments: attachments ?? this.attachments,
    );
  }
}
