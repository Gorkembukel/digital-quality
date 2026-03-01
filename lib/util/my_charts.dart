//metrikler ile alakalı widgetlar burada belirlenecek


import 'package:dashbord/util/constant.dart';
import 'package:flutter/material.dart';

class MymetricTile extends StatefulWidget{
  const MymetricTile({super.key});

  @override
  State<MymetricTile> createState() => _MymetricTileState();
}

class _MymetricTileState extends State<MymetricTile> {
  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        
        decoration: BoxDecoration(
          color: defaultPrimaryColor,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: const Color.fromARGB(202, 134, 187, 229),
          ),
        )
      ),
    );
  }
}