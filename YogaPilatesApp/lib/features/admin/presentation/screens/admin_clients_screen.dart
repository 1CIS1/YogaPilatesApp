import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/admin_providers.dart';

/// Список клиентов с поиском.
class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(adminClientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Клиенты')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Поиск по имени, телефону, email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          ref.read(adminClientsSearchProvider.notifier).set('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (v) {
                ref.read(adminClientsSearchProvider.notifier).set(v);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: clientsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(adminClientsProvider),
                  child: const Text('Повторить'),
                ),
              ),
              data: (clients) {
                if (clients.isEmpty) {
                  return const Center(child: Text('Клиенты не найдены'));
                }
                return ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (_, i) {
                    final c = clients[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (c.fullName != null && c.fullName!.isNotEmpty)
                              ? c.fullName!.substring(0, 1).toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(c.fullName ?? 'Без имени'),
                      subtitle: Text(
                          [c.phone, c.email].where((e) => e != null).join(' · ')),
                      trailing: c.isBlocked
                          ? const Icon(Icons.block, color: Colors.red)
                          : const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.adminClientProfile,
                          extra: c.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
