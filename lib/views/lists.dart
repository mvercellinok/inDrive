import 'package:flutter/material.dart';
import '../theme/theme.dart';

class ListsView extends StatelessWidget {
  const ListsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      // app bar
      appBar: AppBar(
        title: const Text('Listas'),
      ),

      // lista
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.spacing200,
        ),
        children: [
          // item 1
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing400,
              vertical: AppSpacing.spacing100,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppRadius.radius2xl,
              ),
              child: Image.asset(
                'assets/images/kaleko.jpeg',
                width: AppSpacing.spacing1000,
                height: AppSpacing.spacing1000,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              'Kaleko Urdangak',
              style: text.bodyLarge,
            ),
            subtitle: Text(
              'Canción 01',
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),

        
          // item 2
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing400,
              vertical: AppSpacing.spacing100,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppRadius.radius2xl,
              ),
              child: Image.asset(
                'assets/images/kaleko.jpeg',
                width: AppSpacing.spacing1000,
                height: AppSpacing.spacing1000,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              'Kaleko Urdangak',
              style: text.bodyLarge,
            ),
            subtitle: Text(
              'Canción 2',
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}