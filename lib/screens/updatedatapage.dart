import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class UpdateDataPage extends StatefulWidget {
  @override
  _UpdateDataState createState() => _UpdateDataState();
}

class _UpdateDataState extends State<UpdateDataPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? _username; 
  @override
  void initState() {
    super.initState();
    _fetchUsername(); 
  }

  // Function to fetch the username from Firestore
  Future<void> _fetchUsername() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
       
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          _username = userData['username']; 
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Username', hintText: _username ?? 'Username'), 
                readOnly: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditUsernamePage(currentUsername: _username ?? ''),
                    ),
                  ).then((newUsername) {
                    if (newUsername != null) {
                      setState(() {
                        _username = newUsername;
                      });
                    }
                  });

                 
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Email', hintText: user?.email ?? 'Email'),
                readOnly: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateEmailPage(),
                      ),
                  );

                 
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpdatePasswordPage()),
                );
               
              },
              child: Text('Change Password'),
            ),
            SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}


class EditUsernamePage extends StatefulWidget {
  final String currentUsername; \

  EditUsernamePage({required this.currentUsername});

  @override
  _EditUsernamePageState createState() => _EditUsernamePageState();
}

class _EditUsernamePageState extends State<EditUsernamePage> {
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Username'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'New Username'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Implement logic to update username in Firestore
                String newUsername = _usernameController.text;

                // Get the current user's document ID or user ID
                String userId = FirebaseAuth.instance.currentUser!.uid;

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({'username': newUsername});

                  // Navigate back to the profile page
                  Navigator.pop(context, newUsername);
                } catch (e) {
                  print('Error updating username: $e');
                  // Handle error
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}


class UpdateEmailPage extends StatefulWidget {
  @override
  _UpdateEmailPageState createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends State<UpdateEmailPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _newEmail = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Email'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'New Email Address'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _newEmail = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final user = _auth.currentUser;
                      if (user != null) {
                        await user.verifyBeforeUpdateEmail(_newEmail);
                        //await user.updateEmail(_newEmail);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Email updated successfully'),
                        ));
                      }
                    } catch (e) {
                      print('Error updating email: $e');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error updating email: $e'),
                      ));
                    }
                  }
                },
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class UpdatePasswordPage extends StatefulWidget {
  @override
  _UpdatePasswordPageState createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await user.updatePassword(_newPasswordController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password updated successfully'),
                          ),
                        );
                        // Navigate back to the previous page
                        Navigator.pop(context);
                      }
                    } catch (error) {
                      print('Error updating password: $error');
                      if (error is FirebaseAuthException && error.code == 'weak-password') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password is too weak. Please choose a stronger password.'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating password: $error'),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
