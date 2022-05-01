import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo-App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Todo-App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.black,
          ),
        ),
        body: const ListDisplay());
  }
}

class ListDisplay extends StatefulWidget {
  const ListDisplay({Key? key}) : super(key: key);

  @override
  State createState() => DynamicList();
}

class Todo {
  String name;
  bool isDone;
  int id;

  Todo(this.name, this.isDone, this.id);

  Map<String, dynamic> toJson() => {
        'name': name,
        'isDone': isDone,
        'id': id,
      };

  Todo.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        isDone = json['isDone'] as bool,
        id = json['id'] as int;
}

class TodoHandler {
  var prefs;
  static const key = 'todoList';
  List<Todo> todos = [];

  TodoHandler();

  setPrefs(SharedPreferences prefs) {
    this.prefs = prefs;
    if (!prefs.containsKey(key)) {
      prefs.setString(key, "[]");
    } else {
      todos = getTodos();
    }
  }


  List<Todo> getTodos() {
    final jsonString = prefs.getString(key);
    final json = jsonDecode(jsonString);
    final todos = List<Todo>.from(json.map((todo) => Todo.fromJson(todo)));
    return todos;
  }

  void addTodo(Todo todo) {
    // check if todo with same id already exists
    Todo newTodo = todo;
    if (todoExists(todo)) {
      int id = todo.id;
      while (todoExists(newTodo)) {
        newTodo = Todo(todo.name, todo.isDone, id);
        id++;
      }
    }
    todos.add(newTodo);
    final json = jsonEncode(todos);
    prefs.setString(key, json);
  }

  removeTodo(Todo todo) {
    todos.remove(todo);
    final json = jsonEncode(todos);
    prefs.setString(key, json);
  }

  updateTodo(Todo oldTodo, Todo newTodo) {
    todos.removeWhere((todo) => todo.id == oldTodo.id);
    todos.add(newTodo);
    final json = jsonEncode(todos);
    prefs.setString(key, json);
  }

  tickTodo(Todo todo) {
    todo.isDone = !todo.isDone;
    if (!todo.isDone) {
      todos.remove(todo);
    }
    final json = jsonEncode(todos);
    prefs.setString(key, json);
  }

  bool todoExists(Todo todo) {
    return todos.where((t) => t.id == todo.id).toList().isNotEmpty;
  }

  getDoneTodos() {
    return todos.where((t) => t.isDone).toList();
  }

  getUndoneTodos() {
    return todos.where((t) => !t.isDone).toList();
  }
}

class DynamicList extends State<ListDisplay> {
  final TodoHandler todoHandler = TodoHandler();
  List<Todo> undoneTodos = [];
  List<Todo> doneTodos = [];
  final TextEditingController eCtrl = TextEditingController();


  @override
  Widget build(BuildContext ctxt) {
    SharedPreferences.getInstance().then((prefs) {
      todoHandler.setPrefs(prefs);
      undoneTodos = todoHandler.getUndoneTodos();
      doneTodos = todoHandler.getDoneTodos();
      setState(() {});
    });
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
              controller: eCtrl,
              style: const TextStyle(fontSize: 20),
              textAlignVertical: TextAlignVertical.center,
              // controller: eCtrl,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  prefixIcon: const Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "New Todo ",
                      style: TextStyle(
                        // color: Color(0xFF474747),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.greenAccent),
                  ),
                  suffixIcon: Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (eCtrl.text.isNotEmpty) {
                            Todo todo = Todo(eCtrl.text, false, undoneTodos.length + doneTodos.length + 1);
                            todoHandler.addTodo(todo);
                            eCtrl.clear();
                          }
                          setState(() {});
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Save"),
                      ))),
              onSubmitted: (String text) {
                if (text.isNotEmpty) {
                  Todo todo = Todo(text, false, undoneTodos.length + doneTodos.length + 1);
                  todoHandler.addTodo(todo);
                  eCtrl.clear();
                }
                setState(() {});
              })),
          Expanded(
              child: ListView.separated(
                  itemCount: undoneTodos.length + doneTodos.length,
                  itemBuilder: (context, index) => Container(
                    child: InkWell(
                      child: ListTile(
                        title: Text(
                            index < undoneTodos.length
                                ? undoneTodos[index].name
                                : doneTodos[index - undoneTodos.length].name
                        ),
                        leading: Checkbox(
                          value: index < undoneTodos.length
                              ? undoneTodos[index].isDone
                              : doneTodos[index - undoneTodos.length].isDone,
                          fillColor: MaterialStateProperty.all(Colors.grey),
                          onChanged: (value) {
                            setState(() {
                              if (index < undoneTodos.length) {
                                todoHandler.tickTodo(undoneTodos[index]);
                              } else {
                                todoHandler.tickTodo(doneTodos[index - undoneTodos.length]);
                              }
                            });
                          },
                        ),
                      ),
                      onTap: () {
                        if (index < undoneTodos.length) {
                          todoHandler.tickTodo(undoneTodos[index]);
                        } else {
                          todoHandler.tickTodo(doneTodos[index - undoneTodos.length]);
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  separatorBuilder: (context, index) => Container(
                    child: Text("Erledigte Todos", style: TextStyle(fontSize: index == undoneTodos.length -1 ? 16: 0)),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: index == undoneTodos.length -1 ? Colors.grey : Colors.transparent,
                                width: index == undoneTodos.length - 1
                                    ? 1
                                    : 0,
                                style: BorderStyle.solid

                            ))),
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  )
              ))
        ]);
  }
}