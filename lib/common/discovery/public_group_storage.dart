import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:nchat_mobile/common/discovery/public_group_discovery.dart';

class PublicGroupCacheEntry {
  final PublicGroupInfo info;
  final String? avatarBase64;

  const PublicGroupCacheEntry({
    required this.info,
    required this.avatarBase64,
  });
}

class PublicGroupStorage {
  static final PublicGroupStorage instance = PublicGroupStorage._();

  PublicGroupStorage._();

  static const _dbName = 'discovery.db';
  static const _dbVersion = 2;
  static const _tableGroups = 'discovery_groups';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableGroups (
            topic_id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            category TEXT,
            subscriber_count INTEGER,
            avatar_path TEXT,
            avatar_base64 TEXT,
            last_seen_at INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tableGroups ADD COLUMN avatar_base64 TEXT',
          );
        }
      },
    );
  }

  Future<void> upsertGroup(
    PublicGroupInfo info, {
    String? avatarBase64,
  }) async {
    final db = await database;
    final existingRows = await db.query(
      _tableGroups,
      where: 'topic_id = ?',
      whereArgs: [info.topicId],
      limit: 1,
    );
    final existing = existingRows.isNotEmpty ? existingRows.first : null;

    final existingName = (existing?['name'] as String?) ?? '';
    final existingDescription = (existing?['description'] as String?) ?? '';
    final existingCategory = (existing?['category'] as String?) ?? 'general';
    final existingSubscriberCount =
        int.tryParse(existing?['subscriber_count']?.toString() ?? '0') ?? 0;
    final existingAvatarPath = existing?['avatar_path'] as String?;
    final existingAvatarBase64 = existing?['avatar_base64'] as String?;

    await db.insert(
      _tableGroups,
      {
        'topic_id': info.topicId,
        'name': info.name.isNotEmpty ? info.name : existingName,
        'description': info.description.isNotEmpty
            ? info.description
            : existingDescription,
        'category': info.category.isNotEmpty ? info.category : existingCategory,
        'subscriber_count': info.subscriberCount > 0
            ? info.subscriberCount
            : existingSubscriberCount,
        'avatar_path': info.avatarPath != null && info.avatarPath!.isNotEmpty
            ? info.avatarPath
            : existingAvatarPath,
        'avatar_base64': avatarBase64 != null && avatarBase64.isNotEmpty
            ? avatarBase64
            : existingAvatarBase64,
        'last_seen_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PublicGroupCacheEntry?> query(String topicId) async {
    final db = await database;
    final rows = await db.query(
      _tableGroups,
      where: 'topic_id = ?',
      whereArgs: [topicId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final info = PublicGroupInfo(
      topicId: row['topic_id'] as String,
      name: (row['name'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      category: (row['category'] as String?) ?? 'general',
      subscriberCount: (row['subscriber_count'] as int?) ?? 0,
      avatarPath: row['avatar_path'] as String?,
    );

    return PublicGroupCacheEntry(
      info: info,
      avatarBase64: row['avatar_base64'] as String?,
    );
  }

  Future<List<PublicGroupCacheEntry>> queryAll() async {
    final db = await database;
    final rows = await db.query(
      _tableGroups,
      orderBy: 'last_seen_at DESC',
    );
    return rows
        .map(
          (row) => PublicGroupCacheEntry(
            info: PublicGroupInfo(
              topicId: row['topic_id'] as String,
              name: (row['name'] as String?) ?? '',
              description: (row['description'] as String?) ?? '',
              category: (row['category'] as String?) ?? 'general',
              subscriberCount: (row['subscriber_count'] as int?) ?? 0,
              avatarPath: row['avatar_path'] as String?,
            ),
            avatarBase64: row['avatar_base64'] as String?,
          ),
        )
        .toList();
  }
}
