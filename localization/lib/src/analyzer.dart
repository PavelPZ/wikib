import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/session.dart' as sessions;
import 'package:analyzer/dart/analysis/utilities.dart' as utils;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:protobuf_for_dart/algorithm.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:protobuf/protobuf.dart';
import 'package:path/path.dart' as p;

const drive = r'd:';
const root = '$drive\\wikibulary\\localize\\data';
const transDBNewFile = '$root\\transDBNew.bin'; // export from dart code

final projects = <TransDB_Project>[
  TransDB_Project()
    ..id = 1
    ..dir = 'wikib\\wikib\\lib',
];

List<SyntacticEntity> _flatten_tree(AstNode n, [int depth = 9999999]) {
  var que = [];
  que.add(n);
  var nodes = <SyntacticEntity>[];
  int nodes_count = que.length;
  int dep = 0;
  int c = 0;
  if (depth == 0) return [n];
  while (que.isNotEmpty) {
    var node = que.removeAt(0);
    if (node is! AstNode) continue;
    for (var cn in node.childEntities) {
      nodes.add(cn);
      que.add(cn);
    }
    //Keeping track of how deep in the tree
    ++c;
    if (c == nodes_count) {
      ++dep; // One layer done
      if (depth <= dep) return nodes;
      c = 0;
      nodes_count = que.length;
    }
  }
  return nodes;
}

class MethodCall {
  MethodCall(this.name, this.id, this.par);
  final String name;
  final int id;
  final String par;
}

class MethodCalls {
  MethodCall? file;
  MethodCall? project;
  final items = <MethodCall>[];
}

MethodCalls _parseDart(CompilationUnit unit) {
  final nodes = _flatten_tree(unit);
  final res = MethodCalls();
  for (var node in nodes) {
    if (node is! MethodInvocation || !node.methodName.name.startsWith('Lo\$')) continue;
    final args = node.argumentList.arguments;
    final name = node.methodName.name;
    final c = MethodCall(name, (args[0] as IntegerLiteral).value!, (args[1] as SimpleStringLiteral).value);
    if (name == 'Lo\$file') {
      assert(res.file == null);
      res.file = c;
    } else if (name == 'Lo\$project') {
      assert(res.project == null);
      res.project = c;
    } else if (name == 'Lo\$msg') {
      res.items.add(c);
    } else
      assert(false);
  }
  return res;
}

void main() async {
  final transDB = TransDB();
  for (var p in projects) {
    final project = p.deepCopy();
    transDB.projects[project.id.toString()] = project;
    final prefix = '$drive\\${project.dir}';
    //https://github.com/dart-lang/sdk/blob/master/pkg/analyzer/doc/tutorial/analysis.md
    AnalysisContextCollection collection = new AnalysisContextCollection(includedPaths: [prefix]);
    for (AnalysisContext context in collection.contexts) {
      for (String path in context.contextRoot.analyzedFiles()) {
        sessions.AnalysisSession session = context.currentSession;
        final pp = await session.getParsedLibrary(path);
        if (pp is! ParsedLibraryResult) continue;
        final filePath = path.substring(prefix.length + 1);
        TransDB_File? file;
        for (var un in pp.units) {
          // if (path == r'd:\wikib\wikib\lib\world\world.dart') {
          //   if (path == '') return;
          // }
          final calls = _parseDart(un.unit);
          if (calls.project == null && calls.file == null && calls.items.isEmpty) continue;
          if (calls.project != null) {
            assert(calls.project!.id == project.id, 'calls.project.${calls.project!.id} == project.${project.id}');
          }
          if (un.path == path && calls.file != null) {
            assert(file == null, 'file == null ($path)');
            assert(filePath == calls.file!.par, 'filePath ($filePath) == calls.file.${calls.file!.par}');
            file = TransDB_File()
              ..projectId = project.id
              ..id = calls.file!.id
              ..path = filePath;
            project.files[file.id.toString()] = file;
          }
          for (var c in calls.items) {
            assert(file != null, 'file != null ($path)');
            assert(c.name == 'Lo\$msg', 'c.name=${c.name}');
            final msgId = '${project.id}/${file!.id}/${c.id}';
            assert(!transDB.items.containsKey(msgId), '!transDB.items.containsKey($msgId)');
            transDB.items[msgId] = TransDB_Item()
              ..projectId = project.id
              ..fileId = file.id
              ..id = c.id
              ..enSrcMsg = c.par;
          }
        }
      }
    }
  }
  final bin = transDB.writeToBuffer();
  var f = File(transDBNewFile);
  if (f.existsSync()) f.deleteSync();
  f.writeAsBytesSync(bin, flush: true);
  final str = jsonEncode(transDB.toProto3Json());
  f = File(p.setExtension(transDBNewFile, '.json'));
  if (f.existsSync()) f.deleteSync();
  f.writeAsStringSync(str, flush: true);
  return;

  String content = '''
const lo\$project = Lo\$project(1, r'/wikib/wikib/lib');
const _lo\$file = Lo\$file(2, r'main.dart', lo\$project);

final t = Text(Lo\$msg(3, 'Hi, how are you?', _lo\$file).loc);
final _msg = Lo\$msg(4, 'Hi, how are you?', _lo\$file).loc;
final t2 = Text('\${Lo\$msg(5, 'Hi, how are you?', _lo\$file).loc}');

''';
  ParseStringResult result = utils.parseString(content: content, throwIfDiagnostics: false);
  final nodes = _flatten_tree(result.unit);
  final calls = <MethodCall>[];
  for (var node in nodes) {
    if (node is! MethodInvocation || !node.methodName.name.startsWith('Lo\$')) continue;
    final args = node.argumentList.arguments;
    calls.add(MethodCall(node.methodName.name, (args[0] as IntegerLiteral).value!, (args[1] as SimpleStringLiteral).value));
  }
  final invoc = nodes
      .where((e) =>
          (e is MethodInvocation && e.methodName.name.startsWith('Lo\$')) || (e is FunctionTypedFormalParameter && e.identifier.name == 'Lo\$msg'))
      .toList();
  final res = result.unit.toSource();
  return;
}
