class Subject {
  final String id, name, handle, bio;
  final int tint;
  final bool sample;
  final DateTime? deadline;
  final String? deadlineName;
  const Subject({required this.id, required this.name, required this.handle, required this.bio, required this.tint, this.sample = false, this.deadline, this.deadlineName});

  factory Subject.sample({required String id, required String name, required String handle, required int tint}) =>
    Subject(id:id, name:name, handle:handle, tint:tint, sample:true, bio:'Sample account • Tap + to add your own study material');

  Map<String,dynamic> toMap() => {'id':id,'name':name,'handle':handle,'bio':bio,'tint':tint,'sample':sample,'deadline':deadline?.toIso8601String(),'deadlineName':deadlineName};
  factory Subject.fromMap(Map<String,dynamic> m) => Subject(id:m['id'], name:m['name'], handle:m['handle'], bio:m['bio'] ?? '', tint:m['tint'] ?? 0xFF9B8CFF, sample:m['sample'] ?? false, deadline:m['deadline']==null?null:DateTime.parse(m['deadline']), deadlineName:m['deadlineName']);
}
