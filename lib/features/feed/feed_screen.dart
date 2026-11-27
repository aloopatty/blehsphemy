import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/glass.dart';
import '../../core/storage/study_store.dart';
import '../app/studygram_app.dart';
import '../accounts/account_switcher.dart';
import '../accounts/models.dart';
import '../feed/models.dart';
import '../stories/story_viewer.dart';
import '../countdown/countdown_logic.dart';
import '../upload/parser.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
  @override ConsumerState<FeedScreen> createState() => _FeedScreenState();
}
class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final subject = ref.watch(subjectsProvider).firstWhere((s) => s.id == ref.watch(activeSubjectProvider));
    final posts = StudyStore.postsFor(subject.id);
    final tint = Color(subject.tint);
    return AmbientBackground(accent: tint, child: SafeArea(
      child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverAppBar(
          pinned: true, toolbarHeight: 58, backgroundColor: Colors.black.withValues(alpha: .18),
          surfaceTintColor: Colors.transparent, titleSpacing: 16,
          title: TextButton(onPressed: () => showAccounts(context, ref), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(subject.handle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Icon(Icons.keyboard_arrow_down, size: 18),
            Container(width: 5, height: 5, margin: const EdgeInsets.only(left: 5), decoration: BoxDecoration(shape: BoxShape.circle, color: tint)),
          ])),
          actions: [
            _Countdown(subject: subject, ref: ref),
            const SizedBox(width: 5),
            IconButton(icon: const Icon(Icons.contrast_rounded, size: 20), onPressed: () => ref.read(lightModeProvider.notifier).state = !ref.read(lightModeProvider)),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(.5), child: Container(height: .5, color: Colors.white12)),
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: StoriesTray(posts: posts, tint: tint))),
        if (posts.isEmpty) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(18), child: Glass(padding: const EdgeInsets.all(24), child: const Text('Your feed is waiting. Upload lecture notes to create study posts.')))),
        SliverList(delegate: SliverChildBuilderDelegate((context, index) => PostCard(post: posts[index], subject: subject, tint: tint, onChanged: () => setState(() {})), childCount: posts.length)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    ));
  }
}

class _Countdown extends StatefulWidget {
  final Subject subject; final WidgetRef ref;
  const _Countdown({required this.subject, required this.ref});
  @override State<_Countdown> createState() => _CountdownState();
}
class _CountdownState extends State<_Countdown> {
  late DateTime now; Timer? timer;
  @override void initState() { super.initState(); now = DateTime.now(); if (widget.subject.deadline != null) timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => now = DateTime.now()); }); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final deadline = widget.subject.deadline;
    final remaining = deadline == null ? null : remainingUntil(deadline, now);
    return InkWell(onTap: () => _editGoal(context, widget.subject, widget.ref), child: Glass(radius: 20, padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFB4A6FF)), const SizedBox(width: 4),
      Text(remaining == null ? 'Set goal' : countdownLabel(remaining), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
    ])));
  }
}
Future<void> _editGoal(BuildContext context, Subject subject, WidgetRef ref) async {
  final name = TextEditingController(text: subject.deadlineName ?? 'Exam');
  final date = ValueNotifier<DateTime>(subject.deadline ?? DateTime.now().add(const Duration(days: 7)));
  final saved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Study goal'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Goal name')),
      ListenableBuilder(listenable: date, builder: (context, _) => TextButton(onPressed: () async {
        final picked = await showDatePicker(context: ctx, initialDate: date.value, firstDate: DateTime.now(), lastDate: DateTime(2100));
        if (picked != null) date.value = picked;
      }, child: Text(date.value.day.toString() + '/' + date.value.month.toString() + '/' + date.value.year.toString()))),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))],
  ));
  if (saved == true) {
    await StudyStore.saveSubject(Subject(id: subject.id, name: subject.name, handle: subject.handle, bio: subject.bio, tint: subject.tint, sample: subject.sample, deadline: date.value, deadlineName: name.text));
    ref.read(subjectsProvider.notifier).state = StudyStore.allSubjects;
  }
}

class PostCard extends StatefulWidget {
  final StudyPost post; final Subject subject; final Color tint; final VoidCallback onChanged;
  const PostCard({super.key, required this.post, required this.subject, required this.tint, required this.onChanged});
  @override State<PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<PostCard> {
  int page = 0; bool captionExpanded = false, heartBurst = false;
  @override Widget build(BuildContext context) {
    final post = widget.post;
    final caption = post.cards.first.replaceAll(RegExp(r'\s+'), ' ');
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header(context),
      _media(context),
      _actions(context),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(post.mastered ? 'Mastered · ' + post.cards.length.toString() + ' slides' : post.cards.length.toString() + ' slides', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(widget.subject.handle + '  ' + (captionExpanded ? post.cards.join(' · ') : caption.substring(0, min(120, caption.length))) + (caption.length > 120 && !captionExpanded ? '…' : ''), style: const TextStyle(fontSize: 12.5, height: 1.35))),
      if (caption.length > 120) Padding(padding: const EdgeInsets.only(left: 14), child: TextButton(onPressed: () => setState(() => captionExpanded = !captionExpanded), child: Text(captionExpanded ? 'less' : 'more', style: TextStyle(color: widget.tint)))),
      Padding(padding: const EdgeInsets.fromLTRB(14, 2, 14, 10), child: Text('#' + widget.subject.name.replaceAll(' ', '') + ' #StudyNotes #' + post.tag.replaceAll(' ', ''), style: TextStyle(color: widget.tint.withValues(alpha: .8), fontSize: 11))),
      Container(height: .5, color: Colors.white12),
    ]));
  }
  Widget _header(BuildContext context) {
    final post = widget.post;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), child: Row(children: [
      Container(padding: const EdgeInsets.all(1), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.tint)), child: CircleAvatar(radius: 16, backgroundColor: widget.tint.withValues(alpha: .18), child: Icon(Icons.menu_book, color: widget.tint, size: 16))),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.subject.handle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        Text(post.sourceName + ' · ' + _ago(post.createdAt), style: const TextStyle(fontSize: 10, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Glass(radius: 10, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), child: Text(post.tag, style: TextStyle(color: widget.tint, fontSize: 9, fontWeight: FontWeight.w800))),
      PopupMenuButton<String>(icon: const Icon(Icons.more_horiz), itemBuilder: (_) => const [PopupMenuItem(value: 'open', child: Text('View full file')), PopupMenuItem(value: 'delete', child: Text('Delete post'))], onSelected: (value) async {
        if (value == 'open') showPostDetail(context, post, widget.tint);
        if (value == 'delete') { await StudyStore.deletePost(post); widget.onChanged(); }
      }),
    ]));
  }
  Widget _media(BuildContext context) {
    final post = widget.post;
    return GestureDetector(onTap: () => showPostDetail(context, post, widget.tint), onDoubleTap: _like, child: Stack(children: [
      SizedBox(height: MediaQuery.of(context).size.width * 1.08, child: PageView.builder(physics: const BouncingScrollPhysics(), itemCount: post.cards.length, onPageChanged: (value) => setState(() => page = value), itemBuilder: (context, index) => _slide(post.cards[index], index))),
      Positioned(right: 12, top: 12, child: Glass(radius: 14, padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), child: Text((page + 1).toString() + ' / ' + post.cards.length.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)))),
      if (heartBurst) const Positioned.fill(child: Center(child: Icon(Icons.favorite, color: Color(0xFFE1306C), size: 80))),
    ]));
  }
  Widget _slide(String raw, int index) {
    final text = StudyParser.normalizeExtractedText(raw);
    final title = text.split('\n').firstWhere((line) => line.trim().isNotEmpty, orElse: () => widget.post.sourceName);
    final body = text.replaceFirst(title, '').trim();
    return Container(margin: const EdgeInsets.symmetric(horizontal: 10), padding: const EdgeInsets.fromLTRB(20, 22, 20, 18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [widget.tint.withValues(alpha: .18 + (index % 3) * .02), const Color(0xFF171822), const Color(0xFF0A0B12)]), border: Border.all(color: Colors.white.withValues(alpha: .08))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PAGE ' + (index + 1).toString().padLeft(2, '0') + ' · NOTES', style: TextStyle(color: widget.tint, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
      const SizedBox(height: 14), Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.2)),
      const SizedBox(height: 10), Expanded(child: SingleChildScrollView(child: SelectableText(body.isEmpty ? text : body, style: TextStyle(fontSize: 14, height: 1.45, color: Colors.white.withValues(alpha: .88))))),
      if (text.length > 450) Align(alignment: Alignment.bottomRight, child: Glass(radius: 10, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: const Text('Tap to read full page', style: TextStyle(fontSize: 9))),
    ]));
  }
  Widget _actions(BuildContext context) {
    final post = widget.post;
    return Row(children: [
      IconButton(onPressed: () async { await StudyStore.toggleLiked(post); widget.onChanged(); }, icon: Icon(post.liked ? Icons.favorite : Icons.favorite_border, color: post.liked ? const Color(0xFFE1306C) : null)),
      IconButton(onPressed: () => _review(context, post, widget.tint), icon: const Icon(Icons.style_outlined)),
      IconButton(onPressed: () async { await Clipboard.setData(ClipboardData(text: post.cards.join('\n\n'))); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied study notes'))); }, icon: const Icon(Icons.send_outlined)),
      const Spacer(),
      Row(children: List.generate(post.cards.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.symmetric(horizontal: 2), width: i == page ? 7 : 4, height: 4, decoration: BoxDecoration(color: i == page ? widget.tint : Colors.white24, borderRadius: BorderRadius.circular(4)))),
      IconButton(onPressed: () async { await StudyStore.toggleSaved(post); widget.onChanged(); }, icon: Icon(post.saved ? Icons.bookmark : Icons.bookmark_border, color: post.saved ? widget.tint : null)),
    ]);
  }
  Future<void> _like() async { HapticFeedback.mediumImpact(); await StudyStore.toggleLiked(widget.post); await StudyStore.toggleMastered(widget.post); setState(() => heartBurst = true); Future.delayed(const Duration(milliseconds: 600), () { if (mounted) setState(() => heartBurst = false); }); widget.onChanged(); }
  String _ago(DateTime d) { final m = DateTime.now().difference(d).inMinutes; if (m < 1) return 'now'; if (m < 60) return m.toString() + 'm'; if (m < 1440) return (m ~/ 60).toString() + 'h'; return (m ~/ 1440).toString() + 'd'; }
}
Future<void> _review(BuildContext context, StudyPost post, Color tint) => showModalBottomSheet<void>(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Glass(radius: 24, padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
  const Text('Quick review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
  ...post.cards.take(4).map((card) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• ' + card.replaceAll(RegExp(r'\s+'), ' ').substring(0, min(130, card.length)))),
  FilledButton(onPressed: () => showPostDetail(context, post, tint), child: const Text('Open full notes')),
])));
