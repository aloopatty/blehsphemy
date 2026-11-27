import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studygram/features/upload/parser.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('StudyParser', () {
    test('splits text/Markdown into sections and strips heading markers', () {
      final doc = StudyParser.parseText('# Thermodynamics\n\nHeat is energy transfer.\n\n## Entropy\n\nA state function.', 'notes.md');
      expect(doc.sections.length, greaterThanOrEqualTo(2));
      expect(doc.sections.first, contains('Thermodynamics'));
      expect(doc.sections.last, contains('Entropy'));
    });

    test('empty text has a fallback card', () {
      expect(StudyParser.parseText('', 'empty.txt').sections, ['No text content found.']);
    });

    test('extracts slide text from a minimal PPTX archive', () {
      final archive = Archive();
      final xmlBytes = utf8.encode('<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:t>Slide title</a:t><a:t>Bullet point</a:t></p:sld>');
      archive.addFile(ArchiveFile('ppt/slides/slide1.xml', xmlBytes.length, xmlBytes));
      final bytes = ZipEncoder().encode(archive)!;
      final parsed = StudyParser.parsePptx(bytes, 'lecture.pptx');
      expect(parsed.sections.single, contains('Slide title'));
      expect(parsed.sections.single, contains('Bullet point'));
    });

    test('extracts text from a one-page PDF', () {
      final pdf = PdfDocument();
      pdf.pages.add().graphics.drawString('Offline PDF text', PdfStandardFont(PdfFontFamily.helvetica, 12));
      final bytes = pdf.saveSync();
      pdf.dispose();
      final parsed = StudyParser.parsePdf(bytes, 'handout.pdf');
      expect(parsed.sections.single, contains('Offline PDF text'));
    });
  });
}
