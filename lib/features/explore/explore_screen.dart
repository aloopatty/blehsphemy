import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/glass.dart';
import '../../core/storage/study_store.dart';
import '../app/studygram_app.dart';
import '../stories/story_viewer.dart';
import '../feed/models.dart';

class ExploreScreen extends ConsumerStatefulWidget {
 const ExploreScreen({super.key});
 @override ConsumerState<ExploreScreen> createState()=>_ExploreScreenState();
}
class _ExploreScreenState extends ConsumerState<ExploreScreen> {
 final search=TextEditingController();
 @override void dispose(){search.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  final q=search.text.toLowerCase().trim();
  final posts=StudyStore.allPosts.where((p)=>q.isEmpty||p.sourceName.toLowerCase().contains(q)||p.tag.toLowerCase().contains(q)||p.cards.any((s)=>s.toLowerCase().contains(q))).toList();
  return AmbientBackground(child:SafeArea(child:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
   SliverToBoxAdapter(child:_heading(context)),
   SliverToBoxAdapter(child:_searchBox()),
   SliverToBoxAdapter(child:_resultCount(posts.length)),
   SliverList(delegate:SliverChildBuilderDelegate((context,index){return _tile(context,posts[index]);},childCount:posts.length)),
   const SliverToBoxAdapter(child:SizedBox(height:90)),
  ])));
 }
 Widget _heading(BuildContext context)=>Padding(padding:const EdgeInsets.all(18),child:Text('Explore',style:Theme.of(context).textTheme.headlineMedium));
 Widget _searchBox()=>Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:Glass(radius:15,padding:const EdgeInsets.symmetric(horizontal:10),child:TextField(controller:search,onChanged:(value)=>setState((){}),decoration:const InputDecoration(border:InputBorder.none,prefixIcon:Icon(Icons.search),hintText:'Search notes, slides and concepts')));
 Widget _resultCount(int count)=>Padding(padding:const EdgeInsets.all(16),child:Text(count.toString()+' posts',style:const TextStyle(color:Colors.white54)));
 Widget _tile(BuildContext context,StudyPost post){
  final subjects=ref.watch(subjectsProvider);
  final subject=subjects.firstWhere((s)=>s.id==post.subjectId,orElse:()=>subjects.first);
  final tint=Color(subject.tint);
  return Padding(padding:const EdgeInsets.fromLTRB(12,0,12,10),child:Glass(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[CircleAvatar(radius:15,backgroundColor:tint.withValues(alpha:.2),child:Icon(Icons.menu_book,color:tint,size:15)),const SizedBox(width:8),Expanded(child:Text(subject.handle,style:const TextStyle(fontWeight:FontWeight.bold))),Text(post.tag,style:TextStyle(color:tint,fontSize:10))]),
   const SizedBox(height:8),Text(post.sourceName,style:const TextStyle(fontWeight:FontWeight.w700)),Text(post.cards.first,maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70)),
   Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>showPostDetail(context,post,tint),child:const Text('Open'))),
  ])));
 }
}
