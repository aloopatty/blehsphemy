import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/glass.dart';
import '../../core/storage/study_store.dart';
import '../app/studygram_app.dart';
class QuickStudyScreen extends ConsumerWidget {
  const QuickStudyScreen({super.key});
  @override Widget build(BuildContext context,WidgetRef ref){
    final subject=ref.watch(subjectsProvider).firstWhere((s)=>s.id==ref.watch(activeSubjectProvider));
    final cards=StudyStore.postsFor(subject.id).expand((post)=>post.cards).toList();
    final tint=Color(subject.tint);
    return AmbientBackground(accent:tint,child:SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.all(18),child:Row(children:[const Icon(Icons.bolt,color:Color(0xFFFFD166)),const SizedBox(width:8),Expanded(child:Text('Quick Study',style:Theme.of(context).textTheme.headlineMedium)),Text(cards.length.toString()+' cards',style:const TextStyle(color:Colors.white54))])),
      Expanded(child:cards.isEmpty?Center(child:Glass(padding:const EdgeInsets.all(22),child:const Text('Upload notes to create quick-study cards.'))):PageView.builder(scrollDirection:Axis.vertical,physics:const BouncingScrollPhysics(),itemCount:cards.length,itemBuilder:(context,index)=>_card(cards[index],index,tint))),
    ])));
  }
  Widget _card(String text,int index,Color tint)=>Padding(padding:const EdgeInsets.fromLTRB(16,8,16,18),child:Glass(radius:26,padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('CARD '+(index+1).toString(),style:TextStyle(color:tint,fontWeight:FontWeight.w800,letterSpacing:1.3)),const Spacer(),SingleChildScrollView(child:SelectableText(text,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w700,height:1.4))),const Spacer(),Row(children:[const Text('Swipe for next',style:TextStyle(color:Colors.white54)),Icon(Icons.swipe_vertical,color:tint)])])));
}
