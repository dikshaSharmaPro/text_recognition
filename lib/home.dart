import 'package:flutter/material.dart';

import 'package:testrecognition/textscanner.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Recognition'),),
      body: Center(
        child: ElevatedButton(onPressed: 
        (){
         Navigator.push(context, MaterialPageRoute(builder: (context)=>const TextScanner()));
      
        }, child: const Text("Click to scan")),
      ),
    
      
    );
  }
}