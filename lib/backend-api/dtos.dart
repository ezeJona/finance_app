// Data Transfer Objects (DTOs)

class AppointmentRes {
  AppointmentRes({
    required this.id,
    required this.patientId,
    this.physicianId,
    required this.motive,
    this.specialty,
    required this.status,
    required this.start,
    required this.end,
    this.calendarItemId,
    this.facilityUnitId,
    required this.createdAt,
  });

  int id;
  int patientId;
  int? physicianId;
  String motive;
  String? specialty;
  String status;
  DateTime? start;
  DateTime? end;
  int? calendarItemId;
  int? facilityUnitId;
  DateTime createdAt;

  factory AppointmentRes.fromJson(Map<String, dynamic> json) => AppointmentRes(
    id: json["id"],
    patientId: json["patient_id"],
    physicianId: json["physician_id"],
    motive: json["motive"],
    specialty: json["specialty"],
    status: json["status"],
    start: json["start"] != null ? DateTime.parse(json["start"]) : null,
    end: json["end"] != null ? DateTime.parse(json["end"]) : null,
    calendarItemId: json["calendar_item_id"],
    facilityUnitId: json["facility_unit_id"],
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "patient_id": patientId,
    "physician_id": physicianId,
    "motive": motive,
    "specialty": specialty,
    "status": status,
    "start": start?.toIso8601String(),
    "end": end?.toIso8601String(),
    "calendar_item_id": calendarItemId,
    "facility_unit_id": facilityUnitId,
    "created_at": createdAt.toIso8601String(),
  };

  AppointmentRes copyWith({
    int? id,
    int? patientId,
    int? physicianId,
    String? motive,
    String? specialty,
    String? status,
    DateTime? start,
    DateTime? end,
    int? calendarItemId,
    int? facilityUnitId,
    DateTime? createdAt,
  }) {
    return AppointmentRes(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      physicianId: physicianId ?? this.physicianId,
      motive: motive ?? this.motive,
      specialty: specialty ?? this.specialty,
      status: status ?? this.status,
      start: start ?? this.start,
      end: end ?? this.end,
      calendarItemId: calendarItemId ?? this.calendarItemId,
      facilityUnitId: facilityUnitId ?? this.facilityUnitId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentRes &&
          other.id == id &&
          other.patientId == patientId &&
          other.physicianId == physicianId &&
          other.motive == motive &&
          other.specialty == specialty &&
          other.status == status &&
          other.start == start &&
          other.end == end &&
          other.calendarItemId == calendarItemId &&
          other.facilityUnitId == facilityUnitId &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    patientId,
    physicianId,
    motive,
    specialty,
    status,
    start,
    end,
    calendarItemId,
    facilityUnitId,
    createdAt,
  ]);
}

class AppUserRes {
  AppUserRes({
    required this.id,
    required this.firstName,
    this.secondName,
    required this.firstLastName,
    this.secondLastName,
    this.dateOfBirth,
    this.avatar,
  });

  String id;
  String firstName;
  String? secondName;
  String firstLastName;
  String? secondLastName;
  DateTime? dateOfBirth;
  String? avatar;

  factory AppUserRes.fromJson(Map<String, dynamic> json) => AppUserRes(
    id: json["id"],
    firstName: json["first_name"],
    secondName: json["second_name"],
    firstLastName: json["first_last_name"],
    secondLastName: json["second_last_name"],
    dateOfBirth: json["date_of_birth"] == null
        ? null
        : DateTime.parse(json["date_of_birth"]),
    avatar: json["avatar"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "first_name": firstName,
    "second_name": secondName,
    "first_last_name": firstLastName,
    "second_last_name": secondLastName,
    "date_of_birth": dateOfBirth?.toIso8601String(),
    "avatar": avatar,
  };

  AppUserRes copyWith({
    String? id,
    String? firstName,
    String? secondName,
    String? firstLastName,
    String? secondLastName,
    DateTime? dateOfBirth,
    String? avatar,
  }) {
    return AppUserRes(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      firstLastName: firstLastName ?? this.firstLastName,
      secondLastName: secondLastName ?? this.secondLastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUserRes &&
          other.id == id &&
          other.firstName == firstName &&
          other.secondName == secondName &&
          other.firstLastName == firstLastName &&
          other.secondLastName == secondLastName &&
          other.dateOfBirth == dateOfBirth &&
          other.avatar == avatar;

  @override
  int get hashCode => Object.hashAll([
    id,
    firstName,
    secondName,
    firstLastName,
    secondLastName,
    dateOfBirth,
    avatar,
  ]);
}

class AuthUserRes {
  AuthUserRes({required this.id, required this.email});

  String id;
  String email;

  factory AuthUserRes.fromJson(Map<String, dynamic> json) =>
      AuthUserRes(id: json["id"], email: json["email"]);

  Map<String, dynamic> toJson() => {"id": id, "email": email};

  AuthUserRes copyWith({String? id, String? email}) {
    return AuthUserRes(id: id ?? this.id, email: email ?? this.email);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUserRes && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hashAll([id, email]);
}

class CreateAppointmentReq {
  CreateAppointmentReq({
    required this.patientId,
    required this.motive,
    required this.specialty,
  });

  int patientId;
  String motive;
  String specialty;

  factory CreateAppointmentReq.fromJson(Map<String, dynamic> json) =>
      CreateAppointmentReq(
        patientId: json["patient_id"],
        motive: json["motive"],
        specialty: json["specialty"],
      );

  Map<String, dynamic> toJson() => {
    "patient_id": patientId,
    "motive": motive,
    "specialty": specialty,
  };

  CreateAppointmentReq copyWith({
    int? patientId,
    String? motive,
    String? specialty,
  }) {
    return CreateAppointmentReq(
      patientId: patientId ?? this.patientId,
      motive: motive ?? this.motive,
      specialty: specialty ?? this.specialty,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateAppointmentReq &&
          other.patientId == patientId &&
          other.motive == motive &&
          other.specialty == specialty;

  @override
  int get hashCode => Object.hashAll([patientId, motive, specialty]);
}

class CreateAppUserReq {
  CreateAppUserReq({
    required this.id,
    required this.firstName,
    this.secondName,
    required this.firstLastName,
    this.secondLastName,
    this.dateOfBirth,
  });

  String id;
  String firstName;
  String? secondName;
  String firstLastName;
  String? secondLastName;
  DateTime? dateOfBirth;

  factory CreateAppUserReq.fromJson(Map<String, dynamic> json) =>
      CreateAppUserReq(
        id: json["id"],
        firstName: json["first_name"],
        secondName: json["second_name"],
        firstLastName: json["first_last_name"],
        secondLastName: json["second_last_name"],
        dateOfBirth: json["date_of_birth"] == null
            ? null
            : DateTime.parse(json["date_of_birth"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "first_name": firstName,
    "second_name": secondName,
    "first_last_name": firstLastName,
    "second_last_name": secondLastName,
    "date_of_birth": dateOfBirth?.toIso8601String(),
  };

  CreateAppUserReq copyWith({
    String? id,
    String? firstName,
    String? secondName,
    String? firstLastName,
    String? secondLastName,
    DateTime? dateOfBirth,
  }) {
    return CreateAppUserReq(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      firstLastName: firstLastName ?? this.firstLastName,
      secondLastName: secondLastName ?? this.secondLastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUserRes &&
          other.id == id &&
          other.firstName == firstName &&
          other.secondName == secondName &&
          other.firstLastName == firstLastName &&
          other.secondLastName == secondLastName &&
          other.dateOfBirth == dateOfBirth;

  @override
  int get hashCode => Object.hashAll([
    id,
    firstName,
    secondName,
    firstLastName,
    secondLastName,
    dateOfBirth,
  ]);
}

class CreateBusinessReq {
  CreateBusinessReq({
    required this.userId,
    required this.name,
    this.businessType = 'Personal',
    this.currencyCode = 'NIO',
  });

  String userId;
  String name;
  String businessType;
  String currencyCode;

  factory CreateBusinessReq.fromJson(Map<String, dynamic> json) =>
      CreateBusinessReq(
        userId: json["user_id"],
        name: json["name"],
        businessType: json["business_type"] ?? 'Personal',
        currencyCode: json["currency_code"] ?? 'NIO',
      );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "name": name,
    "business_type": businessType,
    "currency_code": currencyCode,
  };

  CreateBusinessReq copyWith({
    String? userId,
    String? name,
    String? businessType,
    String? currencyCode,
  }) {
    return CreateBusinessReq(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateBusinessReq &&
          other.userId == userId &&
          other.name == name &&
          other.businessType == businessType &&
          other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hashAll([
    userId,
    name,
    businessType,
    currencyCode,
  ]);
}

class FacilityUnitRes {
  FacilityUnitRes({
    required this.id,
    required this.facilityId,
    required this.name,
    this.indications,
  });

  int id;
  int facilityId;
  String name;
  String? indications;

  factory FacilityUnitRes.fromJson(Map<String, dynamic> json) =>
      FacilityUnitRes(
        id: json["id"],
        facilityId: json["facility_id"],
        name: json["name"],
        indications: json["indications"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "facility_id": facilityId,
    "name": name,
    "indications": indications,
  };

  FacilityUnitRes copyWith({
    int? id,
    int? facilityId,
    String? name,
    String? indications,
  }) {
    return FacilityUnitRes(
      id: id ?? this.id,
      facilityId: facilityId ?? this.facilityId,
      name: name ?? this.name,
      indications: indications ?? this.indications,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacilityUnitRes &&
          id == other.id &&
          facilityId == other.facilityId &&
          name == other.name &&
          indications == other.indications;

  @override
  int get hashCode => Object.hashAll([id, facilityId, name, indications]);
}

class HealthcareFacilityRes {
  HealthcareFacilityRes({
    required this.id,
    required this.name,
    required this.servesInss,
    required this.isPublicMinsa,
    required this.address,
    required this.district,
    required this.municipalityId,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  int id;
  String name;
  bool servesInss;
  bool isPublicMinsa;
  String address;
  String district;
  int municipalityId;
  double latitude;
  double longitude;
  String? notes;

  factory HealthcareFacilityRes.fromJson(Map<String, dynamic> json) =>
      HealthcareFacilityRes(
        id: json["id"],
        name: json["name"],
        servesInss: json["serves_inss"],
        isPublicMinsa: json["is_public_minsa"],
        address: json["address"],
        district: json["district"],
        municipalityId: json["municipality_id"],
        latitude: (json["latitude"] as num).toDouble(),
        longitude: (json["longitude"] as num).toDouble(),
        notes: json["notes"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "serves_inss": servesInss,
    "is_public_minsa": isPublicMinsa,
    "address": address,
    "district": district,
    "municipality_id": municipalityId,
    "latitude": latitude,
    "longitude": longitude,
    "notes": notes,
  };

  HealthcareFacilityRes copyWith({
    int? id,
    String? name,
    bool? servesInss,
    bool? isPublicMinsa,
    String? address,
    String? district,
    int? municipalityId,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return HealthcareFacilityRes(
      id: id ?? this.id,
      name: name ?? this.name,
      servesInss: servesInss ?? this.servesInss,
      isPublicMinsa: isPublicMinsa ?? this.isPublicMinsa,
      address: address ?? this.address,
      district: district ?? this.district,
      municipalityId: municipalityId ?? this.municipalityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthcareFacilityRes &&
          other.id == id &&
          other.name == name &&
          other.servesInss == servesInss &&
          other.isPublicMinsa == isPublicMinsa &&
          other.address == address &&
          other.district == district &&
          other.municipalityId == municipalityId &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.notes == notes;

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    name.hashCode,
    servesInss.hashCode,
    isPublicMinsa.hashCode,
    address.hashCode,
    district.hashCode,
    municipalityId.hashCode,
    latitude.hashCode,
    longitude.hashCode,
    notes.hashCode,
  ]);
}

class MunicipalityRes {
  MunicipalityRes({
    required this.id,
    required this.name,
    required this.departmentId,
  });

  int id;
  String name;
  int departmentId;

  factory MunicipalityRes.fromJson(Map<String, dynamic> json) =>
      MunicipalityRes(
        id: json["id"],
        name: json["name"],
        departmentId: json["department_id"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "department_id": departmentId,
  };

  MunicipalityRes copyWith({int? id, String? name, int? departmentId}) {
    return MunicipalityRes(
      id: id ?? this.id,
      name: name ?? this.name,
      departmentId: departmentId ?? this.departmentId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MunicipalityRes &&
          other.id == id &&
          other.name == name &&
          other.departmentId == departmentId;

  @override
  int get hashCode => Object.hashAll([id, name, departmentId]);
}

class BusinessRes {
  BusinessRes({
    required this.id,
    required this.userId,
    required this.name,
    required this.businessType,
    required this.currencyCode,
    required this.isDefault,
  });

  int id;
  String userId;
  String name;
  String businessType;
  String currencyCode;
  bool isDefault;

  factory BusinessRes.fromJson(Map<String, dynamic> json) => BusinessRes(
    id: json["id"],
    userId: json["user_id"],
    name: json["name"],
    businessType: json["business_type"],
    currencyCode: json["currency_code"],
    isDefault: json["is_default"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "name": name,
    "business_type": businessType,
    "currency_code": currencyCode,
    "is_default": isDefault,
  };

  BusinessRes copyWith({
    int? id,
    String? userId,
    String? name,
    String? businessType,
    String? currencyCode,
    bool? isDefault,
  }) {
    return BusinessRes(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      currencyCode: currencyCode ?? this.currencyCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessRes &&
          other.id == id &&
          other.userId == userId &&
          other.name == name &&
          other.businessType == businessType &&
          other.currencyCode == currencyCode &&
          other.isDefault == isDefault;

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    name,
    businessType,
    currencyCode,
    isDefault,
  ]);
}