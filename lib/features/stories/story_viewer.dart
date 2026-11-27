import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/widgets/glass.dart';
import '../../core/storage/study_store.dart';
import '../feed/models.dart';

class StoriesTray extends StatelessWidget {
  final List<StudyPost> posts;
  final Color tint;
  const StoriesTray({super.key, required this.posts, required this.tint});

  @override
  Widget build(BuildContext context) {
    final insights = posts.expand((p) => List.generate(p.cards.length, (i) => _Insight(p.cards[i], p.sources.isEmpty ? p.sourceName : p.sources[min(i, p.sources.length - 1)], p))).take(12).toList();
    if (insights.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 106,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [...insights.take(6).map((ins) => _ring(context, ins)), _shuffle(context, insights)],
      ),
    );
  }

  Widget _ring(BuildContext context, _Insight i) => GestureDetector(
    onTap: () => StoryViewer.open(context, [i], tint),
    child: Padding(padding: const EdgeInsets.only(right: 12), child: Column(children: [
      Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [tint, Colors.cyanAccent, Colors.pinkAccent])), child: CircleAvatar(radius: 29, backgroundColor: const Color(0xFF101521), child: Icon(Icons.bolt, color: tint))),
      const SizedBox(height: 7),
      SizedBox(width: 66, child: Text(i.post.sourceName, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
    ])),
  );

  Widget _shuffle(BuildContext context, List<_Insight> list) => GestureDetector(
    onTap: () { final shuffled = [...list]..shuffle(Random()); StoryViewer.open(context, shuffled.take(5).toList(), tint); },
    child: Column(children: [
      Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38)), child: CircleAvatar(radius: 29, backgroundColor: Colors.white.withValues(alpha: .07), child: const Icon(Icons.shuffle))),
      const SizedBox(height: 7),
      const Text('Shuffle', style: TextStyle(fontSize: 10)),
    ]),
  );
}

class _Insight {
  final String text, source;
  final StudyPost post;
  _Insight(this.text, this.source, this.post);
}

class StoryViewer extends StatefulWidget {
  final List<_Insight> insights;
  final Color tint;
  const StoryViewer({super.key, required this.insights, required this.tint});

  static void open(BuildContext context, List<_Insight> insights, Color tint) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondary) => StoryViewer(insights: insights, tint: tint),
      transitionsBuilder: (context, animation, secondary, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(animation), child: child),
      ),
    ));
  }

  @override State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  int index = 0;
  bool paused = false;

  @override
  Widget build(BuildContext context) {
    final insight = widget.insights[index];
    return GestureDetector(
      onTapUp: (e) {
        if (e.localPosition.dx < MediaQuery.of(context).size.width * .35) {
          setState(() => index = max(0, index - 1));
        } else {
          setState(() => index = min(widget.insights.length - 1, index + 1));
        }
      },
      onLongPress: () => setState(() => paused = !paused),
      onVerticalDragEnd: (e) { if ((e.primaryVelocity ?? 0) > 300) Navigator.pop(context); },
      child: Scaffold(
        backgroundColor: const Color(0xFF070A12),
        body: AmbientBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Row(children: List.generate(widget.insights.length, (n) => Expanded(child: Container(
                  height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: n <= index ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(4)),
                )))),
                const SizedBox(height: 24),
                Row(children: [
                  CircleAvatar(backgroundColor: widget.tint.withValues(alpha: .2), child: Icon(Icons.auto_stories, color: widget.tint)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(insight.source, style: const TextStyle(fontSize: 12))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
                const Spacer(),
                Hero(
                  tag: 'story-${insight.post.id}-$index',
                  child: Glass(radius: 30, padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('QUICK INSIGHT', style: TextStyle(letterSpacing: 2, fontSize: 11, color: widget.tint, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text(insight.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.5)),
                  ])),
                ),
                const Spacer(),
                Row(children: [
                  OutlinedButton.icon(onPressed: () async { await StudyStore.toggleSaved(insight.post); }, icon: const Icon(Icons.bookmark_border), label: const Text('Save for review')),
                  const Spacer(),
                  FilledButton.icon(onPressed: () => setState(() => index = (index + 1) % widget.insights.length), icon: const Icon(Icons.shuffle), label: const Text('Next')),
                ]),
                const SizedBox(height: 18),
                Text(paused ? 'Paused · long press to resume' : 'Tap sides to navigate · hold to pause · swipe down to close', style: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 11)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

void showPostDetail(BuildContext context, StudyPost post, Color tint) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
    backgroundColor: const Color(0xFF080B14),
    appBar: AppBar(title: Text(post.sourceName)),
    body: AmbientBackground(child: PageView(children: post.cards.map((card) => Padding(
      padding: const EdgeInsets.all(18),
      child: Glass(padding: const EdgeInsets.all(26), child: SingleChildScrollView(child: Text(card, style: const TextStyle(fontSize: 21, height: 1.5)))),
    )).toList())),
  )));
}
