import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../accounts/models.dart';
import '../feed/models.dart';
import '../../core/storage/study_store.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';
import '../upload/upload_screen.dart';

final subjectsProvider = StateProvider<List<Subject>>((ref)=>StudyStore.allSubjects);
final activeSubjectProvider = StateProvider<String>((ref)=>StudyStore.allSubjects.first.id);
final postsProvider = StateProvider<List<StudyPost>>((ref)=>StudyStore.allPosts);
final lightModeProvider = StateProvider<bool>((ref)=>false);

class StudyGramApp extends ConsumerWidget {
  const StudyGramApp({super.key});
  @override Widget build(BuildContext context,WidgetRef ref) {
    final light=ref.watch(lightModeProvider);
    return MaterialApp(debugShowCheckedModeBanner:false,title:'StudyGram',theme:light?AppTheme.light():AppTheme.dark(),home:const MainShell());
  }
}
class MainShell extends ConsumerStatefulWidget { const MainShell({super.key}); @override ConsumerState<MainShell> createState()=>_MainShellState(); }
class _MainShellState extends ConsumerState<MainShell> {
  int tab=0;
  @override Widget build(BuildContext context) {
    final subject=ref.watch(subjectsProvider).firstWhere((s)=>s.id==ref.watch(activeSubjectProvider));
    final pages=[const FeedScreen(),const UploadScreen(),const ProfileScreen()];
    return Scaffold(
      extendBody:true,
      body:pages[tab],
      bottomNavigationBar:Padding(padding:const EdgeInsets.fromLTRB(16,0,16,14),child:Container(
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.25),blurRadius:20)]),
        child:NavigationBar(height:70,backgroundColor:Colors.white.withValues(alpha:.07),indicatorColor:Color(subject.tint).withValues(alpha:.25),selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
          destinations:const [NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),selectedIcon:Icon(Icons.auto_awesome),label:'Feed'),NavigationDestination(icon:Icon(Icons.add_circle_outline,size:30),selectedIcon:Icon(Icons.add_circle,size:30),label:'Upload'),NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile')]))),
    );
  }
}
