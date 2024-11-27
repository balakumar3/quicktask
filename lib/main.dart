import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quicktask/login.dart';
import 'package:intl/intl.dart'; // Import the intl package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "lib/.env");

  var keyApplicationId = dotenv.env['B4A_APPLICATION_ID'];
  var keyClientKey = dotenv.env['B4A_CLIENT_KEY'];
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId!, keyParseServerUrl,
      clientKey: keyClientKey, autoSendSessionId: true);

  Widget initialScreen = LoginPage();

  runApp(MaterialApp(home: initialScreen));
}

class QuickTaskApp extends StatefulWidget {
  const QuickTaskApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _QuickTaskAppState createState() => _QuickTaskAppState();
}

class _QuickTaskAppState extends State<QuickTaskApp> {
  List<ParseObject> tasks = [];
  TextEditingController taskController = TextEditingController();
  TextEditingController editTaskController = TextEditingController();
  TextEditingController dueDateController = TextEditingController();
  TextEditingController editDueDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getTasks();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: const Color.fromARGB(255, 255, 255, 255),
          hintColor: const Color.fromARGB(255, 156, 245, 96),
          scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
          appBarTheme:
              AppBarTheme(backgroundColor: Color.fromARGB(255, 138, 43, 226))),
      home: Scaffold(
        appBar: AppBar(
            title: const Text('QuickTask',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0))),
            backgroundColor: Color.fromARGB(255, 138, 43, 226),
            centerTitle: true),
        body: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTaskInput(),
              const SizedBox(height: 20),
              Expanded(child: _buildTaskList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInput() {
    DateTime? selectedDate;
    // Function to pick date
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != selectedDate) {
        selectedDate = picked;
        dueDateController.text = "${selectedDate!.toLocal()}"
            .split(' ')[0]; // Formatting the date to show in TextField
      }
    }

    // Function to show a dialog if no date is selected
    Future<void> _showDateRequiredDialog(BuildContext context) async {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Please enter due date"),
            content: const Text(
                "You must select a due date before adding the task."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: taskController,
            decoration: InputDecoration(
              hintText: 'Task',
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          TextField(
            controller: dueDateController,
            readOnly:
                true, // Make it read-only since it's being set via date picker
            decoration: InputDecoration(
              hintText: 'Select Due Date',
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () => _selectDate(context), // Show date picker on tap
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: () {
              addTask();
              // Handle task submission logic here (e.g., store task, selected date, etc.)
              if (selectedDate != null) {
                // Make sure to pass the selected date to your task logic
              } else {
                // Handle case where no date is selected (optional)
                // _showDateRequiredDialog(context);
              }
            },
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white)),
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final varTask = tasks[index];
        final varTitle = varTask.get('title') ?? '';
        final varDueDate = varTask.get('dueDate') ?? '';
        bool done = varTask.get<bool>('done') ?? false;
        DateTime? selectedDate = varDueDate.isNotEmpty
            ? DateTime.tryParse(varDueDate)
            : DateTime.now();

        // Function to show date picker for due date
        Future<void> _selectDate(BuildContext context) async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (picked != null && picked != selectedDate) {
            selectedDate = picked;
            editDueDateController.text =
                "${selectedDate!.toLocal()}".split(' ')[0]; // Format the date
          }
        }

        return ListTile(
          title: Row(
            children: [
              Checkbox(
                value: done,
                onChanged: (newValue) {
                  updateTask(index, newValue!, varTitle, varDueDate);
                },
              ),
              Expanded(child: Text(varTitle)),
              Expanded(child: Text(varDueDate)),
              IconButton(
                icon: const Icon(Icons.edit,
                    color: Color.fromARGB(255, 0, 162, 255)),
                onPressed: () {
                  // Open edit dialog with updated logic
                  _showEditDialog(context, varTask, index);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    color: Color.fromARGB(255, 255, 0, 0)),
                onPressed: () {
                  deleteTask(index, varTask.objectId!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show edit dialog
  void _showEditDialog(BuildContext context, ParseObject task, int index) {
    final TextEditingController titleController =
        TextEditingController(text: task.get('title') ?? '');
    final TextEditingController dateController =
        TextEditingController(text: task.get('dueDate') ?? '');
    DateTime? selectedDate = DateTime.tryParse(task.get('dueDate') ?? '');

    Future<void> _selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != selectedDate) {
        selectedDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Task Title',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select Due Date',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _selectDate,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              editTask(
                context,
                index,
                task.get('done') ?? false,
                titleController.text.trim(),
                selectedDate != null
                    ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                    : task.get('dueDate'),
              );
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 170, 0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 223, 2, 2)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addTask() async {
    String task = taskController.text.trim();
    String dueDate = dueDateController.text.trim();
    print('print task $task $dueDate');
    if (task.isEmpty || dueDate.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please enter ${task.isEmpty ? 'Task!' : 'Due Date!'}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      var newTask = ParseObject('Task')
        ..set('title', task)
        ..set('dueDate', dueDate)
        ..set('done', false);

      var response = await newTask.save();

      if (response.success) {
        setState(() {
          tasks.add(newTask);
        });
        taskController.clear();
        dueDateController.clear();
      }
    }
  }

  Future<void> updateTask(
      int index, bool done, String varTitle, String varDueDate) async {
    final varTask = tasks[index];
    final String id = varTask.objectId.toString();

    var updatedTask = ParseObject('Task')
      ..objectId = id
      ..set('title', varTitle)
      ..set('dueDate', varDueDate)
      ..set('done', done);

    var response = await updatedTask.save();

    if (response.success) {
      setState(() {
        tasks[index] = updatedTask;
      });
    }
  }

  Future<void> editTask(
      context, int index, bool done, String varTitle, String varDueDate) async {
    final varTask = tasks[index];
    final String id = varTask.objectId.toString();

    var updatedTask = ParseObject('Task')
      ..objectId = id
      ..set('title', varTitle)
      ..set('dueDate', varDueDate)
      ..set('done', done);

    var response = await updatedTask.save();

    if (response.success) {
      setState(() {
        tasks[index] = updatedTask;
      });
      Navigator.of(context).pop();
    }
  }

  Future<void> getTasks() async {
    var queryBuilder = QueryBuilder<ParseObject>(ParseObject('Task'));
    var apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.results != null) {
      setState(() {
        tasks = apiResponse.results as List<ParseObject>;
      });
    }
  }

  Future<void> deleteTask(int index, String id) async {
    var deletedTask = ParseObject('Task')..objectId = id;
    var response = await deletedTask.delete();

    if (response.success) {
      setState(() {
        tasks.removeAt(index);
      });
    }
  }
}
