import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'poll_providers.dart';
import 'poll_widgets.dart';

class PollDetailScreen extends ConsumerWidget {
  const PollDetailScreen({super.key, required this.pollId});
  final int pollId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final feed = ref.watch(currentPollFeedProvider);
    final poll = feed.value?.byId(pollId);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabQuestion)),
      body: poll == null
          ? feed.isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ErrorRetry(message: l10n.errorGeneric)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(l10n.pollWeekOf(LocalTime.civil(poll.semaine, context.localeName)), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(poll.question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 10),
                PollStatusChip(poll),
                const SizedBox(height: 4),
                PollBody(poll),
              ],
            ),
    );
  }
}
