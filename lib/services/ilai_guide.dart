enum IlaiTopic { summary, action, reason, connection, help }

class IlaiSnapshot {
  final bool available, simulation;
  final String condition, problem, action, reason;
  final DateTime? timestamp;
  const IlaiSnapshot({required this.available, required this.simulation,
    this.condition = '', this.problem = '', this.action = '', this.reason = '', this.timestamp});
}

/// A bounded guide to supplied findings, not a model or diagnostic engine.
class IlaiGuide {
  static IlaiTopic topic(String question) {
    final q = question.toLowerCase().trim();
    if (RegExp(r'connect|offline|wifi|wi-fi|firebase|இணை|சாதனம்').hasMatch(q)) return IlaiTopic.connection;
    if (RegExp(r'why|reason|evidence|ஏன்|எதனால்|காரண').hasMatch(q)) return IlaiTopic.reason;
    if (RegExp(r'what.*do|action|solution|water|help.*plant|செய்|தீர்வு|தண்ணீர்|நீர்').hasMatch(q)) return IlaiTopic.action;
    if (RegExp(r'problem|wrong|plant|health|condition|செடி|நிலை|பிரச்ச').hasMatch(q)) return IlaiTopic.summary;
    return IlaiTopic.help;
  }

  static String reply(IlaiTopic topic, IlaiSnapshot data, {required bool tamil}) {
    String t(String en, String ta) => tamil ? ta : en;
    if (topic == IlaiTopic.help) {
      return t('I’m Ilai, PhytoSense’s plant guide. I can explain the current plant finding, the next step, and the reason. I’m a guided assistant, not a general AI chatbot. Try one of the questions below.',
          'நான் இலை, PhytoSense செடி வழிகாட்டி. தற்போதைய செடி நிலை, செய்ய வேண்டிய செயல், அதன் காரணம் ஆகியவற்றை விளக்குவேன். இது பொதுவான செயற்கை நுண்ணறிவு உரையாடல் அல்ல. கீழே உள்ள கேள்விகளில் ஒன்றைத் தேர்வு செய்யுங்கள்.');
    }
    if (topic == IlaiTopic.connection) {
      return t('Open Settings to connect your ESP32. Nearby, use the device’s Wi-Fi. Away from it, use your configured remote connection. Wait for a fresh reading. Simulation is only for practice and is kept separate.',
          'அமைப்புகளில் ESP32 சாதனத்தை இணைக்கவும். அருகில் இருந்தால் சாதனத்தின் வைஃபையைப் பயன்படுத்தவும். தொலைவில் இருந்தால் அமைத்துள்ள இணைய இணைப்பைப் பயன்படுத்தவும். புதிய அளவீட்டுக்குக் காத்திருக்கவும். சிமுலேஷன் பயிற்சிக்கானது மட்டும்.');
    }
    if (!data.available) {
      return data.simulation
          ? t('No practice reading is available. Choose a practice condition in Settings, then ask again.', 'பயிற்சி அளவீடு கிடைக்கவில்லை. அமைப்புகளில் பயிற்சி நிலையைத் தேர்வு செய்து மீண்டும் கேளுங்கள்.')
          : t('I don’t have a current plant finding. Connect your ESP32 and wait for a fresh, supported reading. I won’t guess whether your plant needs water.',
              'தற்போதைய செடி முடிவு கிடைக்கவில்லை. ESP32 சாதனத்தை இணைத்து புதிய அளவீட்டுக்குக் காத்திருக்கவும். செடிக்குத் தண்ணீர் தேவையா என்பதை ஊகிக்க மாட்டேன்.');
    }
    final source = data.simulation
        ? t('Practice data only.\n\n', 'இது பயிற்சிக்கான தரவு மட்டும்.\n\n')
        : t('From your ESP32 finding:\n\n', 'உங்கள் ESP32 முடிவின்படி:\n\n');
    final missing = t('The device has not supplied this detail. Open Plant care for the available findings.',
        'இந்த விவரத்தைச் சாதனம் வழங்கவில்லை. கிடைக்கும் முடிவுகளுக்குச் செடி பராமரிப்பைப் பார்க்கவும்.');
    String supplied(String s) => s.trim().isEmpty ? missing : s;
    return source + switch (topic) {
      IlaiTopic.action => '${t('What to do now', 'இப்போது செய்ய வேண்டியது')}\n${supplied(data.action)}',
      IlaiTopic.reason => '${t('Why PhytoSense says this', 'இதற்கான காரணம்')}\n${supplied(data.reason)}',
      _ => '${supplied(data.condition)}\n\n${t('What is wrong?', 'என்ன பிரச்சினை?')}\n${supplied(data.problem)}\n\n${t('What to do now', 'இப்போது செய்ய வேண்டியது')}\n${supplied(data.action)}',
    };
  }
}
