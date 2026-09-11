import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/local_time.dart';
import '../../core/widgets/widgets.dart';
import 'poll_providers.dart';
import 'poll_widgets.dart';

/// Une semaine passée : même carte que la question courante, à l'état fermé.
class PollDetailScreen extends ConsumerWidget {
  const PollDetailScreen({super.key, required this.pollId});
  final int pollId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feed = ref.watch(currentPollFeedProvider);
    final poll = feed.value?.byId(pollId);
    if (poll == null) {
      return BandScaffold(
        title: l10n.tabQuestion,
        children: [
          SoftCard(
            child: feed.isLoading ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))) : ErrorRetry(message: l10n.errorGeneric),
          ),
        ],
      );
    }
    return BandScaffold(
      eyebrow: l10n.pollWeekOf(LocalTime.civil(poll.semaine, context.localeName)),
      clock: pollStatusLine(context, ref, poll),
      title: poll.question,
      children: [PollCard(poll), const SizedBox(height: 4), PosterList(children: [PollContextCard(poll, initiallyOpen: true)])],
    );
  }
}
