class Lo$project {
  const Lo$project(this.id, {this.dir = ''});
  final String id;
  final String dir;
}

class Lo$file {
  const Lo$file(this.id, this.project, {this.path = ''});
  final Lo$project project;
  final String id;
  final String path;
}

class Lo$msg {
  const Lo$msg(this.id, this.msg, this.file, {this.descr = ''});
  final Lo$file file;
  final String id;
  final String msg;
  final String descr;
  String get loc => msg;
}
