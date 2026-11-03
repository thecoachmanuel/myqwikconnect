import 'package:orange_ui/model/social/post/add_comment.dart';
import 'package:orange_ui/model/user/registration_user.dart';

class Feed {
  Feed({
    bool? status,
    String? message,
    Data? data,
  }) {
    _status = status;
    _message = message;
    _data = data;
  }

  Feed.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  bool? _status;
  String? _message;
  Data? _data;

  bool? get status => _status;
  String? get message => _message;
  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class Data {
  Data({
    List<UserData>? usersStories,
    List<Post>? posts,
    bool? hasMore,
    int? totalCount,
    int? currentPage,
  }) {
    _usersStories = usersStories;
    _posts = posts;
    _hasMore = hasMore;
    _totalCount = totalCount;
    _currentPage = currentPage;
  }

  Data.fromJson(dynamic json) {
    if (json['users_stories'] != null) {
      _usersStories = [];
      json['users_stories'].forEach((v) {
        _usersStories?.add(UserData.fromJson(v));
      });
    }
    if (json['posts'] != null) {
      _posts = [];
      json['posts'].forEach((v) {
        _posts?.add(Post.fromJson(v));
      });
    }
    _hasMore = json['has_more'] as bool?;
    _totalCount = json['total_count'] as int?;
    _currentPage = json['current_page'] as int?;
  }

  List<UserData>? _usersStories;
  List<Post>? _posts;
  bool? _hasMore;
  int? _totalCount;
  int? _currentPage;

  List<UserData>? get usersStories => _usersStories;
  List<Post>? get posts => _posts;
  bool? get hasMore => _hasMore;
  int? get totalCount => _totalCount;
  int? get currentPage => _currentPage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_usersStories != null) {
      map['users_stories'] = _usersStories?.map((v) => v.toJson()).toList();
    }
    if (_posts != null) {
      map['posts'] = _posts?.map((v) => v.toJson()).toList();
    }
    map['has_more'] = _hasMore;
    map['total_count'] = _totalCount;
    map['current_page'] = _currentPage;
    return map;
  }
}
