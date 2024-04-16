import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';



class MyLocationPage extends StatefulWidget {
  @override
  _MyLocationPageState createState() => _MyLocationPageState();
}

class _MyLocationPageState extends State<MyLocationPage> {
  Position? _currentPosition;
  List<DocumentSnapshot> _nearbyUsers = [];


  Future<void> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentPosition = null;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentPosition = null;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentPosition = null;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      await _saveCurrentLocation(position);
      await getNearbyUsers(_currentPosition!,5000);

    } catch (e) {
      debugPrint('e as String?');
    }
  }

  Future<void> _saveCurrentLocation(Position position) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      GeoPoint userLocation = GeoPoint(position.latitude, position.longitude);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'currentLocation': userLocation});
    } catch (e) {
      debugPrint('Error saving current location: $e');
    }
  }

  Future<void> getNearbyUsers(Position position, double radius) async {
    try {
      GeoPoint center = GeoPoint(position.latitude, position.longitude);
      double radiusInDegrees = radius / 111000; // 111000 meters in one degree

      // Define the boundaries of the query
      double minLat = center.latitude - radiusInDegrees;
      double maxLat = center.latitude + radiusInDegrees;
      double minLng = center.longitude - radiusInDegrees;
      double maxLng = center.longitude + radiusInDegrees;

      // Execute the query
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('currentLocation.latitude',  isGreaterThanOrEqualTo : minLat)
          .where('currentLocation.latitude', isLessThanOrEqualTo: maxLat)
          .where('currentLocation.longitude', isGreaterThanOrEqualTo: minLng)
          .where('currentLocation.longitude', isLessThanOrEqualTo: maxLng)
          .get();

      // Handle the query results
      List<DocumentSnapshot> documents = querySnapshot.docs;
      for (DocumentSnapshot document in documents) {
        // Process each document as needed
        print('User ID: ${document.id}');
        // Access other fields using document.data()['fieldName']
      }
    } catch (e) {
      // Handle any errors that occur during the query
      print('Error fetching users: $e');

    }
  }


  Future<void> _fetchNearbyUsers(Position position) async {
    try {
      double radius = 5000; // Define the radius in meters (adjust as needed)
      GeoPoint center = GeoPoint(position.latitude, position.longitude);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('currentLocation', isGreaterThan: center)
          .where('currentLocation', isLessThan: center)
          .get();

      setState(() {
        _nearbyUsers = querySnapshot.docs;
      });
      List<DocumentSnapshot> documents = querySnapshot.docs;
      for (DocumentSnapshot document in documents) {
        // Process each document as needed
        print('User ID: ${document.id}');
        // Access other fields using document.data()['fieldName']
      }
    } catch (e) {
      debugPrint('Error fetching nearby users: $e');
    }
  }

  Future<void> _fetchNearbyUsers2(Position position) async {
    try {
      GeoPoint center = GeoPoint(position.latitude, position.longitude);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('currentLocation', isEqualTo: center)
          .get();

      setState(() {
        _nearbyUsers = querySnapshot.docs;
      });
      List<DocumentSnapshot> documents = querySnapshot.docs;
      for (DocumentSnapshot document in documents) {
        // Process each document as needed
        print('User ID: ${document.id}');
        // Access other fields using document.data()['fieldName']
      }
    } catch (e) {
      debugPrint('Error fetching nearby users: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('My Location'),
            // Map icon
            SizedBox(width: 8), // Add some spacing between the icon and the title text
            Icon(Icons.location_on_rounded),
          ],
        ),
      ),
      body: Center(
        child: _currentPosition == null
            ? CircularProgressIndicator()
            : Text('Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}'),
      ),
    );
  }
}
