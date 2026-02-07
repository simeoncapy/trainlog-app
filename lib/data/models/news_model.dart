import 'dart:io';

enum NewsDevice {all, web, app}

class NewsModel {
  final int id;
  final String title;
  final String content;
  final String author;
  final DateTime created;
  final DateTime lastModified;
  final NewsDevice device;
  bool isNew;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.created,
    required this.lastModified,
    this.device = NewsDevice.all,
    this.isNew = false,
  });

  void haveBeenRead() => isNew = false;

  factory NewsModel.fromJson(Map<String, dynamic> json, {DateTime? lastVisit}) {
    final created = HttpDate.parse(json['created']);
    final isNew = lastVisit != null ? created.isAfter(lastVisit) : false;

    return NewsModel(
      id: int.tryParse(json["id"].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      author: json['author_display']?.toString() ?? '',
      created: created.toLocal(),
      lastModified: HttpDate.parse(json['last_modified']).toLocal(),
      isNew: isNew,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_display': author,
      'created': created.toUtc().toIso8601String(),
      'last_modified': lastModified.toUtc().toIso8601String(),
    };
  }
}
