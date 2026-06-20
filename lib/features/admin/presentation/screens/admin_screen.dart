import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/loading_indicator.dart';

/// Админ-панель (заглушка MVP). Доступ — только для персонала (гвард в роутере).
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const ComingSoonView(
        title: 'Управление студией',
        icon: Icons.admin_panel_settings,
      ),
    );
  }
}
