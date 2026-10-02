//Hands-on Exercise 03
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
//model
class Note {
  final int? id;
  final String title;
  final String content;
  final String createdAt;
  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'content': content,
    'created_at': createdAt,
  };
  factory Note.fromMap(Map<String, Object?> map) => Note(
    id: map['id'] as int,
    title: map['title'] as String,
    content: map['content'] as String,
    createdAt: map['created_at'] as String,
  );
}
//database
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static const String _dbName = 'notes_app.db';
  static const String _table = 'notes';
  Future<Database>? _dbFuture;
  Future<Database> get database => _dbFuture ??= _initDatabase();
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }
  //create
  Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert(_table, note.toMap());
  }
  //read
  Future<List<Note>> getNotes() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'id DESC');
    return rows.map((row) => Note.fromMap(row)).toList();
  }
  //update
  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      _table,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }
  //delete
  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
//app entry
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
//home page
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadNotes();
  }
  Future<void> _loadNotes() async {
    try {
      final notes = await _db.getNotes();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }
  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
  Future<void> _addOrEditNote([Note? existing]) async {
    final result = await showDialog<Note>(
      context: context,
      builder: (_) => NoteDialog(note: existing),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await _db.insertNote(result);
        _showMessage('Note added');
      } else {
        await _db.updateNote(result);
        _showMessage('Note updated');
      }
      await _loadNotes();
    } catch (e) {
      _showMessage('Could not save the note: $e');
    }
  }
  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('"${note.title}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.deleteNote(note.id!);
      _showMessage('Note deleted');
      await _loadNotes();
    } catch (e) {
      _showMessage('Could not delete the note: $e');
    }
  }
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Database error: $_error\n\n'
                'On Chrome, run "dart run sqflite_common_ffi_web:setup" in the '
                'project terminal, then restart the app.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_notes.isEmpty) {
      return const Center(
        child: Text('No notes yet. Tap "Add note" to create one.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${note.content}\n${note.createdAt}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _addOrEditNote(note),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteNote(note),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes (${_notes.length})'),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditNote(),
        icon: const Icon(Icons.add),
        label: const Text('Add note'),
      ),
    );
  }
}
//add / edit dialogue
class NoteDialog extends StatefulWidget {
  final Note? note;
  const NoteDialog({super.key, this.note});
  @override
  State<NoteDialog> createState() => _NoteDialogState();
}
class _NoteDialogState extends State<NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool get _isEditing => widget.note != null;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  String _now() => DateTime.now().toString().substring(0, 16);
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Note(
        id: widget.note?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.note?.createdAt ?? _now(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit note' : 'Add note'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter some content'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}