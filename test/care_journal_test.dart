import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phytosense_ai/services/care_journal.dart';
void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(()=>SharedPreferences.setMockInitialValues({}));
  CareEntry entry(String id,{String source='manual'})=>CareEntry(id:id,plant:'Tomato',source:source,kind:'water',note:'Checked the soil first.',time:DateTime(2026,9,12));
  test('parallel saves do not lose a care action',()async{
    final journal=CareJournal();await Future.wait([journal.add(entry('1')),journal.add(entry('2'))]);
    expect((await journal.load()).map((e)=>e.id),containsAll(['1','2']));
  });
  test('restore merges IDs and preserves source separation',()async{
    final journal=CareJournal();await journal.add(entry('1'));
    final backup=CareJournal.encode([entry('1'),entry('2',source:'simulation')]);
    await journal.restore(backup);await journal.restore(backup);
    final data=await journal.load();expect(data.length,2);expect(data.firstWhere((e)=>e.id=='2').source,'simulation');
  });
  test('malformed restore leaves existing diary untouched',()async{
    final journal=CareJournal();await journal.add(entry('1'));
    expect(()=>journal.restore(jsonEncode({'format':'phytosense-care','version':1,'entries':[{'id':'bad'}]})),throwsA(isA<FormatException>()));
    expect((await journal.load()).single.id,'1');
  });
}
