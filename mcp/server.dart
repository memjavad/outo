import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A simple implementation of an MCP server in Dart.
/// This server follows the Model Context Protocol (MCP) standards.
void main() async {
  final server = McpServer();
  await server.start();
}

class McpServer {
  final Map<String, dynamic> _tools = {
    'get_project_stats': {
      'description': 'Returns statistics about the current project.',
      'parameters': {
        'type': 'object',
        'properties': {},
      },
    },
    'analyze_code': {
      'description': 'Runs dart analyze on the project.',
      'parameters': {
        'type': 'object',
        'properties': {},
      },
    },
  };

  Future<void> start() async {
    stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleMessage);
  }

  void _handleMessage(String message) {
    try {
      final request = jsonDecode(message) as Map<String, dynamic>;
      final id = request['id'];
      final method = request['method'];

      if (method == 'list_tools') {
        _sendResponse(id, {'tools': _tools.values.toList()});
      } else if (method == 'call_tool') {
        final params = request['params'] as Map<String, dynamic>;
        final toolName = params['name'];
        _handleToolCall(id, toolName, params['arguments'] ?? {});
      } else {
        _sendError(id, -32601, 'Method not found');
      }
    } catch (e) {
      // Handle parsing errors
    }
  }

  void _handleToolCall(dynamic id, String toolName, Map<String, dynamic> args) async {
    if (toolName == 'get_project_stats') {
      final libDir = Directory('lib');
      final files = libDir.listSync(recursive: true).whereType<File>();
      final lineCount = files.fold(0, (sum, file) => sum + file.readAsLinesSync().length);
      
      _sendResponse(id, {
        'content': [
          {
            'type': 'text',
            'text': 'Project Stats:\nTotal files: ${files.length}\nTotal lines of code: $lineCount',
          }
        ]
      });
    } else if (toolName == 'analyze_code') {
      final result = await Process.run('dart', ['analyze']);
      _sendResponse(id, {
        'content': [
          {
            'type': 'text',
            'text': result.stdout.toString() + result.stderr.toString(),
          }
        ]
      });
    } else {
      _sendError(id, -32602, 'Tool not found');
    }
  }

  void _sendResponse(dynamic id, Map<String, dynamic> result) {
    stdout.writeln(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    }));
  }

  void _sendError(dynamic id, int code, String message) {
    stdout.writeln(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    }));
  }
}
