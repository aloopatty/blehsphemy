import 'dart:async';\nimport 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/glass.dart';
import '../../core/storage/study_store.dart';
import '../app/studygram_app.dart';
import '../accounts/account_switcher.dart';
import '../accounts/models.dart';
import '../feed/models.dart';
import '../stories/story_viewer.dart';
import '../countdown/countdown_logic.dart';

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

    return AmbientBackground(
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => showAccounts(context, ref),
                    child: Row(children: [Text(subject.handle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const Icon(Icons.keyboard_arrow_down)]),
                  ),
                  const Spacer(),
                  _Countdown(subject: subject, ref: ref),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => ref.read(lightModeProvider.notifier).state = !ref.read(lightModeProvider), icon: const Icon(Icons.brightness_6_outlined)),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                child: Row(children: [
                  CircleAvatar(radius: 26, backgroundColor: tint.withValues(alpha: .22), child: Icon(Icons.auto_stories, color: tint)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(subject.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(subject.sample ? 'Sample account' : 'Your personal study feed', style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 12)),
                  ])),
                ]),
              ),
            ),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: StoriesTray(posts: posts, tint: tint))),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                child: Row(children: [const Text('Your learning feed', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const Spacer(), Text('${posts.length} posts', style: TextStyle(color: Colors.white.withValues(alpha: .5)))]),
              ),
            ),
            if (posts.isEmpty) SliverToBoxAdapter(child: Glass(padding: const EdgeInsets.all(24), child: const Text('Upload lecture notes to create your first post.'))),
            SliverList(delegate: SliverChildBuilderDelegate((context, index) => PostCard(post: posts[index], tint: tint, onChanged: () => setState(() {})), childCount: posts.length)),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  final Subject subject;
  final WidgetRef ref;
  const _Countdown({required this.subject, required this.ref});
  @override State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late DateTime now;
  Timer? ticker;
  @override void initState() {
    super.initState();
    now = DateTime.now();
    if (widget.subject.deadline != null) ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => now = DateTime.now()); });
  }
  @override void dispose() { ticker?.cancel(); super.dispose(); }
  @override void didUpdateWidget(covariant _Countdown oldWidget) { super.didUpdateWidget(oldWidget); now = DateTime.now(); if (oldWidget.subject.deadline != widget.subject.deadline) { ticker?.cancel(); if (widget.subject.deadline != null) ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => now = DateTime.now()); }); } }
  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    final d = subject.deadline == null ? null : remainingUntil(subject.deadline!, now);
    return GestureDetector(
      onTap: () => _edit(context, subject, widget.ref),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        radius: 30,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFB4A6FF)),
          const SizedBox(width: 5),
          Text(d == null ? 'Set goal' : countdownLabel(d), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

Future<void> _edit(BuildContext context, Subject s, WidgetRef ref) async {
  final name = TextEditingController(text: s.deadlineName ?? 'Exam');
  final date = ValueNotifier<DateTime>(s.deadline ?? DateTime.now().add(const Duration(days: 7)));
  final picked = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Study goal countdown'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Event name')),
        const SizedBox(height: 12),
        ListenableBuilder(listenable: date, builder: (c, _) => TextButton(
          onPressed: () async {
            final d = await showDatePicker(context: ctx, initialDate: date.value, firstDate: DateTime.now(), lastDate: DateTime(2100));
            if (d != null) date.value = d;
          },
          child: Text('${date.value.day}/${date.value.month}/${date.value.year} · Tap to edit date'),
        )),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );
  if (picked == true) {
    final updated = Subject(id: s.id, name: s.name, handle: s.handle, bio: s.bio, tint: s.tint, sample: s.sample, deadline: date.value, deadlineName: name.text);
    await StudyStore.saveSubject(updated);
    ref.read(subjectsProvider.notifier).state = StudyStore.allSubjects;
  }
}

class PostCard extends StatefulWidget {
  final StudyPost post;
  final Color tint;
  final VoidCallback onChanged;
  const PostCard({super.key, required this.post, required this.tint, required this.onChanged});
  @override State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Glass(
        radius: 26,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(radius: 17, backgroundColor: widget.tint.withValues(alpha: .2), child: Icon(Icons.menu_book, color: widget.tint, size: 17)),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.sourceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(p.sample ? 'SAMPLE CONTENT' : 'Added ${_ago(p.createdAt)}', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .48))),
              ])),
              Glass(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), radius: 12, child: Text(p.tag, style: TextStyle(fontSize: 9, color: widget.tint, fontWeight: FontWeight.bold))),
            ]),
          ),
          SizedBox(
            height: 330,
            child: PageView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: p.cards.length,
              onPageChanged: (v) => setState(() => page = v),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [widget.tint.withValues(alpha: .18), Colors.white.withValues(alpha: .035)]),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1} / ${p.cards.length}', style: TextStyle(color: widget.tint, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Expanded(child: SingleChildScrollView(child: Text(p.cards[i], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.5)))),
                  ]),
                ),
              ),
            ),
          ),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(p.cards.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == page ? 15 : 5,
              height: 5,
              decoration: BoxDecoration(color: i == page ? widget.tint : Colors.white24, borderRadius: BorderRadius.circular(9)),
            ))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(children: [
              IconButton(onPressed: () async { HapticFeedback.lightImpact(); await StudyStore.toggleMastered(p); widget.onChanged(); }, icon: Icon(p.mastered ? Icons.check_circle : Icons.circle_outlined, color: p.mastered ? Colors.greenAccent : null)),
              Text(p.mastered ? 'Mastered' : 'Master this', style: const TextStyle(fontSize: 12)),
              const Spacer(),
              IconButton(onPressed: () async { HapticFeedback.lightImpact(); await StudyStore.toggleSaved(p); widget.onChanged(); }, icon: Icon(p.saved ? Icons.bookmark : Icons.bookmark_border, color: p.saved ? widget.tint : null)),
              IconButton(onPressed: () => showPostDetail(context, p, widget.tint), icon: const Icon(Icons.open_in_full)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _ago(DateTime d) {
    final mins = DateTime.now().difference(d).inMinutes;
    if (mins < 60) return '$mins min ago';
    return '${mins ~/ 60}h ago';
  }
}
