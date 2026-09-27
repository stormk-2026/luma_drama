import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../catalog/domain/drama.dart';
import '../application/engagement_controller.dart';

class DramaCommentsSheet extends StatefulWidget {
  const DramaCommentsSheet({super.key, required this.drama});

  final Drama drama;

  @override
  State<DramaCommentsSheet> createState() => _DramaCommentsSheetState();
}

class _DramaCommentsSheetState extends State<DramaCommentsSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _post() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<EngagementController>().addComment(widget.drama.id, text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comments = context.watch<EngagementController>().commentsFor(
      widget.drama.id,
    );
    final available =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        24;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: available.clamp(240.0, 460.0),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.comments,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.localOnlyComments,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: comments.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noComments,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        )
                      : ListView.separated(
                          itemCount: comments.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) => ListTile(
                            leading: const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person_rounded, size: 18),
                            ),
                            title: Text(comments[index]),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('comment-input'),
                        controller: _input,
                        maxLength: 300,
                        maxLines: 1,
                        decoration: InputDecoration(
                          hintText: l10n.writeComment,
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF35353A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _post(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('comment-post'),
                      tooltip: l10n.postComment,
                      onPressed: _post,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
