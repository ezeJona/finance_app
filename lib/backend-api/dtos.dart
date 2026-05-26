// Data Transfer Objects (DTOs)

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
      other is CreateAppUserReq &&
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

class TransactionRes {
  TransactionRes({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    this.description,
    required this.paymentMethod,
    this.contactName,
    required this.category,
    required this.transactionDate,
    required this.createdAt,
  });

  String id;
  int businessId;
  String type; // 'income' or 'expense'
  double amount;
  String? description;
  String paymentMethod;
  String? contactName;
  String category;
  DateTime transactionDate;
  DateTime createdAt;

  factory TransactionRes.fromJson(Map<String, dynamic> json) => TransactionRes(
    id: json["id"],
    businessId: json["business_id"],
    type: json["type"],
    amount: (json["amount"] as num).toDouble(),
    description: json["description"],
    paymentMethod: json["payment_method"],
    contactName: json["contact_name"],
    category: json["category"],
    transactionDate: DateTime.parse(json["transaction_date"]),
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "business_id": businessId,
    "type": type,
    "amount": amount,
    "description": description,
    "payment_method": paymentMethod,
    "contact_name": contactName,
    "category": category,
    "transaction_date": transactionDate.toIso8601String(),
    "created_at": createdAt.toIso8601String(),
  };

  TransactionRes copyWith({
    String? id,
    int? businessId,
    String? type,
    double? amount,
    String? description,
    String? paymentMethod,
    String? contactName,
    String? category,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return TransactionRes(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      contactName: contactName ?? this.contactName,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CreateTransactionReq {
  CreateTransactionReq({
    required this.businessId,
    required this.type,
    required this.amount,
    this.description,
    this.paymentMethod = 'Efectivo',
    this.category = 'General',
    this.contactName,
    DateTime? transactionDate,
  }) : transactionDate = transactionDate ?? DateTime.now();

  int businessId;
  String type;
  double amount;
  String? description;
  String paymentMethod;
  String category;
  String? contactName;
  DateTime transactionDate;

  Map<String, dynamic> toJson() => {
    "business_id": businessId,
    "type": type,
    "amount": amount,
    "description": description,
    "payment_method": paymentMethod,
    "category": category,
    "contact_name": contactName,
    "transaction_date": transactionDate.toIso8601String(),
  };
}

