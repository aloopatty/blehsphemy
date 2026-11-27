import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../app/studygram_app.dart';
import 'models.dart';
import '../../core/storage/study_store.dart';
import '../../core/widgets/glass.dart';

Future<void> showAccounts(BuildContext context,WidgetRef ref) async {
  await showModalBottomSheet<void>(context:context,backgroundColor:Colors.transparent,isScrollControlled:true,builder:(ctx)=>Glass(radius:30,padding:const EdgeInsets.all(20),child:SafeArea(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Your study accounts',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:12),
    ...ref.watch(subjectsProvider).map((s)=>ListTile(leading:CircleAvatar(backgroundColor:Color(s.tint).withValues(alpha:.22),child:Icon(Icons.menu_book,color:Color(s.tint))),title:Text(s.name),subtitle:Text(s.handle),trailing:ref.watch(activeSubjectProvider)==s.id?const Icon(Icons.check_circle,color:Colors.greenAccent):null,onTap:(){HapticFeedback.lightImpact();ref.read(activeSubjectProvider.notifier).state=s.id;Navigator.pop(ctx);})),
    const SizedBox(height:8),OutlinedButton.icon(onPressed:()=>_addSubject(ctx,ref),icon:const Icon(Icons.add),label:const Text('Add Subject Account'))
  ]))));
}
Future<void> _addSubject(BuildContext context,WidgetRef ref) async {
  final controller=TextEditingController();
  final name=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('New subject account'),content:TextField(controller:controller,autofocus:true,decoration:const InputDecoration(hintText:'Subject name')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:const Text('Create'))]));
  if(name==null||name.isEmpty)return;
  final s=Subject(id:StudyStore.newId(),name:name,handle:'@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'),'_')}',bio:'Your personal $name study feed',tint:Colors.primaries[ref.read(subjectsProvider).length%Colors.primaries.length].toARGB32());
  await StudyStore.saveSubject(s);ref.read(subjectsProvider.notifier).state=StudyStore.allSubjects;ref.read(activeSubjectProvider.notifier).state=s.id;
}
