// ignore_for_file: unnecessary_getters_setters

import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  String? _conversationId;
  bool? _blockFromOther;
  bool? _block;
  String? _deletedId;
  bool? _isDeleted;
  bool? _isMute;
  String? _lastMsg;
  String? _newMsg;
  double? _time;
  ChatUser? _user;

  Conversation({
    String? conversationId,
    bool? blockFromOther,
    bool? block,
    String? deletedId,
    bool? isDeleted,
    bool? isMute,
    String? lastMsg,
    String? newMsg,
    ChatUser? user,
    double? time,
  }) {
    _conversationId = conversationId;
    _blockFromOther = blockFromOther;
    _block = block;
    _deletedId = deletedId;
    _isDeleted = isDeleted;
    _isMute = isMute;
    _lastMsg = lastMsg;
    _newMsg = newMsg;
    _user = user;
    _time = time;
  }

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) return Conversation();
    return Conversation(
      conversationId: data['conversationId']?.toString(),
      blockFromOther: data['blockFromOther'] == true,
      block: data['block'] == true,
      deletedId: data['deletedId']?.toString(),
      isDeleted: data['isDeleted'] == true,
      isMute: data['isMute'] == true,
      lastMsg: data['lastMsg']?.toString() ?? '',
      newMsg: data['newMsg']?.toString(),
      time: (data['time'] as num?)?.toDouble() ??
          (data['time'] is String ? double.tryParse(data['time']) : null),
      user: data['user'] != null ? ChatUser.fromJson(data['user']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (conversationId != null) "conversationId": _conversationId,
      if (blockFromOther != null) "blockFromOther": _blockFromOther,
      if (block != null) "block": _block,
      if (deletedId != null) "deletedId": _deletedId,
      if (isDeleted != null) "isDeleted": _isDeleted,
      if (isMute != null) "isMute": _isMute,
      if (lastMsg != null) "lastMsg": _lastMsg,
      if (newMsg != null) "newMsg": _newMsg,
      if (time != null) "time": _time,
      if (user != null) "user": _user
    };
  }

  Conversation.fromJson(dynamic json) {
    if (json == null) return;
    final map = json is Map ? json : {};
    _conversationId = map["conversationId"]?.toString();
    _blockFromOther = map["blockFromOther"] == true;
    _block = map["block"] == true;
    _deletedId = map["deletedId"]?.toString();
    _isDeleted = map["isDeleted"] == true;
    _isMute = map["isMute"] == true;
    _lastMsg = map["lastMsg"]?.toString() ?? '';
    _newMsg = map["newMsg"]?.toString();
    _time = (map["time"] as num?)?.toDouble() ??
        (map["time"] is String ? double.tryParse(map["time"]) : null);
    _user = map["user"] != null ? ChatUser.fromJson(map["user"]) : null;
  }

  Map<String, Object?> toJson() {
    return {
      "conversationId": _conversationId,
      "blockFromOther": _blockFromOther,
      "block": _block,
      "deletedId": _deletedId,
      "isDeleted": _isDeleted,
      "isMute": _isMute,
      "lastMsg": _lastMsg,
      "newMsg": _newMsg,
      "user": _user?.toJson(),
      "time": _time,
    };
  }

  String? get conversationId => _conversationId;

  void setConversationId(String? con) {
    _conversationId = con;
  }

  bool? get blockFromOther => _blockFromOther;

  bool? get block => _block;

  ChatUser? get user => _user;

  double? get time => _time;

  String? get newMsg => _newMsg;

  String? get lastMsg => _lastMsg;

  bool? get isMute => _isMute;

  bool? get isDeleted => _isDeleted;

  String? get deletedId => _deletedId;
}

class ChatUser {
  String? _age;
  String? _city;
  String? _image;
  String? _userIdentity;
  String? _username;
  bool? _isHost;
  bool? _isNewMsg;
  double? _date;
  int? _userid;

  ChatUser({
    String? age,
    String? city,
    String? image,
    String? userIdentity,
    String? username,
    bool? isHost,
    bool? isNewMsg,
    double? date,
    int? userid,
  }) {
    _age = age;
    _city = city;
    _image = image;
    _userIdentity = userIdentity;
    _username = username;
    _isHost = isHost;
    _isNewMsg = isNewMsg;
    _date = date;
    _userid = userid;
  }

  Map<String, dynamic> toJson() {
    return {
      "age": _age,
      "city": _city,
      "image": _image,
      "userIdentity": _userIdentity,
      "username": _username,
      "isHost": _isHost,
      "isNewMsg": _isNewMsg,
      "date": _date,
      "userid": _userid,
    };
  }

  ChatUser.fromJson(dynamic json) {
    if (json == null) return;
    final map = json is Map ? json : {};
    _age = map["age"]?.toString();
    _city = map["city"]?.toString();
    _image = map["image"]?.toString();
    _userIdentity = map["userIdentity"]?.toString();
    _username = map["username"]?.toString();
    _isHost = map["isHost"] == true;
    _isNewMsg = map["isNewMsg"] == true;
    _date = (map["date"] as num?)?.toDouble() ??
        (map["date"] is String ? double.tryParse(map["date"]) : null);
    _userid = (map["userid"] as num?)?.toInt() ??
        (map["userid"] is String ? int.tryParse(map["userid"]) : null);
  }

  int? get userid => _userid;

  double? get date => _date;

  bool? get isNewMsg => _isNewMsg;

  set isNewMsg(bool? value) {
    _isNewMsg = value;
  }

  set age(String? value) {
    _age = value;
  }

  bool? get isHost => _isHost;

  String? get username => _username;

  String? get userIdentity => _userIdentity;

  String? get image => _image;

  String? get city => _city;

  String? get age => _age;

  set city(String? value) {
    _city = value;
  }

  set image(String? value) {
    _image = value;
  }

  set userIdentity(String? value) {
    _userIdentity = value;
  }

  set username(String? value) {
    _username = value;
  }

  set isHost(bool? value) {
    _isHost = value;
  }

  set date(double? value) {
    _date = value;
  }

  set userid(int? value) {
    _userid = value;
  }
}

class ChatMessage {
  String? _id;
  String? _image;
  String? _video;
  String? _msg;
  String? _msgType;
  double? _time;
  ChatUser? _senderUser;
  List<String>? _notDeletedIdentities;
  bool isSending = false;

  ChatMessage(
      {String? id,
      String? image,
      String? video,
      String? msg,
      String? msgType,
      double? time,
      ChatUser? senderUser,
      List<String>? notDeletedIdentities,
      this.isSending = false}) {
    _id = id;
    _image = image;
    _video = video;
    _msg = msg;
    _msgType = msgType;
    _time = time;
    _senderUser = senderUser;
    _notDeletedIdentities = notDeletedIdentities;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": _id,
      "image": _image,
      "video": _video,
      "msg": _msg,
      "msgType": _msgType,
      "time": _time,
      "senderUser": _senderUser?.toJson(),
      "not_deleted_identities": _notDeletedIdentities?.map((v) => v).toList()
    };
  }

  ChatMessage.fromJson(dynamic json) {
    if (json == null) return;
    final map = json is Map ? json : {};
    _id = map["id"]?.toString();
    _image = map["image"]?.toString();
    _video = map["video"]?.toString();
    _msg = map["msg"]?.toString();
    _msgType = map["msgType"]?.toString();
    _time = (map["time"] as num?)?.toDouble() ??
        (map["time"] is String ? double.tryParse(map["time"]) : null);
    _senderUser =
        map["senderUser"] != null ? ChatUser.fromJson(map["senderUser"]) : null;
    if (map['not_deleted_identities'] != null &&
        map['not_deleted_identities'] is Iterable) {
      _notDeletedIdentities = [];
      for (var v in map['not_deleted_identities']) {
        _notDeletedIdentities?.add(v.toString());
      }
    }
  }

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    List<String> notDeletedIdentities = [];
    if (data?['not_deleted_identities'] != null &&
        data!['not_deleted_identities'] is Iterable) {
      for (var v in data['not_deleted_identities']) {
        notDeletedIdentities.add(v.toString());
      }
    }
    return ChatMessage(
      image: data?['image']?.toString(),
      video: data?['video']?.toString(),
      id: data?['id']?.toString(),
      msg: data?['msg']?.toString(),
      time: (data?['time'] as num?)?.toDouble() ??
          (data?['time'] is String ? double.tryParse(data?['time']) : null),
      msgType: data?['msgType']?.toString(),
      notDeletedIdentities: notDeletedIdentities,
      senderUser: data?["senderUser"] != null
          ? ChatUser.fromJson(data!["senderUser"])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": _id,
      if (image != null) "image": _image,
      if (video != null) "video": _video,
      if (msg != null) "msg": _msg,
      if (msgType != null) "msgType": _msgType,
      if (time != null) "time": _time,
      if (senderUser != null) "senderUser": _senderUser,
      if (notDeletedIdentities != null)
        "not_deleted_identities": _notDeletedIdentities?.map((v) => v).toList()
    };
  }

  String? get video => _video;

  set video(String? value) {
    _video = value;
  }

  List<String>? get notDeletedIdentities => _notDeletedIdentities;

  ChatUser? get senderUser => _senderUser;

  double? get time => _time;

  String? get msgType => _msgType;

  String? get msg => _msg;

  String? get image => _image;

  set image(String? value) {
    _image = value;
  }

  String? get id => _id;
}
