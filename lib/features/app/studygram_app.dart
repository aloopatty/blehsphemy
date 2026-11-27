import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../accounts/models.dart';
import '../feed/models.dart';
import '../../core/storage/study_store.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';
import '../upload/upload_screen.dart';
import '../explore/explore_screen.dart';
import '../quick_study/quick_study_screen.dart';

final subjectsProvider=StateProvider<List<Subject>>((ref)=>StudyStore.allSubjects);
final activeSubjectProvider=StateProvider<String>((ref)=>StudyStore.allSubjects.first.id);
final postsProvider=StateProvider<List<StudyPost>>((ref)=>StudyStore.allPosts);
final lightModeProvider=StateProvider<bool>((ref)=>false);

class StudyGramApp extends ConsumerWidget {
  const StudyGramApp({super.key,this.home});
  final Widget? home;
  @override Widget build(BuildContext context,WidgetRef ref) {
    return MaterialApp(debugShowCheckedModeBanner:false,title:'StudyGram',theme:ref.watch(lightModeProvider)?AppTheme.light():AppTheme.dark(),home:home??const MainShell());
  }
}
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override ConsumerState<MainShell> createState()=>_MainShellState();
}
class _MainShellState extends ConsumerState<MainShell> {
  int tab=0;
  @override Widget build(BuildContext context) {
    final subject=ref.watch(subjectsProvider).firstWhere((s)=>s.id==ref.watch(activeSubjectProvider));
    final tint=Color(subject.tint);
    final pages=[const FeedScreen(),const ExploreScreen(),const UploadScreen(),const QuickStudyScreen(),const ProfileScreen()];
    return Scaffold(
      extendBody:true,
      body:IndexedStack(index:tab,children:pages),
      bottomNavigationBar:Padding(
        padding:const EdgeInsets.fromLTRB(12,0,12,10),
        child:ClipRRect(
          borderRadius:BorderRadius.circular(22),
          child:BackdropFilter(
            filter:ImageFilter.blur(sigmaX:24,sigmaY:24),
            child:Container(
              height:58,
              decoration:BoxDecoration(color:Colors.black.withValues(alpha:.62),border:Border(top:BorderSide(color:Colors.white.withValues(alpha:.12),width:.5))),
              child:Row(children:List.generate(5,(i)=>Expanded(
                child:InkWell(
                  onTap:(){HapticFeedback.selectionClick();setState(()=>tab=i);},
                  child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                    if(i==4) CircleAvatar(radius:13,backgroundColor:tint.withValues(alpha:.2),child:Icon(Icons.menu_book,size:15,color:tint))
                    else Icon([Icons.home_outlined,Icons.search_rounded,Icons.add_box_outlined,Icons.bolt_outlined][i],size:24,color:tab==i?Colors.white:Colors.white60),
                    const SizedBox(height:4),
                    Container(width:4,height:4,decoration:BoxDecoration(shape:BoxShape.circle,color:tab==i?tint:Colors.transparent)),
                  ]),
                ),
              ))),
            ),
          ),
        ),
      ),
    );
  }
}