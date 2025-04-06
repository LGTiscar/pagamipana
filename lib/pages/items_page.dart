import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ItemsPage extends StatefulWidget {
  final List<Map<String, dynamic>> items; // OCR JSON items
  final List<String> people; // List of people added in step 2
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ItemsPage({
    super.key,
    required this.items,
    required this.people,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final Map<String, Map<String, int>> itemAssignments = {}; // Tracks assignments per item
  final Logger logger = Logger(); // Logger for debugging

  @override
  void initState() {
    super.initState();
    logger.i('Initializing itemAssignments...');
    for (var item in widget.items) {
      logger.d('Initializing item: ${item['name']}');
      itemAssignments[item['name']] = {
        for (var person in widget.people) person: 0,
      };
    }
    logger.i('itemAssignments initialized: $itemAssignments');
  }

  void _incrementAssignment(String itemName, String person, int maxQuantity) {
    setState(() {
      if (itemAssignments[itemName]![person]! < maxQuantity) {
        itemAssignments[itemName]![person] =
            itemAssignments[itemName]![person]! + 1;
        logger.d('Incremented $person for $itemName: ${itemAssignments[itemName]}');
      }
    });
  }

  void _decrementAssignment(String itemName, String person) {
    setState(() {
      if (itemAssignments[itemName]![person]! > 0) {
        itemAssignments[itemName]![person] =
            itemAssignments[itemName]![person]! - 1;
        logger.d('Decremented $person for $itemName: ${itemAssignments[itemName]}');
      }
    });
  }

  int _getTotalAssigned(String itemName) {
    if (!itemAssignments.containsKey(itemName)) {
      logger.e('itemAssignments does not contain key: $itemName');
      return 0;
    }
    if (itemAssignments[itemName]!.values.isEmpty) {
      logger.e('itemAssignments[$itemName] has no values');
      return 0;
    }
    final totalAssigned = itemAssignments[itemName]!.values.reduce((a, b) => a + b);
    logger.d('Total assigned for $itemName: $totalAssigned');
    return totalAssigned;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Step 3: Assign Items to People',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select who participated in each item',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final itemName = item['name'];
              final quantity = item['quantity'];
              final unitPrice = item['unitPrice'];
              final isShareable = item['isShareable'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              itemName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Text('Shared'),
                              Switch(
                                value: isShareable,
                                onChanged: (value) {
                                  setState(() {
                                    item['isShareable'] = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Quantity: $quantity'),
                          Text('Unit price: €${unitPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (quantity > 1 && isShareable)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: widget.people.map((person) {
                            final assigned = itemAssignments[itemName]?[person] ?? 0;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      child: Text(person[0].toUpperCase()),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(person),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if (assigned > 0) {
                                          setState(() {
                                            itemAssignments[itemName]![person] =
                                                assigned - 1;
                                            logger.d(
                                                'Decremented $person for $itemName: ${itemAssignments[itemName]}');
                                          });
                                        }
                                      },
                                    ),
                                    Text('$assigned'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: assigned < quantity
                                          ? () {
                                              setState(() {
                                                itemAssignments[itemName]![person] =
                                                    assigned + 1;
                                                logger.d(
                                                    'Incremented $person for $itemName: ${itemAssignments[itemName]}');
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      if (quantity > 1 && !isShareable)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: widget.people.map((person) {
                            final assigned = itemAssignments[itemName]?[person] ?? 0;
                            final totalAssigned = _getTotalAssigned(itemName);
                            final remaining = quantity - totalAssigned;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      child: Text(person[0].toUpperCase()),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(person),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () =>
                                          _decrementAssignment(itemName, person),
                                    ),
                                    Text('$assigned'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: remaining > 0
                                          ? () => _incrementAssignment(
                                              itemName, person, quantity)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      if (!isShareable)
                        Text(
                          'Individual counts: ${_getTotalAssigned(itemName)} of $quantity units assigned',
                          style: TextStyle(
                            color: _getTotalAssigned(itemName) == quantity
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
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
