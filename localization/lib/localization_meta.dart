class Lo$project {
  const Lo$project(this.id, this.dir);
  final int id;
  final String dir;
}

class Lo$file {
  const Lo$file(this.id, this.path, this.project);
  final Lo$project project;
  final int id;
  final String path;
}

class Lo$msg {
  const Lo$msg(this.id, this.msg, this.file);
  final Lo$file file;
  final int id;
  final String msg;
  String get loc => msg;
}
