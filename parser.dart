import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../feed/models.dart';

class ParsedDocument {
  final String name;
  final List<String> sections;
  final List<String> sources;
  const ParsedDocument(this.name,this.sections,this.sources);
  StudyPost toPost(String subjectId) => StudyPost(id:DateTime.now().microsecondsSinceEpoch.toString(),subjectId:subjectId,sourceName:name,tag:_tag(name),createdAt:DateTime.now(),cards:sections,sources:sources);
  static String _tag(String name) => name.split('.').first.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'),'').split(' ').take(2).join(' ');
}

class StudyParser {
  static Future<ParsedDocument> parseFile(File file) async {
    final ext=file.path.split('.').last.toLowerCase();
    final bytes=await file.readAsBytes();
    switch(ext) {
      case 'pdf': return parsePdf(bytes,file.uri.pathSegments.last);
      case 'pptx': return parsePptx(bytes,file.uri.pathSegments.last);
      case 'docx': return parseDocx(bytes,file.uri.pathSegments.last);
      case 'txt': case 'md': return parseText(utf8.decode(bytes,allowMalformed:true),file.uri.pathSegments.last);
      default: throw FormatException('Unsupported file type: .$ext');
    }
  }
  static ParsedDocument parsePdf(List<int> bytes,String name) {
    final doc=PdfDocument(inputBytes:bytes);
    final pages=<String>[];
    for(var i=0;i<doc.pages.count;i++) {
      final text=PdfTextExtractor(doc).extractText(startPageIndex:i,endPageIndex:i);
      if(text.trim().isNotEmpty) pages.add(text.trim());
    }
    doc.dispose();
    return ParsedDocument(name,pages.isEmpty?['No selectable text found in this PDF. It may be scanned.']:pages,List.generate(pages.length,(i)=>'$name · Page ${i+1}'));
  }
  static ParsedDocument parsePptx(List<int> bytes,String name) {
    final zip=ZipDecoder().decodeBytes(bytes);
    final slideFiles=zip.files.where((f)=>RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name)).toList()
      ..sort((a,b)=>_number(a.name).compareTo(_number(b.name)));
    final cards=<String>[],sources=<String>[];
    for(final slide in slideFiles) {
      final xml=XmlDocument.parse(utf8.decode(slide.content as List<int>));
      final text=xml.findAllElements('a:t').map((e)=>e.innerText).join('\n').trim();
      if(text.isNotEmpty) { cards.add(text); sources.add('$name · Slide ${_number(slide.name)}'); }
    }
    // Notes are appended as a separate card when present, keeping the slide attribution.
    final notes=zip.files.where((f)=>RegExp(r'^ppt/notesSlides/notesSlide\d+\.xml$').hasMatch(f.name)).toList()
      ..sort((a,b)=>_number(a.name).compareTo(_number(b.name)));
    for(final note in notes) {
      final xml=XmlDocument.parse(utf8.decode(note.content as List<int>));
      final text=xml.findAllElements('a:t').map((e)=>e.innerText).join(' ').trim();
      final cleaned=text.replaceAll(RegExp(r'\s+'),' ');
      if(cleaned.length>20 && !cleaned.contains('Slide number')) {
        cards.add('Speaker notes\n\n$cleaned'); sources.add('$name · Notes ${_number(note.name)}');
      }
    }
    return ParsedDocument(name,cards.isEmpty?['No readable slide text found.']:cards,sources);
  }
  static ParsedDocument parseDocx(List<int> bytes,String name) {
    final zip=ZipDecoder().decodeBytes(bytes);
    final entry=zip.files.firstWhere((f)=>f.name=='word/document.xml');
    final xml=XmlDocument.parse(utf8.decode(entry.content as List<int>));
    final paras=xml.findAllElements('w:p').map((p)=>p.findAllElements('w:t').map((t)=>t.innerText).join()).where((s)=>s.trim().isNotEmpty).toList();
    return parseText(paras.join('\n\n'),name);
  }
  static ParsedDocument parseText(String text,String name) {
    final blocks=text.split(RegExp(r'\n\s*\n')).map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();
    final cards=<String>[];
    var current=StringBuffer();
    for(final block in blocks) {
      final isHeading=block.split('\n').first.length<100 && (block.startsWith('#') || RegExp(r'^[A-Z0-9][^.!?]{0,70}$').hasMatch(block.split('\n').first));
      if(isHeading && current.isNotEmpty) { cards.add(current.toString().trim()); current=StringBuffer(); }
      current.writeln(block.replaceAll(RegExp(r'^#{1,6}\s*'),''));
      current.writeln();
    }
    if(current.isNotEmpty) cards.add(current.toString().trim());
    final compact=cards.isEmpty?['No text content found.']:cards;
    return ParsedDocument(name,compact,List.generate(compact.length,(i)=>'$name · Section ${i+1}'));
  }
  static int _number(String path)=>int.tryParse(RegExp(r'(\d+)').firstMatch(path)?.group(1)??'0')??0;
}
