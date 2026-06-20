/// Роли пользователей (синхронизировано с enum app_role в БД).
enum AppRole {
  owner,
  seniorAdmin,
  admin,
  client;

  /// Маппинг из строкового значения БД (snake_case).
  static AppRole fromDb(String? value) {
    switch (value) {
      case 'owner':
        return AppRole.owner;
      case 'senior_admin':
        return AppRole.seniorAdmin;
      case 'admin':
        return AppRole.admin;
      case 'client':
      default:
        return AppRole.client;
    }
  }

  /// Является ли роль персоналом студии (доступ к админ-панели).
  bool get isStaff =>
      this == AppRole.owner ||
      this == AppRole.seniorAdmin ||
      this == AppRole.admin;
}
