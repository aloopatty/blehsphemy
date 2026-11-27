class Subject {
  final String id;
  final String name;
  final String handle;
  final String bio;
  final int tint;

  const Subject({required this.id, required this.name, required this.handle, required this.bio, required this.tint});

  factory Subject.sample({required String id, required String name, required String handle, required int tint}) =>
      Subject(id: id, name: name, handle: handle, bio: 'Your $name study space', tint: tint);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'handle': handle, 'bio': bio, 'tint': tint};

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    id: map['id'] as String,
    name: map['name'] as String,
    handle: map['handle'] as String,
    bio: map['bio'] as String? ?? '',
    tint: map['tint'] as int,
  );
}
