import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/app_scope.dart';
import '../services/care_journal.dart';
import '../services/farmer_language.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

class CareJournalScreen extends StatefulWidget {
  const CareJournalScreen({super.key});
  @override
  State<CareJournalScreen> createState()=>_CareJournalScreenState();
}
class _CareJournalScreenState extends State<CareJournalScreen> {
  final journal=CareJournal();
  List<CareEntry> entries=[];
  bool busy=true, photosOnly=false;
  String? error;
  String t(String en,String ta)=>FarmerLanguage.isTamil(context)?ta:en;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load() async {
    try {final data=await journal.load();if(mounted)setState((){entries=data;busy=false;error=null;});}
    catch(_){if(mounted)setState((){busy=false;error='Could not read the diary. Your saved data has not been changed.';});}
  }
  Future<void> _run(Future<void> Function() action) async {
    setState(()=>busy=true);
    try{await action();await _load();}catch(_){if(mounted)setState((){busy=false;error=t('Could not finish. Please try again.','முடிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.');});}
  }
  Future<void> _add(String kind) async {
    final scope=AppScope.of(context);
    final plant=scope.sensors.current?.nodeId ?? scope.farms.selectedField.crop;
    const source='manual';
    String? photo;
    if(kind=='photo') {
      final file=await ImagePicker().pickImage(source:ImageSource.camera,maxWidth:900,maxHeight:900,imageQuality:65);
      if(file==null)return;
      final bytes=await file.readAsBytes();
      if(bytes.length>600000)throw StateError('Photo too large');
      photo=base64Encode(bytes);
    }
    if(!mounted)return;
    final controller=TextEditingController();
    final plantController=TextEditingController(text:plant);
    final note=await showDialog<String>(context:context,builder:(context)=>AlertDialog(
      title:Text(t('Record plant care','பராமரிப்பைப் பதிவு செய்யுங்கள்')),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:plantController,maxLength:100,decoration:InputDecoration(labelText:t('Plant name','செடியின் பெயர்'))),
        TextField(controller:controller,maxLength:500,minLines:2,maxLines:4,decoration:InputDecoration(labelText:t('Add a note (optional)','குறிப்பு (விருப்பம்)'))),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(t('Cancel','ரத்து'))),FilledButton(onPressed:()=>Navigator.pop(context,controller.text),child:Text(t('Save','சேமி')))],
    ));
    final name=plantController.text.trim();
    // Controllers belong to the dialog route; dispose after its exit animation.
    Future<void>.delayed(const Duration(seconds:1),(){controller.dispose();plantController.dispose();});
    if(note==null)return;
    final now=DateTime.now();
    await journal.add(CareEntry(id:now.microsecondsSinceEpoch.toString(),plant:name.isEmpty?plant:name,source:source,kind:kind,note:note,time:now,photo:photo));
  }
  String label(String kind)=>switch(kind){
    'water'=>t('Watered the plant','செடிக்குத் தண்ணீர் ஊற்றினேன்'),
    'check'=>t('Checked the sensor','சென்சாரைச் சரிபார்த்தேன்'),
    'photo'=>t('Plant photo','செடியின் படம்'),
    _=>t('Care note','பராமரிப்பு குறிப்பு'),
  };
  Future<void> _remind(CareEntry entry) async {
    final choice=await showModalBottomSheet<int>(context:context,showDragHandle:true,builder:(context)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
      Padding(padding:const EdgeInsets.all(16),child:Text(t('When should we remind you?','எப்போது நினைவூட்ட வேண்டும்?'),style:Theme.of(context).textTheme.titleLarge)),
      for(final hours in [1,6,24])ListTile(leading:const Icon(Icons.schedule_rounded),title:Text(t('In $hours hours','$hours மணி நேரத்தில்')),onTap:()=>Navigator.pop(context,hours)),
    ])));
    if(choice==null)return;
    await const MethodChannel('ai.phytosense.app/notifications').invokeMethod('requestPermission');
    final id=int.parse(entry.id).remainder(2000000000);
    final ok=await CareJournal.remind(DateTime.now().add(Duration(hours:choice)),t('Check ${entry.plant} again. Open the app for fresh readings.','${entry.plant} செடியை மீண்டும் பார்க்கவும். புதிய அளவீடுகளுக்கு செயலியைத் திறக்கவும்.'),id);
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ok?t('Reminder set. Delivery time may vary with battery settings.','நினைவூட்டல் அமைக்கப்பட்டது. பேட்டரி அமைப்பால் நேரம் மாறலாம்.'):t('Allow notifications in phone settings to use reminders.','நினைவூட்டலுக்கு அறிவிப்பு அனுமதியை வழங்கவும்.'))));
  }
  @override
  Widget build(BuildContext context) {
    final shown=entries.where((e)=>!photosOnly||e.photo!=null).toList();
    return Scaffold(appBar:AppBar(title:Text(t('Care diary','பராமரிப்பு பதிவு')),actions:[
      PopupMenuButton<String>(onSelected:(v)=>_run(()async{
        if(v=='backup'){await journal.backup();}else{await journal.restoreFile();}
      }),itemBuilder:(_)=>[PopupMenuItem(value:'backup',child:Text(t('Save backup','காப்புப்பிரதி சேமி'))),PopupMenuItem(value:'restore',child:Text(t('Restore backup','காப்புப்பிரதியை மீட்டெடு')))]),
    ]),body:PageFrame(children:[
      PhytoPageIntro(eyebrow:t('SMALL ACTIONS, LASTING CARE','தினசரி பராமரிப்பு'),title:t('Your plant’s story','உங்கள் செடியின் கதை'),body:t('Keep care notes and photos together. A saved action does not change the plant’s health result.','குறிப்புகளையும் படங்களையும் சேமிக்கவும். பதிவு செய்த செயல் செடியின் நிலையை மாற்றாது.'),icon:Icons.auto_stories_outlined),
      const SizedBox(height:20),
      Wrap(spacing:8,runSpacing:8,children:[
        for(final kind in ['water','check','photo','note'])ActionChip(avatar:Icon(switch(kind){'water'=>Icons.water_drop_outlined,'check'=>Icons.sensors_outlined,'photo'=>Icons.add_a_photo_outlined,_=>Icons.edit_note_rounded}),label:Text(label(kind)),onPressed:busy?null:()=>_run(()=>_add(kind))),
      ]),
      const SizedBox(height:20),
      SegmentedButton<bool>(segments:[ButtonSegment(value:false,label:Text(t('All care','அனைத்தும்'))),ButtonSegment(value:true,label:Text(t('Photo timeline','படங்கள்')))],selected:{photosOnly},onSelectionChanged:(s)=>setState(()=>photosOnly=s.first)),
      const SizedBox(height:16),
      if(busy)const LinearProgressIndicator(),
      if(error!=null)PhytoStatePanel(icon:Icons.info_outline,title:t('Please try again','மீண்டும் முயற்சி'),body:error!,actionLabel:t('Retry','மீண்டும்'),onAction:_load),
      if(!busy&&shown.isEmpty)PhytoStatePanel(icon:Icons.spa_outlined,title:t('Every plant has a story','ஒவ்வொரு செடிக்கும் ஒரு கதை'),body:t('Add your first care note or take a photo. You can use this diary without a sensor.','முதல் குறிப்பை அல்லது படத்தைச் சேர்க்கவும். சென்சார் இல்லாமலும் பயன்படுத்தலாம்.')),
      for(final e in shown)Padding(padding:const EdgeInsets.only(bottom:14),child:PhytoSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(e.plant,style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:4),
        Text('${DateFormat.yMMMd().add_jm().format(e.time.toLocal())} · ${e.source=="simulation"?t("Simulation","சிமுலேஷன்"):t("Care record","பராமரிப்பு பதிவு")}',style:Theme.of(context).textTheme.bodySmall),
        const SizedBox(height:10),Text(label(e.kind),style:Theme.of(context).textTheme.titleMedium),
        if(e.note.isNotEmpty)...[const SizedBox(height:6),Text(e.note)],
        if(e.photo!=null)...[const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.memory(base64Decode(e.photo!),height:220,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Text(t('Photo unavailable','படம் கிடைக்கவில்லை'))))],
        Wrap(spacing:8,children:[TextButton.icon(onPressed:busy?null:()=>_run(()=>_remind(e)),icon:const Icon(Icons.notifications_active_outlined),label:Text(t('Remind me','நினைவூட்டு'))),TextButton.icon(onPressed:()async{await CareJournal.platform.invokeMethod('cancelReminder',{'id':int.parse(e.id).remainder(2000000000)});if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('Reminder cancelled','நினைவூட்டல் ரத்து செய்யப்பட்டது'))));},icon:const Icon(Icons.notifications_off_outlined),label:Text(t('Cancel reminder','நினைவூட்டலை ரத்து செய்')))]),
      ]))),
    ]));
  }
}
