//server ya da client olarak mı çalışacak bunu seçtiğimiz yer 

import 'package:dashbord/pages/client_page.dart';
import 'package:dashbord/pages/server_page.dart';
import 'package:flutter/material.dart';
import '../util/constant.dart' ;

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Client or Server')),
        backgroundColor: defaultAppbarColor,
      ) ,
      backgroundColor: defaultBacground,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            //Server button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServerPage(),
                  ),
                );
              },
              child: Container(
                width: 200,
                height: 100,              
                padding: EdgeInsets.all(8),              
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.indigo,
              
                ),
                child: Center(child: Text('S E R V E R'))
                ),
            ),
            
            //Client Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientPage(),
                  ),
                );
              },
              child: Container(
                width: 200,
                height: 100,              
                padding: EdgeInsets.all(8),              
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.green[100],
              
                ),
                child: Center(child: Text('C L I E N T'))
                ),
            )
          ],
        ),
      ),
    );
  }
  
}