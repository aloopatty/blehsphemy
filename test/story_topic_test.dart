import 'package:flutter_test/flutter_test.dart';
import 'package:studygram/features/stories/story_viewer.dart';
void main(){
 test('extracts concise story topic',()=>expect(storyTopicLabel('Unit Testing: verify each method independently.'),'Unit Testing'));
 test('category monograms are contextual',(){expect(storyMonogram('Exam question: explain Agile'),'Q?');expect(storyMonogram('Formula F = ma'),'∑');});
}
