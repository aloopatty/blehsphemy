import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/glass.dart';
import '../../core/storage/study_store.dart';
import '../app/studygram_app.dart';
import '../stories/story_viewer.dart';
import '../accounts/account_switcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
 const ProfileScreen({super.key});
 @override ConsumerState<ProfileScreen> createState()=>_ProfileScreenState();
}
class _ProfileScreenState extends ConsumerState<ProfileScreen>{
 int tab=0;
 @override Widget build(BuildContext context){
  final subject=ref.watch(subjectsProvider).firstWhere((s)=>s.id==ref.watch(activeSubjectProvider));final all=StudyStore.postsFor(subject.id);final posts=tab==0?all:tab==1?all.where((p)=>p.mastered).toList():all.where((p)=>p.saved).toList();final tint=Color(subject.tint);
  return AmbientBackground(accent:tint,child:SafeArea(child:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
   SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[const Text('Profile',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const Spacer(),IconButton(onPressed:()=>showAccounts(context,ref),icon:const Icon(Icons.switch_account))]))),
   SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(18,0,18,15),child:Row(children:[Container(padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[tint,Colors.pinkAccent])),child:CircleAvatar(radius:38,backgroundColor:const Color(0xFF10121B),child:Icon(Icons.menu_book,color:tint,size:30))),const SizedBox(width:14),Expanded(child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_stat('Files',all.map((p)=>p.sourceName).toSet().length),_stat('Posts',all.length),_stat('Mastered',all.where((p)=>p.mastered).length)]))]))),
   SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(subject.name,style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),Text(subject.handle,style:const TextStyle(color:Colors.white54)),Text(subject.bio,style:const TextStyle(fontSize:12)),const SizedBox(height:10),Row(children:[Expanded(child:OutlinedButton(onPressed:()=>showAccounts(context,ref),child:const Text('Switch account'))),const SizedBox(width:8),Expanded(child:OutlinedButton(onPressed:()=>showAccounts(context,ref),child:const Text('Edit subject'))])]))),
   SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,15,16,9),child:Row(children:[_highlight(Icons.functions,'Formulas',tint),_highlight(Icons.quiz_outlined,'Exam Qs',tint),_highlight(Icons.bookmark,'Saved',tint)]))),
   SliverToBoxAdapter(child:Row(children:[_tab(Icons.grid_on,0),_tab(Icons.bolt,1),_tab(Icons.bookmark_border,2)])),
   SliverPadding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),sliver:SliverGrid(delegate:SliverChildBuilderDelegate((context,index){final p=posts[index];return GestureDetector(onTap:()=>showPostDetail(context,p,tint),child:Glass(radius:12,padding:const EdgeInsets.all(8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(p.cards.first,maxLines:7,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11))),Text(p.sourceName,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:9,fontWeight:FontWeight.bold)),Row(children:[if(p.saved)const Icon(Icons.bookmark,size:11),if(p.mastered)const Icon(Icons.check_circle,size:11,color:Colors.greenAccent)])])));},childCount:posts.length),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:6,mainAxisSpacing:6,childAspectRatio:.78))),
   const SliverToBoxAdapter(child:SizedBox(height:90))
  ])));
 }
 Widget _stat(String label,int count)=>Column(children:[Text('$count',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Text(label,style:const TextStyle(fontSize:11,color:Colors.white60))]);
 Widget _highlight(IconData icon,String label,Color tint)=>Expanded(child:Column(children:[Container(width:52,height:52,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:Colors.white30),color:tint.withValues(alpha:.12)),child:Icon(icon,color:tint)),const SizedBox(height:5),Text(label,style:const TextStyle(fontSize:10))]));
 Widget _tab(IconData icon,int value)=>Expanded(child:InkWell(onTap:()=>setState(()=>tab=value),child:Column(children:[Icon(icon,color:tab==value?Colors.white:Colors.white38),const SizedBox(height:5),Container(height:1.5,color:tab==value?Colors.white:Colors.transparent)])));
}
