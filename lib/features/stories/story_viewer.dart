import 'dart:math';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/widgets/glass.dart';
import '../../core/storage/study_store.dart';
import '../feed/models.dart';

String storyTopicLabel(String text){
  final clean=text.replaceAll(RegExp(r'[#*_]'),' ').replaceAll(RegExp(r'\s+'),' ').trim();
  if(clean.isEmpty)return 'Insight';
  final first=clean.split(RegExp(r'[.!?:]')).first.trim();
  final words=first.split(' ').take(2).toList();
  return words.join(' ').length>18?words.first:words.join(' ');
}
String storyMonogram(String text){
  final t=text.toLowerCase();
  if(t.contains('formula'))return '∑';
  if(t.contains('exam')||t.contains('question'))return 'Q?';
  if(t.contains('definition'))return 'DEF';
  if(t.contains('summary'))return 'SUM';
  if(t.contains('tip'))return '!';
  final words=storyTopicLabel(text).split(' ');
  if(words.length>1)return words[0][0]+words[1][0];
  return words.first.substring(0,min(2,words.first.length)).toUpperCase();
}
class StoriesTray extends StatelessWidget{
  final List<StudyPost> posts;final Color tint;
  const StoriesTray({super.key,required this.posts,required this.tint});
  @override Widget build(BuildContext context){
    final stories=posts.expand((p)=>List.generate(p.cards.length,(i)=>_Story(p.cards[i],p.sources.isEmpty?p.sourceName:p.sources[min(i,p.sources.length-1)],p))).take(10).toList();
    final children=<Widget>[_shuffle(context,stories)];
    children.addAll(stories.map((story)=>_ring(context,story)));
    return SizedBox(height:108,child:ListView(scrollDirection:Axis.horizontal,physics:const BouncingScrollPhysics(),padding:const EdgeInsets.symmetric(horizontal:14),children:children));
  }
  Widget _ring(BuildContext context,_Story story){
    return GestureDetector(onTap:()=>StoryViewer.open(context,[story],tint),child:Padding(padding:const EdgeInsets.only(right:10),child:Column(children:[
      _avatar(story),
      const SizedBox(height:6),
      SizedBox(width:62,child:Text(storyTopicLabel(story.text),maxLines:1,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600))),
    ])));
  }
  Widget _avatar(_Story story){
    return Container(
      padding:const EdgeInsets.all(2.5),
      decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[Color(0xFFFCAF45),Color(0xFFF77737),Color(0xFFE1306C),Color(0xFF833AB4)])),
      child:Container(
        padding:const EdgeInsets.all(2),
        decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF08090E)),
        child:CircleAvatar(radius:27,backgroundColor:tint.withValues(alpha:.18),child:Text(storyMonogram(story.text),style:TextStyle(color:tint,fontWeight:FontWeight.w800,fontSize:12))),
      ),
    );
  }
  Widget _shuffle(BuildContext context,List<_Story> stories){
    return GestureDetector(onTap:(){
      if(stories.isEmpty)return;
      final shuffled=[...stories]..shuffle(Random());
      StoryViewer.open(context,shuffled.take(min(8,shuffled.length)).toList(),tint);
    },child:Padding(padding:const EdgeInsets.only(right:10),child:Column(children:[
      Container(padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:Colors.white38)),child:CircleAvatar(radius:27,backgroundColor:tint.withValues(alpha:.16),child:Stack(alignment:Alignment.center,children:[
        Icon(Icons.auto_stories,color:tint),
        Positioned(right:-1,bottom:-1,child:Container(width:16,height:16,decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[Color(0xFFE1306C),Color(0xFF833AB4)])),child:const Icon(Icons.add,size:11,color:Colors.white))),
      ]))),
      const SizedBox(height:6),
      const SizedBox(width:62,child:Text('Shuffle',textAlign:TextAlign.center,style:TextStyle(fontSize:10,fontWeight:FontWeight.w600))),
    ])));
  }
}
class _Story{final String text,source;final StudyPost post;_Story(this.text,this.source,this.post);}
class StoryViewer extends StatefulWidget{
  final List<_Story> stories;final Color tint;
  const StoryViewer({super.key,required this.stories,required this.tint});
  static void open(BuildContext context,List<_Story> stories,Color tint){
    if(stories.isEmpty)return;
    Navigator.push(context,PageRouteBuilder(
      transitionDuration:const Duration(milliseconds:300),
      pageBuilder:(context,a,b)=>StoryViewer(stories:stories,tint:tint),
      transitionsBuilder:(context,a,b,child)=>FadeTransition(opacity:a,child:ScaleTransition(scale:Tween<double>(begin:.96,end:1).animate(a),child:child)),
    ));
  }
  @override State<StoryViewer>createState()=>_StoryViewerState();
}
class _StoryViewerState extends State<StoryViewer>{
  int index=0;bool paused=false;
  @override Widget build(BuildContext context){
    final story=widget.stories[index];
    return Scaffold(backgroundColor:const Color(0xFF07080D),body:AmbientBackground(accent:widget.tint,child:SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.all(14),child:_progress()),
      Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:_header(story)),
      const Spacer(),
      Expanded(child:GestureDetector(
        onTapUp:(event){setState(()=>index=event.localPosition.dx<MediaQuery.of(context).size.width*.32?max(0,index-1):min(widget.stories.length-1,index+1));},
        onLongPress:()=>setState(()=>paused=!paused),
        onVerticalDragEnd:(event){if((event.primaryVelocity??0)>250)Navigator.pop(context);},
        child:Center(child:_storyCard(story)),
      )),
      const Spacer(),
      Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:_actions(story)),
      const SizedBox(height:8),
      Text(paused?'Paused':'Tap sides · hold to pause · swipe down to close',style:const TextStyle(color:Colors.white38,fontSize:10)),
      const SizedBox(height:8),
    ]))));
  }
  Widget _progress(){
    final segments=List<Widget>.generate(widget.stories.length,(i){return Expanded(child:Container(height:2.5,margin:const EdgeInsets.symmetric(horizontal:2),decoration:BoxDecoration(color:i<=index?Colors.white:Colors.white24,borderRadius:BorderRadius.circular(4))));});
    return Row(children:segments);
  }
  Widget _header(_Story story)=>Row(children:[CircleAvatar(radius:15,backgroundColor:widget.tint.withValues(alpha:.2),child:Icon(Icons.menu_book,color:widget.tint,size:15)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(storyTopicLabel(story.text),style:const TextStyle(fontWeight:FontWeight.bold)),Text(story.source,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white54,fontSize:10))])),IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close))]);
  Widget _storyCard(_Story story){
    return Hero(tag:'story-'+story.post.id+'-'+index.toString(),child:Glass(radius:26,padding:const EdgeInsets.all(24),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('INSIGHT',style:TextStyle(color:widget.tint,fontWeight:FontWeight.w800,letterSpacing:1.4)),
      const SizedBox(height:14),
      SelectableText(story.text,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700,height:1.4)),
    ]))));
  }
  Widget _actions(_Story story)=>Row(children:[
    IconButton(onPressed:()async{await StudyStore.toggleSaved(story.post);},icon:Icon(story.post.saved?Icons.bookmark:Icons.bookmark_border)),
    const Spacer(),
    OutlinedButton.icon(onPressed:()async{await Clipboard.setData(ClipboardData(text:story.text));},icon:const Icon(Icons.copy,size:16),label:const Text('Copy')),
    const SizedBox(width:8),
    FilledButton.icon(onPressed:()=>setState(()=>index=(index+1)%widget.stories.length),icon:const Icon(Icons.shuffle,size:16),label:const Text('Next')),
  ]);
}
void showPostDetail(BuildContext context,StudyPost post,Color tint){
  final pages=post.cards.map((card)=>Padding(padding:const EdgeInsets.all(18),child:Glass(padding:const EdgeInsets.all(24),child:SingleChildScrollView(child:SelectableText(card,style:const TextStyle(fontSize:19,height:1.5)))))).toList();
  Navigator.push(context,MaterialPageRoute(builder:(context)=>Scaffold(backgroundColor:const Color(0xFF08090E),appBar:AppBar(title:Text(post.sourceName),backgroundColor:Colors.transparent),body:AmbientBackground(accent:tint,child:PageView(physics:const BouncingScrollPhysics(),children:pages)))));
}
