import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';

class CreateGroupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    String? userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Groups'),

      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'My Groups',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: userId != null ? MyGroupsList(userId) : CircularProgressIndicator(),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'create_group_fab',
              onPressed: () {
                // Navigate to the page for creating a new group
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateNewGroupPage()),
                );
              },
              child: Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'invite_people_fab',
              onPressed: () {
                // Navigate to the page for sending invitations
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InvitationsPage(userId: userId!),
                  ),
                );
              },
              child: Icon(Icons.insert_invitation_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationData {

  Map<String ,dynamic> address;
  final String addressName;

  LocationData({

    required this.address,
    required this.addressName,
  });
}

class CreateNewGroupPage extends StatefulWidget {
  const CreateNewGroupPage({Key? key}) : super(key: key);

  @override
  _CreateNewGroupPageState createState() => _CreateNewGroupPageState();
}

class _CreateNewGroupPageState extends State<CreateNewGroupPage> {
  final TextEditingController groupNameController = TextEditingController();
  LocationData? pickedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Group'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: groupNameController,
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to the location selection page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyMapPage(),
                ),
              ).then((pickedData) {
                // Handle the picked data when returning from the map page
                setState(() {
                  pickedLocation = pickedData;
                });
              });
            },
            child: Text('Select Location'),
          ),
          Spacer(), // Use Spacer to push the button to the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                // Get the current user's ID
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  String userId = user.uid;
                  String groupName = groupNameController.text;
                  if (groupName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a group name.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  if (pickedLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a location.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  try {
                    await FirebaseFirestore.instance.collection('groups').add({
                      'groupName': groupName,
                      'groupLocation': {
                        'address': pickedLocation!.address,
                        'addressName': pickedLocation!.addressName,
                      },
                      'users': [userId],
                      'checkedInUsers': [],
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group created successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    print('Error creating group: $e');
                  }
                } else {
                  print('No user signed in.');
                }
              },
              child: Text('Create Group'),
            ),
          ),
        ],
      ),
    );
  }
}

class MyMapPage extends StatefulWidget {
  const MyMapPage({Key? key}) : super(key: key);

  @override
  State<MyMapPage> createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Page'),
      ),
      body: OpenStreetMapSearchAndPick(
        buttonColor: Colors.blue,
        buttonText: 'Set Location',
        onPicked: (pickedData) {
          // Navigate back to the create page and pass the picked data
          Navigator.pop(
            context,
            LocationData(

              address: pickedData.address,
              addressName: pickedData.addressName,
            ),
          );
        },
      ),
    );
  }
}


class MyGroupsList extends StatelessWidget {
  final String userId;

  MyGroupsList(this.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<QueryDocumentSnapshot<Map<String, dynamic>>> groupDocs = snapshot.data!.docs;


        List<QueryDocumentSnapshot<Map<String, dynamic>>> userGroups = groupDocs.where((groupDoc) {
          List<dynamic> users = groupDoc['users'];
          return users.contains(userId);
        }).toList();

        return ListView.builder(
          itemCount: userGroups.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupDetails(groupDoc: userGroups[index])),
                  );
                },
                child: Text(userGroups[index]['groupName']),
              ),
              trailing: Icon(Icons.arrow_circle_right_outlined),
            );
          },
        );
      },
    );
  }
}

class GroupDetails extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> groupDoc;

  const GroupDetails({Key? key, required this.groupDoc}) : super(key: key);

  @override
  _GroupDetailsState createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  String? currentUserId;
  late bool isCheckedIn = false;
  String? groupAddressName;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          currentUserId = user.uid;
        });
        checkIsCheckedIn();
      }
    });
    getGroupAddressName();
  }

  void getGroupAddressName() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> groupSnapshot =
      await widget.groupDoc.reference.get();
      if (groupSnapshot.exists) {
        Map<String, dynamic> groupData = groupSnapshot.data()!;
        Map<String, dynamic> groupLocation = groupData['groupLocation'];
        setState(() {
          groupAddressName = groupLocation['addressName'];
        });
      }
    } catch (e) {
      print('Error fetching group address name: $e');
    }
  }


  void checkIsCheckedIn() async {
    if (currentUserId != null) {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        Map<String, dynamic> userData = userSnapshot.data()!;
        isCheckedIn = userData['isCheckedIn'] ?? false;
      } else {
        isCheckedIn = false;
      }

      setState(() {});
    }
  }

  void toggleCheckIn() async {
    isCheckedIn = !isCheckedIn;
    try {
      if (isCheckedIn) {
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupDoc.id).update({
          'checkedInUsers': FieldValue.arrayUnion([currentUserId]),
        });
      } else {
        await FirebaseFirestore.instance.collection('groups').doc(widget.groupDoc.id).update({
          'checkedInUsers': FieldValue.arrayRemove([currentUserId]),
        });
      }
    } catch (e) {
      print('Error toggling check-in: $e');
    }
    setState(() {});
  }

  void toggleCheckOut() async {
    isCheckedIn = false;
    try {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupDoc.id).update({
        'checkedInUsers': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      print('Error toggling check-out: $e');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupDoc['groupName']),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: widget.groupDoc.reference.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          Map<String, dynamic> groupData = snapshot.data!.data()!;
          String addressName = groupData['groupLocation']['addressName'];
          List<dynamic> userIds = groupData['users'];
          List<dynamic> checkedInUsers = groupData['checkedInUsers'];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Address: ${addressName?? 'Unknown'}', // Display the group address name
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Checked-in Users',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () {
                            toggleCheckIn();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel_outlined, color: Colors.red),
                          onPressed: () {
                            toggleCheckOut();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: checkedInUsers.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance.collection('users').doc(checkedInUsers[index]).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          Map<String, dynamic> userData = snapshot.data!.data()!;
                          String username = userData['username'];

                          return ListTile(
                            title: Text(username),
                            trailing: Icon(Icons.check_circle, color: Colors.green),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Users',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: userIds.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance.collection('users').doc(userIds[index]).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          Map<String, dynamic> userData = snapshot.data!.data()!;
                          String username = userData['username'];

                          return ListTile(
                            title: Text(username),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InvitePage2(groupDoc: widget.groupDoc)),
          );
        },
        child: Icon(Icons.person_add),
      ),

    );
  }
}



class InvitationsPage extends StatelessWidget {
  final String userId;

  const InvitationsPage({Key? key, required this.userId}) : super(key: key);

  Future<String?> fetchGroupName(String? groupId) async {
    if (groupId == null) return null;

    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        return groupDoc['groupName'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting group name: $e');
      return null;
    }
  }
  Future<String?> fetchUsername(String? senderId) async {
    if (senderId == null) return null;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (userDoc.exists) {
        return userDoc['username'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  Future<void> acceptInvitation(String groupId, String senderId) async {
    try {
      // Add the user to the group's users list
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update(
          {
            'users': FieldValue.arrayUnion([userId]),
          });

      // Remove the invitation
      await removeInvitation(groupId, senderId);
    } catch (e) {
      print('Error accepting invitation: $e');
    }
  }

  Future<void> declineInvitation(String groupId, String senderId) async {
    try {
      // Remove the invitation
      await removeInvitation(groupId, senderId);
    } catch (e) {
      print('Error declining invitation: $e');
    }
  }

  Future<void> removeInvitation(String groupId, String senderId) async {
    try {
      // Remove the invitation
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'invitations': FieldValue.arrayRemove(
            [{'groupId': groupId, 'senderId': senderId}]),
      });
    } catch (e) {
      print('Error removing invitation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitations'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return Center(
              child: Text('No data available'),
            );
          }

          // Get user data
          Map<String, dynamic>? userData = snapshot.data!.data() as Map<
              String,
              dynamic>?;

          if (userData == null || !userData.containsKey('invitations')) {
            return Center(
              child: Text('No invitations'),
            );
          }

          // Get invitations list
          List<dynamic>? invitations = userData['invitations'];

          return ListView.builder(
            itemCount: invitations?.length ?? 0,
            itemBuilder: (context, index) {
              var invitation = invitations![index] as Map<String, dynamic>;
              return FutureBuilder<String?>(
                future: fetchGroupName(invitation['groupId']),
                builder: (context, groupNameSnapshot) {
                  if (groupNameSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                      subtitle: Text(invitation['senderId'] ?? 'No Sender ID'),
                      trailing: ElevatedButton(
                        onPressed: () {

                        },
                        child: Text('Accept'),
                      ),
                    );
                  }
                  if (groupNameSnapshot.hasError ||
                      groupNameSnapshot.data == null) {
                    return ListTile(
                      title: Text('Error loading group name'),
                      subtitle: Text(invitation['senderId'] ?? 'No Sender ID'),
                      trailing: ElevatedButton(
                        onPressed: () {

                        },
                        child: Text('Accept'),
                      ),
                    );
                  }

                  return FutureBuilder<String?>(
                    future: fetchUsername(invitation['senderId']),
                    builder: (context, usernameSnapshot) {
                      if (usernameSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          title: Text(
                              groupNameSnapshot.data ?? 'Unknown Group'),
                          subtitle: Text('Loading...'),
                          trailing: ElevatedButton(
                            onPressed: () {

                            },
                            child: Text('Accept'),
                          ),
                        );
                      }
                      if (usernameSnapshot.hasError || usernameSnapshot.data ==
                          null) {
                        return ListTile(
                          title: Text(
                              groupNameSnapshot.data ?? 'Unknown Group'),
                          subtitle: Text('Error loading username'),
                          trailing: ElevatedButton(
                            onPressed: () {

                            },
                            child: Text('Accept'),
                          ),
                        );
                      }

                      // Inside the ListView.builder
                      return ListTile(
                        title: Text(groupNameSnapshot.data ?? 'Unknown Group'),
                        subtitle: Text(
                            usernameSnapshot.data ?? 'Unknown Sender'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (invitation['groupId'] != null &&
                                    invitation['senderId'] != null) {
                                  acceptInvitation(invitation['groupId'],
                                      invitation['senderId']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Invitation accepted'),
                                    ),
                                  );
                                }
                              },
                              child: Text('Accept'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (invitation['groupId'] != null &&
                                    invitation['senderId'] != null) {
                                  declineInvitation(invitation['groupId'],
                                      invitation['senderId'] ?? '');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Invitation declined'),
                                    ),
                                  );
                                }
                              },
                              child: Text('Decline'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

  class InvitePage2 extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> groupDoc;

  const InvitePage2({Key? key, required this.groupDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invite People'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          List<DocumentSnapshot> users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              String email = (users[index].data() as Map<String,
                  dynamic>?)?['email'] ?? '';
              String username = (users[index].data() as Map<String,
                  dynamic>?)?['username'] ?? '';


              return ListTile(
                title: Text(username),
                leading: IconButton(
                  icon: Icon(Icons.email),
                  onPressed: () {
                    String userId = users[index].id;
                    String groupId = groupDoc.id;
                    addInvitation(email, userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent to $username'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }



  void addInvitation(String email, String userId) async {

    String groupId = groupDoc.id;
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Get the current invitations array of the user
    DocumentSnapshot userSnapshot = await userRef.get();
    List<dynamic> invitations = (userSnapshot.data() as Map<String, dynamic>)['invitations'] ?? [];
    String? senderId = FirebaseAuth.instance.currentUser?.uid;

    Map<String, dynamic> newInvitation = {
      'senderId': senderId,
      'groupId': groupId,
    };
    invitations.add(newInvitation);


    await userRef.update({'invitations': invitations});
  }

}
