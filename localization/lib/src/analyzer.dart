import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/session.dart' as sessions;
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
    ..id = 'w'
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
  MethodCall(this.name, this.id);
  final String name;
  final String id;
  String par = '';
  String descr = '';
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
    final c = MethodCall(name, (args[0] as SimpleStringLiteral).value);
    if (args.length > 1 && args[1] is SimpleStringLiteral) c.par = (args[1] as SimpleStringLiteral).value;
    if (args.length > 3 && args[3] is NamedExpression) c.descr = ((args[3] as NamedExpression).expression as SimpleStringLiteral).value;
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
    transDB.projects[project.id] = project;
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
          final fromDart = _parseDart(un.unit);
          if (fromDart.project == null && fromDart.file == null && fromDart.items.isEmpty) continue;
          if (fromDart.project != null) {
            assert(fromDart.project!.id == project.id, 'calls.project.${fromDart.project!.id} == project.${project.id}');
          }
          if (un.path == path && fromDart.file != null) {
            assert(file == null, 'file == null ($path)');
            file = TransDB_File()
              ..projectId = project.id
              ..id = fromDart.file!.id
              ..path = filePath;
            project.files[file.id] = file;
          }
          for (var c in fromDart.items) {
            assert(file != null, 'file != null ($path)');
            assert(c.name == 'Lo\$msg', 'c.name=${c.name}');
            final msgId = '${project.id}~${file!.id}~${c.id}';
            assert(!transDB.items.containsKey(msgId), '!transDB.items.containsKey($msgId)');
            transDB.items[msgId] = TransDB_Item()
              ..projectId = project.id
              ..fileId = file.id
              ..id = c.id
              ..enSrcMsg = c.par
              ..enSrcDescr = c.descr;
          }
        }
      }
    }
  }
  // check unique '$en_src_msg~$en_src_descr'
  final checkHash = <String, TransDB_Item>{};
  for (var it in transDB.items.values) {
    final poolId = '${it.enSrcMsg}~${it.enSrcDescr}';
    final oldIt = checkHash[poolId];
    assert(oldIt == null, '[enSrcMsg~enSrcDescr duplicity: ${it.projectId}~${it.fileId}~${it.id} and ${oldIt.projectId}~${oldIt.fileId}~${oldIt.id}');
    checkHash[poolId] = it;
  }
  // write for CSharp
  final bin = transDB.writeToBuffer();
  var f = File(transDBNewFile);
  if (f.existsSync()) f.deleteSync();
  f.writeAsBytesSync(bin, flush: true);
  final str = jsonEncode(transDB.toProto3Json());
  f = File(p.setExtension(transDBNewFile, '.json'));
  if (f.existsSync()) f.deleteSync();
  f.writeAsStringSync(str, flush: true);
}
