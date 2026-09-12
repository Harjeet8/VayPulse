import 'package:flutter/material.dart';
import '../services/farmer_language.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';
import 'settings_screen.dart';
class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});
  @override
  Widget build(BuildContext context){final ta=FarmerLanguage.isTamil(context);
    final steps=<({IconData icon,String en,String tamil,String body,String bodyTa,Color color})>[
      (icon:Icons.spa_outlined,en:'Choose your plant',tamil:'செடியைத் தேர்ந்தெடுக்கவும்',body:'Use one plant and give it a name in the care diary. Keep its notes and photos together.',bodyTa:'ஒரு செடிக்கு பெயரிட்டு அதன் குறிப்புகளையும் படங்களையும் ஒன்றாக சேமிக்கவும்.',color:const Color(0xFF397353)),
      (icon:Icons.water_drop_outlined,en:'Place the soil sensor',tamil:'மண் சென்சாரை வைக்கவும்',body:'Place the sensing part in the soil near the roots. Keep the circuit and connectors dry.',bodyTa:'வேருக்கு அருகில் உணரும் பகுதியை மண்ணில் வைக்கவும். மின்சுற்றையும் இணைப்புகளையும் உலர்வாக வைக்கவும்.',color:const Color(0xFF367F98)),
      (icon:Icons.wb_sunny_outlined,en:'Let air and light reach the sensors',tamil:'காற்றும் ஒளியும் சென்சாரை அடையட்டும்',body:'Keep the air and light sensors uncovered. Follow your hardware mounting instructions.',bodyTa:'காற்று மற்றும் ஒளி சென்சாரை மூட வேண்டாம். கருவியின் பொருத்தும் வழிமுறைகளைப் பின்பற்றவும்.',color:const Color(0xFFAC772F)),
      (icon:Icons.wifi_rounded,en:'Connect your device',tamil:'கருவியை இணைக்கவும்',body:'For local readings, connect to the ESP32 Wi-Fi. For remote readings, choose Firebase in Settings. Wait for a fresh reading.',bodyTa:'உள்ளூர் அளவீடுகளுக்கு ESP32 Wi-Fi-இல் இணையவும். தொலைவிலிருந்து பார்க்க அமைப்புகளில் Firebase-ஐ தேர்ந்தெடுக்கவும். புதிய அளவீட்டுக்குக் காத்திருக்கவும்.',color:const Color(0xFF657596)),
      (icon:Icons.hearing_outlined,en:'Read or listen to the advice',tamil:'ஆலோசனையைப் படிக்கவும் அல்லது கேட்கவும்',body:'Open Plant Care. Check the problem and the next action. If a sensor needs checking, fix that first.',bodyTa:'செடி பராமரிப்பைத் திறந்து பிரச்சினையையும் செய்ய வேண்டியதையும் பார்க்கவும். சென்சாரைச் சரிபார்க்கச் சொன்னால் முதலில் அதைச் செய்யவும்.',color:const Color(0xFFAC654F)),
    ];
    return Scaffold(appBar:AppBar(title:Text(ta?'தொடங்குவோம்':'Getting started')),body:PageFrame(children:[
      PhytoPageIntro(eyebrow:ta?'எளிய படிகள்':'A FEW SIMPLE STEPS',title:ta?'செடியைப் புரிந்துகொள்ளுங்கள்':'Meet your plant',body:ta?'ஒருமுறை அமைத்து தினமும் எளிதாகப் பார்க்கவும்.':'Set up once. Make everyday checks easier.',icon:Icons.explore_outlined),
      const SizedBox(height:20),
      for(var i=0;i<steps.length;i++)Padding(padding:const EdgeInsets.only(bottom:16),child:PhytoSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(height:100,width:double.infinity,decoration:BoxDecoration(color:steps[i].color.withValues(alpha:.12),borderRadius:BorderRadius.circular(16)),child:Icon(steps[i].icon,size:52,color:steps[i].color)),
        const SizedBox(height:16),Text('${i+1}. ${ta?steps[i].tamil:steps[i].en}',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),Text(ta?steps[i].bodyTa:steps[i].body),
      ]))),
      FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen())),child:Text(ta?'இணைப்பு அமைப்புகள்':'Connection settings')),
    ]));
  }
}
