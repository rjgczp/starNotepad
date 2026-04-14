// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTopMeta = const VerificationMeta('isTop');
  @override
  late final GeneratedColumn<bool> isTop = GeneratedColumn<bool>(
    'is_top',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_top" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHighlightMeta = const VerificationMeta(
    'isHighlight',
  );
  @override
  late final GeneratedColumn<bool> isHighlight = GeneratedColumn<bool>(
    'is_highlight',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_highlight" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isReminderMeta = const VerificationMeta(
    'isReminder',
  );
  @override
  late final GeneratedColumn<bool> isReminder = GeneratedColumn<bool>(
    'is_reminder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reminder" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtLocalMeta = const VerificationMeta(
    'updatedAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtLocal =
      GeneratedColumn<DateTime>(
        'updated_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _updatedAtRemoteMeta = const VerificationMeta(
    'updatedAtRemote',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtRemote =
      GeneratedColumn<DateTime>(
        'updated_at_remote',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<int> syncState = GeneratedColumn<int>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncState.synced),
  );
  static const VerificationMeta _dirtyFieldsMeta = const VerificationMeta(
    'dirtyFields',
  );
  @override
  late final GeneratedColumn<String> dirtyFields = GeneratedColumn<String>(
    'dirty_fields',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteId,
    uuid,
    title,
    content,
    updatedAt,
    isDirty,
    isDeleted,
    categoryId,
    color,
    icon,
    isTop,
    isHighlight,
    isReminder,
    recordedAt,
    updatedAtLocal,
    updatedAtRemote,
    deletedAt,
    syncState,
    dirtyFields,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('is_top')) {
      context.handle(
        _isTopMeta,
        isTop.isAcceptableOrUnknown(data['is_top']!, _isTopMeta),
      );
    }
    if (data.containsKey('is_highlight')) {
      context.handle(
        _isHighlightMeta,
        isHighlight.isAcceptableOrUnknown(
          data['is_highlight']!,
          _isHighlightMeta,
        ),
      );
    }
    if (data.containsKey('is_reminder')) {
      context.handle(
        _isReminderMeta,
        isReminder.isAcceptableOrUnknown(data['is_reminder']!, _isReminderMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('updated_at_local')) {
      context.handle(
        _updatedAtLocalMeta,
        updatedAtLocal.isAcceptableOrUnknown(
          data['updated_at_local']!,
          _updatedAtLocalMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_remote')) {
      context.handle(
        _updatedAtRemoteMeta,
        updatedAtRemote.isAcceptableOrUnknown(
          data['updated_at_remote']!,
          _updatedAtRemoteMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('dirty_fields')) {
      context.handle(
        _dirtyFieldsMeta,
        dirtyFields.isAcceptableOrUnknown(
          data['dirty_fields']!,
          _dirtyFieldsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      localId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}local_id'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      ),
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      content:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}content'],
          )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isDirty:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_dirty'],
          )!,
      isDeleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_deleted'],
          )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      isTop:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_top'],
          )!,
      isHighlight:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_highlight'],
          )!,
      isReminder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_reminder'],
          )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      ),
      updatedAtLocal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at_local'],
          )!,
      updatedAtRemote: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_remote'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncState:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sync_state'],
          )!,
      dirtyFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dirty_fields'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int localId;
  final int? remoteId;
  final String? uuid;
  final String title;
  final String content;
  final DateTime? updatedAt;
  final bool isDirty;
  final bool isDeleted;
  final int? categoryId;
  final String? color;
  final String? icon;
  final bool isTop;
  final bool isHighlight;
  final bool isReminder;
  final DateTime? recordedAt;
  final DateTime updatedAtLocal;
  final DateTime? updatedAtRemote;
  final DateTime? deletedAt;
  final int syncState;
  final String? dirtyFields;
  const Note({
    required this.localId,
    this.remoteId,
    this.uuid,
    required this.title,
    required this.content,
    this.updatedAt,
    required this.isDirty,
    required this.isDeleted,
    this.categoryId,
    this.color,
    this.icon,
    required this.isTop,
    required this.isHighlight,
    required this.isReminder,
    this.recordedAt,
    required this.updatedAtLocal,
    this.updatedAtRemote,
    this.deletedAt,
    required this.syncState,
    this.dirtyFields,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    if (!nullToAbsent || uuid != null) {
      map['uuid'] = Variable<String>(uuid);
    }
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_top'] = Variable<bool>(isTop);
    map['is_highlight'] = Variable<bool>(isHighlight);
    map['is_reminder'] = Variable<bool>(isReminder);
    if (!nullToAbsent || recordedAt != null) {
      map['recorded_at'] = Variable<DateTime>(recordedAt);
    }
    map['updated_at_local'] = Variable<DateTime>(updatedAtLocal);
    if (!nullToAbsent || updatedAtRemote != null) {
      map['updated_at_remote'] = Variable<DateTime>(updatedAtRemote);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_state'] = Variable<int>(syncState);
    if (!nullToAbsent || dirtyFields != null) {
      map['dirty_fields'] = Variable<String>(dirtyFields);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      localId: Value(localId),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      uuid: uuid == null && nullToAbsent ? const Value.absent() : Value(uuid),
      title: Value(title),
      content: Value(content),
      updatedAt:
          updatedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(updatedAt),
      isDirty: Value(isDirty),
      isDeleted: Value(isDeleted),
      categoryId:
          categoryId == null && nullToAbsent
              ? const Value.absent()
              : Value(categoryId),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isTop: Value(isTop),
      isHighlight: Value(isHighlight),
      isReminder: Value(isReminder),
      recordedAt:
          recordedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(recordedAt),
      updatedAtLocal: Value(updatedAtLocal),
      updatedAtRemote:
          updatedAtRemote == null && nullToAbsent
              ? const Value.absent()
              : Value(updatedAtRemote),
      deletedAt:
          deletedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(deletedAt),
      syncState: Value(syncState),
      dirtyFields:
          dirtyFields == null && nullToAbsent
              ? const Value.absent()
              : Value(dirtyFields),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      localId: serializer.fromJson<int>(json['localId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      uuid: serializer.fromJson<String?>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      isTop: serializer.fromJson<bool>(json['isTop']),
      isHighlight: serializer.fromJson<bool>(json['isHighlight']),
      isReminder: serializer.fromJson<bool>(json['isReminder']),
      recordedAt: serializer.fromJson<DateTime?>(json['recordedAt']),
      updatedAtLocal: serializer.fromJson<DateTime>(json['updatedAtLocal']),
      updatedAtRemote: serializer.fromJson<DateTime?>(json['updatedAtRemote']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncState: serializer.fromJson<int>(json['syncState']),
      dirtyFields: serializer.fromJson<String?>(json['dirtyFields']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'uuid': serializer.toJson<String?>(uuid),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'categoryId': serializer.toJson<int?>(categoryId),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'isTop': serializer.toJson<bool>(isTop),
      'isHighlight': serializer.toJson<bool>(isHighlight),
      'isReminder': serializer.toJson<bool>(isReminder),
      'recordedAt': serializer.toJson<DateTime?>(recordedAt),
      'updatedAtLocal': serializer.toJson<DateTime>(updatedAtLocal),
      'updatedAtRemote': serializer.toJson<DateTime?>(updatedAtRemote),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncState': serializer.toJson<int>(syncState),
      'dirtyFields': serializer.toJson<String?>(dirtyFields),
    };
  }

  Note copyWith({
    int? localId,
    Value<int?> remoteId = const Value.absent(),
    Value<String?> uuid = const Value.absent(),
    String? title,
    String? content,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isDirty,
    bool? isDeleted,
    Value<int?> categoryId = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    bool? isTop,
    bool? isHighlight,
    bool? isReminder,
    Value<DateTime?> recordedAt = const Value.absent(),
    DateTime? updatedAtLocal,
    Value<DateTime?> updatedAtRemote = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncState,
    Value<String?> dirtyFields = const Value.absent(),
  }) => Note(
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    uuid: uuid.present ? uuid.value : this.uuid,
    title: title ?? this.title,
    content: content ?? this.content,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDirty: isDirty ?? this.isDirty,
    isDeleted: isDeleted ?? this.isDeleted,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
    isTop: isTop ?? this.isTop,
    isHighlight: isHighlight ?? this.isHighlight,
    isReminder: isReminder ?? this.isReminder,
    recordedAt: recordedAt.present ? recordedAt.value : this.recordedAt,
    updatedAtLocal: updatedAtLocal ?? this.updatedAtLocal,
    updatedAtRemote:
        updatedAtRemote.present ? updatedAtRemote.value : this.updatedAtRemote,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncState: syncState ?? this.syncState,
    dirtyFields: dirtyFields.present ? dirtyFields.value : this.dirtyFields,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      isTop: data.isTop.present ? data.isTop.value : this.isTop,
      isHighlight:
          data.isHighlight.present ? data.isHighlight.value : this.isHighlight,
      isReminder:
          data.isReminder.present ? data.isReminder.value : this.isReminder,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      updatedAtLocal:
          data.updatedAtLocal.present
              ? data.updatedAtLocal.value
              : this.updatedAtLocal,
      updatedAtRemote:
          data.updatedAtRemote.present
              ? data.updatedAtRemote.value
              : this.updatedAtRemote,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      dirtyFields:
          data.dirtyFields.present ? data.dirtyFields.value : this.dirtyFields,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('categoryId: $categoryId, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isTop: $isTop, ')
          ..write('isHighlight: $isHighlight, ')
          ..write('isReminder: $isReminder, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAtLocal: $updatedAtLocal, ')
          ..write('updatedAtRemote: $updatedAtRemote, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState, ')
          ..write('dirtyFields: $dirtyFields')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    remoteId,
    uuid,
    title,
    content,
    updatedAt,
    isDirty,
    isDeleted,
    categoryId,
    color,
    icon,
    isTop,
    isHighlight,
    isReminder,
    recordedAt,
    updatedAtLocal,
    updatedAtRemote,
    deletedAt,
    syncState,
    dirtyFields,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.content == this.content &&
          other.updatedAt == this.updatedAt &&
          other.isDirty == this.isDirty &&
          other.isDeleted == this.isDeleted &&
          other.categoryId == this.categoryId &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.isTop == this.isTop &&
          other.isHighlight == this.isHighlight &&
          other.isReminder == this.isReminder &&
          other.recordedAt == this.recordedAt &&
          other.updatedAtLocal == this.updatedAtLocal &&
          other.updatedAtRemote == this.updatedAtRemote &&
          other.deletedAt == this.deletedAt &&
          other.syncState == this.syncState &&
          other.dirtyFields == this.dirtyFields);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> localId;
  final Value<int?> remoteId;
  final Value<String?> uuid;
  final Value<String> title;
  final Value<String> content;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDirty;
  final Value<bool> isDeleted;
  final Value<int?> categoryId;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<bool> isTop;
  final Value<bool> isHighlight;
  final Value<bool> isReminder;
  final Value<DateTime?> recordedAt;
  final Value<DateTime> updatedAtLocal;
  final Value<DateTime?> updatedAtRemote;
  final Value<DateTime?> deletedAt;
  final Value<int> syncState;
  final Value<String?> dirtyFields;
  const NotesCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isTop = const Value.absent(),
    this.isHighlight = const Value.absent(),
    this.isReminder = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.updatedAtLocal = const Value.absent(),
    this.updatedAtRemote = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.dirtyFields = const Value.absent(),
  });
  NotesCompanion.insert({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isTop = const Value.absent(),
    this.isHighlight = const Value.absent(),
    this.isReminder = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.updatedAtLocal = const Value.absent(),
    this.updatedAtRemote = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.dirtyFields = const Value.absent(),
  });
  static Insertable<Note> custom({
    Expression<int>? localId,
    Expression<int>? remoteId,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDirty,
    Expression<bool>? isDeleted,
    Expression<int>? categoryId,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<bool>? isTop,
    Expression<bool>? isHighlight,
    Expression<bool>? isReminder,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? updatedAtLocal,
    Expression<DateTime>? updatedAtRemote,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncState,
    Expression<String>? dirtyFields,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (categoryId != null) 'category_id': categoryId,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (isTop != null) 'is_top': isTop,
      if (isHighlight != null) 'is_highlight': isHighlight,
      if (isReminder != null) 'is_reminder': isReminder,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (updatedAtLocal != null) 'updated_at_local': updatedAtLocal,
      if (updatedAtRemote != null) 'updated_at_remote': updatedAtRemote,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncState != null) 'sync_state': syncState,
      if (dirtyFields != null) 'dirty_fields': dirtyFields,
    });
  }

  NotesCompanion copyWith({
    Value<int>? localId,
    Value<int?>? remoteId,
    Value<String?>? uuid,
    Value<String>? title,
    Value<String>? content,
    Value<DateTime?>? updatedAt,
    Value<bool>? isDirty,
    Value<bool>? isDeleted,
    Value<int?>? categoryId,
    Value<String?>? color,
    Value<String?>? icon,
    Value<bool>? isTop,
    Value<bool>? isHighlight,
    Value<bool>? isReminder,
    Value<DateTime?>? recordedAt,
    Value<DateTime>? updatedAtLocal,
    Value<DateTime?>? updatedAtRemote,
    Value<DateTime?>? deletedAt,
    Value<int>? syncState,
    Value<String?>? dirtyFields,
  }) {
    return NotesCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
      categoryId: categoryId ?? this.categoryId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isTop: isTop ?? this.isTop,
      isHighlight: isHighlight ?? this.isHighlight,
      isReminder: isReminder ?? this.isReminder,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAtLocal: updatedAtLocal ?? this.updatedAtLocal,
      updatedAtRemote: updatedAtRemote ?? this.updatedAtRemote,
      deletedAt: deletedAt ?? this.deletedAt,
      syncState: syncState ?? this.syncState,
      dirtyFields: dirtyFields ?? this.dirtyFields,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isTop.present) {
      map['is_top'] = Variable<bool>(isTop.value);
    }
    if (isHighlight.present) {
      map['is_highlight'] = Variable<bool>(isHighlight.value);
    }
    if (isReminder.present) {
      map['is_reminder'] = Variable<bool>(isReminder.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (updatedAtLocal.present) {
      map['updated_at_local'] = Variable<DateTime>(updatedAtLocal.value);
    }
    if (updatedAtRemote.present) {
      map['updated_at_remote'] = Variable<DateTime>(updatedAtRemote.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(syncState.value);
    }
    if (dirtyFields.present) {
      map['dirty_fields'] = Variable<String>(dirtyFields.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('categoryId: $categoryId, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isTop: $isTop, ')
          ..write('isHighlight: $isHighlight, ')
          ..write('isReminder: $isReminder, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAtLocal: $updatedAtLocal, ')
          ..write('updatedAtRemote: $updatedAtRemote, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState, ')
          ..write('dirtyFields: $dirtyFields')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtLocalMeta = const VerificationMeta(
    'updatedAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtLocal =
      GeneratedColumn<DateTime>(
        'updated_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _updatedAtRemoteMeta = const VerificationMeta(
    'updatedAtRemote',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtRemote =
      GeneratedColumn<DateTime>(
        'updated_at_remote',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<int> syncState = GeneratedColumn<int>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncState.synced),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteId,
    name,
    color,
    icon,
    updatedAtLocal,
    updatedAtRemote,
    deletedAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('updated_at_local')) {
      context.handle(
        _updatedAtLocalMeta,
        updatedAtLocal.isAcceptableOrUnknown(
          data['updated_at_local']!,
          _updatedAtLocalMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_remote')) {
      context.handle(
        _updatedAtRemoteMeta,
        updatedAtRemote.isAcceptableOrUnknown(
          data['updated_at_remote']!,
          _updatedAtRemoteMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      localId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}local_id'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      updatedAtLocal:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at_local'],
          )!,
      updatedAtRemote: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_remote'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncState:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sync_state'],
          )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int localId;
  final int? remoteId;
  final String name;
  final String? color;
  final String? icon;
  final DateTime updatedAtLocal;
  final DateTime? updatedAtRemote;
  final DateTime? deletedAt;
  final int syncState;
  const Category({
    required this.localId,
    this.remoteId,
    required this.name,
    this.color,
    this.icon,
    required this.updatedAtLocal,
    this.updatedAtRemote,
    this.deletedAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['updated_at_local'] = Variable<DateTime>(updatedAtLocal);
    if (!nullToAbsent || updatedAtRemote != null) {
      map['updated_at_remote'] = Variable<DateTime>(updatedAtRemote);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_state'] = Variable<int>(syncState);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      localId: Value(localId),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      updatedAtLocal: Value(updatedAtLocal),
      updatedAtRemote:
          updatedAtRemote == null && nullToAbsent
              ? const Value.absent()
              : Value(updatedAtRemote),
      deletedAt:
          deletedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(deletedAt),
      syncState: Value(syncState),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      localId: serializer.fromJson<int>(json['localId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      updatedAtLocal: serializer.fromJson<DateTime>(json['updatedAtLocal']),
      updatedAtRemote: serializer.fromJson<DateTime?>(json['updatedAtRemote']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncState: serializer.fromJson<int>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'updatedAtLocal': serializer.toJson<DateTime>(updatedAtLocal),
      'updatedAtRemote': serializer.toJson<DateTime?>(updatedAtRemote),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncState': serializer.toJson<int>(syncState),
    };
  }

  Category copyWith({
    int? localId,
    Value<int?> remoteId = const Value.absent(),
    String? name,
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    DateTime? updatedAtLocal,
    Value<DateTime?> updatedAtRemote = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncState,
  }) => Category(
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
    updatedAtLocal: updatedAtLocal ?? this.updatedAtLocal,
    updatedAtRemote:
        updatedAtRemote.present ? updatedAtRemote.value : this.updatedAtRemote,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncState: syncState ?? this.syncState,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      updatedAtLocal:
          data.updatedAtLocal.present
              ? data.updatedAtLocal.value
              : this.updatedAtLocal,
      updatedAtRemote:
          data.updatedAtRemote.present
              ? data.updatedAtRemote.value
              : this.updatedAtRemote,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('updatedAtLocal: $updatedAtLocal, ')
          ..write('updatedAtRemote: $updatedAtRemote, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    remoteId,
    name,
    color,
    icon,
    updatedAtLocal,
    updatedAtRemote,
    deletedAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.updatedAtLocal == this.updatedAtLocal &&
          other.updatedAtRemote == this.updatedAtRemote &&
          other.deletedAt == this.deletedAt &&
          other.syncState == this.syncState);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> localId;
  final Value<int?> remoteId;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<DateTime> updatedAtLocal;
  final Value<DateTime?> updatedAtRemote;
  final Value<DateTime?> deletedAt;
  final Value<int> syncState;
  const CategoriesCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.updatedAtLocal = const Value.absent(),
    this.updatedAtRemote = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.updatedAtLocal = const Value.absent(),
    this.updatedAtRemote = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? localId,
    Expression<int>? remoteId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<DateTime>? updatedAtLocal,
    Expression<DateTime>? updatedAtRemote,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncState,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (updatedAtLocal != null) 'updated_at_local': updatedAtLocal,
      if (updatedAtRemote != null) 'updated_at_remote': updatedAtRemote,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncState != null) 'sync_state': syncState,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? localId,
    Value<int?>? remoteId,
    Value<String>? name,
    Value<String?>? color,
    Value<String?>? icon,
    Value<DateTime>? updatedAtLocal,
    Value<DateTime?>? updatedAtRemote,
    Value<DateTime?>? deletedAt,
    Value<int>? syncState,
  }) {
    return CategoriesCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      updatedAtLocal: updatedAtLocal ?? this.updatedAtLocal,
      updatedAtRemote: updatedAtRemote ?? this.updatedAtRemote,
      deletedAt: deletedAt ?? this.deletedAt,
      syncState: syncState ?? this.syncState,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (updatedAtLocal.present) {
      map['updated_at_local'] = Variable<DateTime>(updatedAtLocal.value);
    }
    if (updatedAtRemote.present) {
      map['updated_at_remote'] = Variable<DateTime>(updatedAtRemote.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(syncState.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('updatedAtLocal: $updatedAtLocal, ')
          ..write('updatedAtRemote: $updatedAtRemote, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityLocalIdMeta = const VerificationMeta(
    'entityLocalId',
  );
  @override
  late final GeneratedColumn<int> entityLocalId = GeneratedColumn<int>(
    'entity_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityLocalId,
    op,
    payload,
    retryCount,
    nextRetryAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_local_id')) {
      context.handle(
        _entityLocalIdMeta,
        entityLocalId.isAcceptableOrUnknown(
          data['entity_local_id']!,
          _entityLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityLocalIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      entityType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}entity_type'],
          )!,
      entityLocalId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}entity_local_id'],
          )!,
      op:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}op'],
          )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      retryCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}retry_count'],
          )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entityType;
  final int entityLocalId;
  final String op;
  final String? payload;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.entityLocalId,
    required this.op,
    this.payload,
    required this.retryCount,
    this.nextRetryAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_local_id'] = Variable<int>(entityLocalId);
    map['op'] = Variable<String>(op);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityLocalId: Value(entityLocalId),
      op: Value(op),
      payload:
          payload == null && nullToAbsent
              ? const Value.absent()
              : Value(payload),
      retryCount: Value(retryCount),
      nextRetryAt:
          nextRetryAt == null && nullToAbsent
              ? const Value.absent()
              : Value(nextRetryAt),
      lastError:
          lastError == null && nullToAbsent
              ? const Value.absent()
              : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityLocalId: serializer.fromJson<int>(json['entityLocalId']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String?>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityLocalId': serializer.toJson<int>(entityLocalId),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String?>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? entityType,
    int? entityLocalId,
    String? op,
    Value<String?> payload = const Value.absent(),
    int? retryCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityLocalId: entityLocalId ?? this.entityLocalId,
    op: op ?? this.op,
    payload: payload.present ? payload.value : this.payload,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityLocalId:
          data.entityLocalId.present
              ? data.entityLocalId.value
              : this.entityLocalId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityLocalId,
    op,
    payload,
    retryCount,
    nextRetryAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityLocalId == this.entityLocalId &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<int> entityLocalId;
  final Value<String> op;
  final Value<String?> payload;
  final Value<int> retryCount;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityLocalId = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required int entityLocalId,
    required String op,
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : entityType = Value(entityType),
       entityLocalId = Value(entityLocalId),
       op = Value(op);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<int>? entityLocalId,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityLocalId != null) 'entity_local_id': entityLocalId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<int>? entityLocalId,
    Value<String>? op,
    Value<String?>? payload,
    Value<int>? retryCount,
    Value<DateTime?>? nextRetryAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityLocalId: entityLocalId ?? this.entityLocalId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityLocalId.present) {
      map['entity_local_id'] = Variable<int>(entityLocalId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    categories,
    syncQueue,
  ];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> localId,
      Value<int?> remoteId,
      Value<String?> uuid,
      Value<String> title,
      Value<String> content,
      Value<DateTime?> updatedAt,
      Value<bool> isDirty,
      Value<bool> isDeleted,
      Value<int?> categoryId,
      Value<String?> color,
      Value<String?> icon,
      Value<bool> isTop,
      Value<bool> isHighlight,
      Value<bool> isReminder,
      Value<DateTime?> recordedAt,
      Value<DateTime> updatedAtLocal,
      Value<DateTime?> updatedAtRemote,
      Value<DateTime?> deletedAt,
      Value<int> syncState,
      Value<String?> dirtyFields,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> localId,
      Value<int?> remoteId,
      Value<String?> uuid,
      Value<String> title,
      Value<String> content,
      Value<DateTime?> updatedAt,
      Value<bool> isDirty,
      Value<bool> isDeleted,
      Value<int?> categoryId,
      Value<String?> color,
      Value<String?> icon,
      Value<bool> isTop,
      Value<bool> isHighlight,
      Value<bool> isReminder,
      Value<DateTime?> recordedAt,
      Value<DateTime> updatedAtLocal,
      Value<DateTime?> updatedAtRemote,
      Value<DateTime?> deletedAt,
      Value<int> syncState,
      Value<String?> dirtyFields,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHighlight => $composableBuilder(
    column: $table.isHighlight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReminder => $composableBuilder(
    column: $table.isReminder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtRemote => $composableBuilder(
    column: $table.updatedAtRemote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dirtyFields => $composableBuilder(
    column: $table.dirtyFields,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHighlight => $composableBuilder(
    column: $table.isHighlight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReminder => $composableBuilder(
    column: $table.isReminder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtRemote => $composableBuilder(
    column: $table.updatedAtRemote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dirtyFields => $composableBuilder(
    column: $table.dirtyFields,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isTop =>
      $composableBuilder(column: $table.isTop, builder: (column) => column);

  GeneratedColumn<bool> get isHighlight => $composableBuilder(
    column: $table.isHighlight,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isReminder => $composableBuilder(
    column: $table.isReminder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtRemote => $composableBuilder(
    column: $table.updatedAtRemote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get dirtyFields => $composableBuilder(
    column: $table.dirtyFields,
    builder: (column) => column,
  );
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String?> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<bool> isHighlight = const Value.absent(),
                Value<bool> isReminder = const Value.absent(),
                Value<DateTime?> recordedAt = const Value.absent(),
                Value<DateTime> updatedAtLocal = const Value.absent(),
                Value<DateTime?> updatedAtRemote = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncState = const Value.absent(),
                Value<String?> dirtyFields = const Value.absent(),
              }) => NotesCompanion(
                localId: localId,
                remoteId: remoteId,
                uuid: uuid,
                title: title,
                content: content,
                updatedAt: updatedAt,
                isDirty: isDirty,
                isDeleted: isDeleted,
                categoryId: categoryId,
                color: color,
                icon: icon,
                isTop: isTop,
                isHighlight: isHighlight,
                isReminder: isReminder,
                recordedAt: recordedAt,
                updatedAtLocal: updatedAtLocal,
                updatedAtRemote: updatedAtRemote,
                deletedAt: deletedAt,
                syncState: syncState,
                dirtyFields: dirtyFields,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String?> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<bool> isHighlight = const Value.absent(),
                Value<bool> isReminder = const Value.absent(),
                Value<DateTime?> recordedAt = const Value.absent(),
                Value<DateTime> updatedAtLocal = const Value.absent(),
                Value<DateTime?> updatedAtRemote = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncState = const Value.absent(),
                Value<String?> dirtyFields = const Value.absent(),
              }) => NotesCompanion.insert(
                localId: localId,
                remoteId: remoteId,
                uuid: uuid,
                title: title,
                content: content,
                updatedAt: updatedAt,
                isDirty: isDirty,
                isDeleted: isDeleted,
                categoryId: categoryId,
                color: color,
                icon: icon,
                isTop: isTop,
                isHighlight: isHighlight,
                isReminder: isReminder,
                recordedAt: recordedAt,
                updatedAtLocal: updatedAtLocal,
                updatedAtRemote: updatedAtRemote,
                deletedAt: deletedAt,
                syncState: syncState,
                dirtyFields: dirtyFields,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> localId,
      Value<int?> remoteId,
      required String name,
      Value<String?> color,
      Value<String?> icon,
      Value<DateTime> updatedAtLocal,
      Value<DateTime?> updatedAtRemote,
      Value<DateTime?> deletedAt,
      Value<int> syncState,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> localId,
      Value<int?> remoteId,
      Value<String> name,
      Value<String?> color,
      Value<String?> icon,
      Value<DateTime> updatedAtLocal,
      Value<DateTime?> updatedAtRemote,
      Value<DateTime?> deletedAt,
      Value<int> syncState,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtRemote => $composableBuilder(
    column: $table.updatedAtRemote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtRemote => $composableBuilder(
    column: $table.updatedAtRemote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAtLocal => $composableBuilder(
    column: $table.updatedAtLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtRemote => $composableBuilder(
    column: $table.updatedAtRemote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<DateTime> updatedAtLocal = const Value.absent(),
                Value<DateTime?> updatedAtRemote = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncState = const Value.absent(),
              }) => CategoriesCompanion(
                localId: localId,
                remoteId: remoteId,
                name: name,
                color: color,
                icon: icon,
                updatedAtLocal: updatedAtLocal,
                updatedAtRemote: updatedAtRemote,
                deletedAt: deletedAt,
                syncState: syncState,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required String name,
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<DateTime> updatedAtLocal = const Value.absent(),
                Value<DateTime?> updatedAtRemote = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncState = const Value.absent(),
              }) => CategoriesCompanion.insert(
                localId: localId,
                remoteId: remoteId,
                name: name,
                color: color,
                icon: icon,
                updatedAtLocal: updatedAtLocal,
                updatedAtRemote: updatedAtRemote,
                deletedAt: deletedAt,
                syncState: syncState,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entityType,
      required int entityLocalId,
      required String op,
      Value<String?> payload,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<int> entityLocalId,
      Value<String> op,
      Value<String?> payload,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> entityLocalId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityLocalId: entityLocalId,
                op: op,
                payload: payload,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required int entityLocalId,
                required String op,
                Value<String?> payload = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityLocalId: entityLocalId,
                op: op,
                payload: payload,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
