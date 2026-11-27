import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../feed/models.dart';

class ParsedDocument {
  final String name;
  final List<String> sections,sources;
  const ParsedDocument(this.name,this.sections,this.sources);
  StudyPost toPost(String subjectId)=>StudyPost(id:DateTime.now().microsecondsSinceEpoch.toString(),subjectId:subjectId,sourceName:name,tag:_tag(name),createdAt:DateTime.now(),cards:sections,sources:sources);
  static String _tag(String name)=>name.split('.').first.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'),'').split(' ').take(2).join(' ');
}
class StudyParser {
  static String normalizeExtractedText(String input) {
    var text=input.replaceAll(RegExp(r'-\s*\n\s*'),'').replaceAll('\r\n','\n').replaceAll('\r','\n');
    final output=<String>[];
    for(final raw in text.split('\n')) {
      if(raw.trim().isEmpty){if(output.isNotEmpty&&output.last.isNotEmpty)output.add('');continue;}
      final line=raw.trimLeft();
      final structural=RegExp(r'^(?:#{1,6}\s|[-*•]\s|\d+[.)]\s)').hasMatch(line);
      final previousEndsSentence=output.isNotEmpty&&RegExp(r'[.!?:;)]$').hasMatch(output.last);
      final bulletOrNumber=line.startsWith(RegExp(r'[-*•]|\d+[.)]'));
      if(output.isNotEmpty&&output.last.isNotEmpty&&!structural&&!previousEndsSentence&&!bulletOrNumber){
        output[output.length-1]='${output.last} ${line.trim()}';
      }else{output.add(line);}
    }
    return output.join('\n').replaceAll(RegExp(r'\n{3,}'),'\n\n').trim();
  }
  static Future<ParsedDocument> parseFile(File file) async {
    final extension=file.path.split('.').last.toLowerCase();final bytes=await file.readAsBytes();
    switch(extension){
      case 'pdf':return parsePdf(bytes,file.uri.pathSegments.last);
      case 'pptx':return parsePptx(bytes,file.uri.pathSegments.last);
      case 'docx':return parseDocx(bytes,file.uri.pathSegments.last);
      case 'txt':case 'md':return parseText(utf8.decode(bytes,allowMalformed:true),file.uri.pathSegments.last);
      default:throw FormatException('Unsupported file type: .$extension');
    }
  }
  static ParsedDocument parsePdf(List<int> bytes,String name){
    final document=PdfDocument(inputBytes:bytes);final pages=<String>[];
    for(var i=0;i<document.pages.count;i++){final text=PdfTextExtractor(document).extractText(startPageIndex:i,endPageIndex:i);if(text.trim().isNotEmpty)pages.add(normalizeExtractedText(text));}
    document.dispose();
    return ParsedDocument(name,pages.isEmpty?['No selectable text found in this PDF. It may be scanned.']:pages,List.generate(pages.length,(i)=>'$name · Page ${i+1}'));
  }
  static ParsedDocument parsePptx(List<int> bytes,String name){
    final archive=ZipDecoder().decodeBytes(bytes);
    final slides=archive.files.where((f)=>RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name)).toList()..sort((a,b)=>_number(a.name).compareTo(_number(b.name)));
    final cards=<String>[],sources=<String>[];
    for(final slide in slides){final xml=XmlDocument.parse(utf8.decode(slide.content as List<int>));final text=xml.findAllElements('a:t').map((e)=>e.innerText).join('\n').trim();if(text.isNotEmpty){cards.add(normalizeExtractedText(text));sources.add('$name · Slide ${_number(slide.name)}');}}
    return ParsedDocument(name,cards.isEmpty?['No readable slide text found.']:cards,sources);
  }
  static ParsedDocument parseDocx(List<int> bytes,String name){
    final archive=ZipDecoder().decodeBytes(bytes);final entry=archive.files.firstWhere((f)=>f.name=='word/document.xml');final xml=XmlDocument.parse(utf8.decode(entry.content as List<int>));
    final paragraphs=xml.findAllElements('w:p').map((p)=>p.findAllElements('w:t').map((t)=>t.innerText).join()).where((s)=>s.trim().isNotEmpty);
    return parseText(paragraphs.join('\n\n'),name);
  }
  static ParsedDocument parseText(String text,String name){
    final blocks=normalizeExtractedText(text).split(RegExp(r'\n\s*\n')).where((s)=>s.trim().isNotEmpty);final cards=<String>[];var current=StringBuffer();
    for(final block in blocks){final first=block.split('\n').first;final heading=first.length<100&&(first.startsWith('#')||RegExp(r'^[A-Z0-9][^.!?]{0,70}$').hasMatch(first));if(heading&&current.isNotEmpty){cards.add(current.toString().trim());current=StringBuffer();}current.writeln(block.replaceAll(RegExp(r'^#{1,6}\s*'),''));current.writeln();}
    if(current.isNotEmpty)cards.add(current.toString().trim());final result=cards.isEmpty?['No text content found.']:cards;
    return ParsedDocument(name,result,List.generate(result.length,(i)=>'$name · Section ${i+1}'));
  }
  static int _number(String path)=>int.tryParse(RegExp(r'(\d+)').firstMatch(path)?.group(1)??'0')??0;
}