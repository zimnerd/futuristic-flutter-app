import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

// User table definition
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().unique()();
  TextColumn get username => text().unique()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get interests => text()(); // JSON string
  IntColumn get age => integer().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get photos => text()(); // JSON string
  TextColumn get location => text().nullable()();
  TextColumn get coordinates => text().nullable()(); // JSON string
  BoolColumn get premium => boolean().withDefault(const Constant(false))();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get profileCompletionPercentage => integer().nullable()();
  DateTimeColumn get lastSeen => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Messages table definition
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text().nullable()();
  TextColumn get content => text()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get metadata => text().nullable()(); // JSON string
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Matches table definition
class Matches extends Table {
  TextColumn get id => text()();
  TextColumn get user1Id => text()();
  TextColumn get user2Id => text()();
  BoolColumn get isMatched => boolean().withDefault(const Constant(false))();
  RealColumn get compatibilityScore =>
      real().withDefault(const Constant(0.0))();
  TextColumn get matchReasons => text().nullable()(); // JSON string
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get matchedAt => dateTime().nullable()();
  DateTimeColumn get rejectedAt => dateTime().nullable()();
  DateTimeColumn get expiredAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Conversations table definition
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get user1Id => text()();
  TextColumn get user2Id => text()();
  TextColumn get lastMessage => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Messages, Matches, Conversations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle database migrations here
        },
      );

  // User operations
  Future<List<User>> getAllUsers() => select(users).get();
  Future<User?> getUserById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<bool> updateUser(String id, UsersCompanion user) =>
      (update(users)..where((u) => u.id.equals(id))).write(user);

  // Message operations
  Future<List<Message>> getConversationMessages(String conversationId) =>
      (select(messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([
              (m) =>
                  OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc)
            ]))
          .get();

  Future<int> insertMessage(MessagesCompanion message) =>
      into(messages).insert(message);

  // Match operations
  Future<List<Match>> getUserMatches(String userId) => (select(matches)
        ..where((m) => m.user1Id.equals(userId) | m.user2Id.equals(userId))
        ..where((m) => m.isMatched.equals(true)))
      .get();

  Future<int> insertMatch(MatchesCompanion match) =>
      into(matches).insert(match);

  // Conversation operations
  Future<List<Conversation>> getUserConversations(String userId) =>
      (select(conversations)
            ..where((c) => c.user1Id.equals(userId) | c.user2Id.equals(userId))
            ..where((c) => c.isActive.equals(true))
            ..orderBy([
              (c) => OrderingTerm(
                  expression: c.lastMessageAt, mode: OrderingMode.desc)
            ]))
          .get();

  Future<int> insertConversation(ConversationsCompanion conversation) =>
      into(conversations).insert(conversation);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pulse_dating.db'));

    // Make sure sqlite3 is loaded on mobile platforms
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
