/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

/// Application settings singleton (non-table class for API transport).
/// The actual table is managed manually via migration (singleton pattern like sync_state).
abstract class AppSettings
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AppSettings._({int? archiveRetentionDays})
    : archiveRetentionDays = archiveRetentionDays ?? 0;

  factory AppSettings({int? archiveRetentionDays}) = _AppSettingsImpl;

  factory AppSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppSettings(
      archiveRetentionDays: jsonSerialization['archiveRetentionDays'] as int?,
    );
  }

  /// Number of days to retain archived items before auto-purge. 0 = never purge.
  int archiveRetentionDays;

  /// Returns a shallow copy of this [AppSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AppSettings copyWith({int? archiveRetentionDays});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppSettings',
      'archiveRetentionDays': archiveRetentionDays,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppSettings',
      'archiveRetentionDays': archiveRetentionDays,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AppSettingsImpl extends AppSettings {
  _AppSettingsImpl({int? archiveRetentionDays})
    : super._(archiveRetentionDays: archiveRetentionDays);

  /// Returns a shallow copy of this [AppSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AppSettings copyWith({int? archiveRetentionDays}) {
    return AppSettings(
      archiveRetentionDays: archiveRetentionDays ?? this.archiveRetentionDays,
    );
  }
}
