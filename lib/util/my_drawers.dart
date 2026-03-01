import 'dart:developer' as dev;

import 'package:dashbord/providers/app_provider.dart';
import 'package:flutter/material.dart';

class NotificationDrawer extends StatelessWidget {
  //burada notificationları almalı
  const NotificationDrawer({super.key, required AppProvider provider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      child: Column(
        children: const [
          DrawerHeader(
            child: Text(
              "Notifications",
              style: TextStyle(fontSize: 20),
            ),
          ),
          ListTile(
            leading: Icon(Icons.message),
            title: Text("New message received"),
          ),
          ListTile(
            leading: Icon(Icons.warning),
            title: Text("Server disconnected"),
          ),
        ],
      ),
    );
  }
}

class MyDrawer extends StatelessWidget {
  const MyDrawer();

  
  @override
  Widget build(BuildContext context) {
   
    
    return Drawer(
      shape: BoxBorder.all(),
      backgroundColor: Colors.lightGreen[300],
      child: Column(
        spacing: 8,
         children: [
          
         ],
        
      ),
      
    );
    
  }
 
}