import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const YatinBikeRentApp());
}

class YatinBikeRentApp extends StatelessWidget {
  const YatinBikeRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yatin Bike Rent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

class BikeRentHomePage extends StatefulWidget {
  const BikeRentHomePage({super.key});

  @override
  State<BikeRentHomePage> createState() => _BikeRentHomePageState();
}

class _BikeRentHomePageState extends State<BikeRentHomePage> {
  final List<Bike> _bikes = [
    Bike(
      id: 'm1',
      name: 'City Cruiser',
      type: 'Urban',
      pricePerHour: 50,
      pricePerDay: 300,
      available: true,
      description: 'Smooth ride for city streets with a comfortable seat.',
    ),
    Bike(
      id: 'm2',
      name: 'Mountain Rider',
      type: 'MTB',
      pricePerHour: 80,
      pricePerDay: 500,
      available: true,
      description: 'Strong and reliable for off-road and rough terrain.',
    ),
    Bike(
      id: 'm3',
      name: 'Family Tandem',
      type: 'Tandem',
      pricePerHour: 120,
      pricePerDay: 700,
      available: false,
      description: 'Perfect for couples or family rides together.',
    ),
    Bike(
      id: 'm4',
      name: 'Electric Assist',
      type: 'E-Bike',
      pricePerHour: 100,
      pricePerDay: 650,
      available: true,
      description: 'Electric boost for easy rides with less effort.',
    ),
  ];

  final List<Booking> _bookings = [];
  int _selectedTab = 0;

  void _addBooking(Booking booking) {
    setState(() {
      _bookings.add(booking);
    });
  }

  @override
  void initState() {
    super.initState();
    addBike();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      BikesScreen(bikes: _bikes, onBook: _addBooking),
      BookingsScreen(bookings: _bookings),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Bike Rent Demo')),
      body: screens[_selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (value) {
          setState(() {
            _selectedTab = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pedal_bike_outlined),
            selectedIcon: Icon(Icons.pedal_bike),
            label: 'Bikes',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}

class BikesScreen extends StatelessWidget {
  const BikesScreen({super.key, required this.bikes, required this.onBook});

  final List<Bike> bikes;
  final void Function(Booking booking) onBook;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Available Bikes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Customers can see rent details, availability, and book directly from the app.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ...bikes.map((bike) => BikeCard(bike: bike, onBook: onBook)),
      ],
    );
  }
}

class BikeCard extends StatelessWidget {
  const BikeCard({super.key, required this.bike, required this.onBook});

  final Bike bike;
  final void Function(Booking booking) onBook;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pedal_bike, size: 40, color: Colors.teal),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bike.type,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(bike.available ? 'Available' : 'Unavailable'),
                  backgroundColor: bike.available
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(bike.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hour: ₹${bike.pricePerHour}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Day: ₹${bike.pricePerDay}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: bike.available
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await Navigator.of(context)
                              .push<Booking>(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BikeBookingPage(bike: bike),
                                ),
                              );
                          if (result != null) {
                            onBook(result);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Booked ${bike.name} successfully!',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.book_online),
                  label: const Text('Book Now'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(bike.name),
                          content: Text(
                            'Rent per hour ₹${bike.pricePerHour}\nRent per day ₹${bike.pricePerDay}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BikeBookingPage extends StatefulWidget {
  const BikeBookingPage({super.key, required this.bike});

  final Bike bike;

  @override
  State<BikeBookingPage> createState() => _BikeBookingPageState();
}

class _BikeBookingPageState extends State<BikeBookingPage> {
  String _rentType = 'Hour';
  int _duration = 1;
  DateTime _selectedDate = DateTime.now();

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  int get totalCost {
    return _rentType == 'Hour'
        ? widget.bike.pricePerHour * _duration
        : widget.bike.pricePerDay * _duration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.bike.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.bike.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.bike.description),
            const SizedBox(height: 24),
            const Text(
              'Choose rental type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [_rentType == 'Hour', _rentType == 'Day'],
              onPressed: (index) {
                setState(() {
                  _rentType = index == 0 ? 'Hour' : 'Day';
                  _duration = 1;
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Hour'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Day'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Duration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text('$_duration ${_rentType.toLowerCase()}(s)'),
              ],
            ),
            Slider(
              min: 1,
              max: _rentType == 'Hour' ? 12 : 7,
              divisions: _rentType == 'Hour' ? 11 : 6,
              value: _duration.toDouble(),
              label: '$_duration',
              onChanged: (value) {
                setState(() {
                  _duration = value.toInt();
                });
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _selectDate,
              child: Text(
                'Pickup date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Total cost: ₹$totalCost',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final booking = Booking(
                  bike: widget.bike,
                  rentType: _rentType,
                  duration: _duration,
                  date: _selectedDate,
                  totalCost: totalCost,
                );
                Navigator.of(context).pop(booking);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Confirm Booking', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key, required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No bookings yet. Select a bike and book to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.bike.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${booking.rentType} booking for ${booking.duration} ${booking.rentType.toLowerCase()}(s)',
                ),
                const SizedBox(height: 6),
                Text(
                  'Pickup date: ${booking.date.day}/${booking.date.month}/${booking.date.year}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Total paid: ₹${booking.totalCost}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Bike {
  final String id;
  final String name;
  final String type;
  final int pricePerHour;
  final int pricePerDay;
  final bool available;
  final String description;

  Bike({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.available,
    required this.description,
  });
}

class Booking {
  final Bike bike;
  final String rentType;
  final int duration;
  final DateTime date;
  final int totalCost;

  Booking({
    required this.bike,
    required this.rentType,
    required this.duration,
    required this.date,
    required this.totalCost,
  });
}
