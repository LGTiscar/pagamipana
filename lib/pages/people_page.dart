import 'package:flutter/material.dart';

class PeoplePage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;

  const PeoplePage({super.key, required this.onBack, required this.onNext});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final List<String> people = [];
  String? payer;

  final TextEditingController nameController = TextEditingController();

  void _addPerson() {
    final name = nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        people.add(name);
        nameController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Step 2: Add People to Split With',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add everyone who\'s splitting the bill',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Add person\'s name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addPerson,
              child: const Text('+ Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (people.isNotEmpty)
          Column(
            children: [
              const Text(
                'Who paid the bill?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: payer,
                hint: const Text('Select a person'),
                items: people.map((person) {
                  return DropdownMenuItem(
                    value: person,
                    child: Text(person),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    payer = value;
                  });
                },
              ),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            ElevatedButton.icon(
              onPressed: widget.onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
