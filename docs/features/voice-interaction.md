# Voice Interaction

Searvo provides natural voice interaction for hands-free search and research. Ask questions by speaking and hear responses read aloud.

## Features

### Voice Input (Speech-to-Text)

Transform your speech into text queries instantly.

#### Starting Voice Input

- **Tap microphone icon** - Start listening
- **Speak your question** - Natural conversation
- **Auto-detection** - Automatically stops when you finish speaking
- **Manual stop** - Tap again to stop early

#### Supported Languages

Voice input supports multiple languages:
- English (US, UK, AU, etc.)
- Spanish
- French
- German
- Italian
- Portuguese
- Japanese
- Chinese (Mandarin)
- And many more...

Language auto-detection based on system settings.

### Voice Output (Text-to-Speech)

Hear AI responses read aloud naturally.

#### Features

- **Auto-playback** - Optionally play responses automatically
- **Pause/Resume** - Control playback
- **Speed control** - Adjust speech rate
- **Voice selection** - Choose from system voices
- **Volume control** - Independent volume settings

#### Customization

Configure voice output in Settings → Voice:
- **Speech Rate**: 0.5x to 2.0x speed
- **Pitch**: Adjust voice pitch
- **Volume**: Set output volume
- **Auto-play**: Toggle automatic playback

## Use Cases

### Hands-Free Research

Perfect for:
- Cooking (following recipes while researching)
- Driving (voice-only, when safe and legal)
- Exercise (listening while working out)
- Accessibility (visual impairment support)
- Multitasking (working while researching)

### Natural Conversation

Talk to Searvo naturally:

```
You: "Hey, what's the weather today?"
Searvo: [Searches and responds] "The weather today is..."

You: "How about tomorrow?"
Searvo: [Understands context] "Tomorrow's forecast shows..."

You: "Should I bring an umbrella?"
Searvo: [Provides recommendation]
```

### Voice Commands

Use voice for quick actions:

```
"Search for Flutter tutorials"
"Read the last result"
"Next article"
"Save this search"
"Go to settings"
```

## Voice Recognition

### How It Works

1. **Activation** - Tap microphone or use wake word (if enabled)
2. **Listening** - Visual feedback while listening
3. **Processing** - Speech converted to text locally or via cloud
4. **Confirmation** - Text shown before search
5. **Execution** - Search performed with voice input

### Recognition Modes

#### Continuous Mode
- Stays active for multiple queries
- Great for extended research sessions
- Auto-stops after period of silence

#### Single Query Mode
- Stops after one question
- Default mode
- Better battery life

### Accuracy Tips

For best recognition:

✅ **Do:**
- Speak clearly and naturally
- Use good microphone
- Minimize background noise
- Speak at normal pace
- Pause briefly between thoughts

❌ **Avoid:**
- Speaking too fast
- Mumbling
- Very loud environments
- Poor microphone placement
- Speaking from far away

## Text-to-Speech

### Voice Quality

Searvo uses system TTS engines:

**Android:**
- Google Text-to-Speech (recommended)
- Samsung TTS
- Third-party engines

**iOS:**
- Built-in Siri voices
- Multiple voice options
- High-quality synthesis

**Desktop:**
- System TTS (Windows, macOS, Linux)
- Optional: Install premium voices

### Response Reading

Configure what gets read:

- **Full Response** - Read entire answer
- **Summary Only** - Brief version
- **Key Points** - Main takeaways only
- **Custom** - Read specific sections

### Reading Controls

During playback:

- **Pause** - Temporarily stop
- **Resume** - Continue from pause
- **Stop** - End playback
- **Rewind** - Go back 10 seconds
- **Forward** - Skip ahead 10 seconds

## Configuration

### Voice Settings

Access via Settings → Voice:

#### Input Settings
```
✓ Enable Voice Input
✓ Auto-start listening
✓ Continuous listening mode
Language: English (US)
Sensitivity: Medium
```

#### Output Settings
```
✓ Enable Voice Output
✓ Auto-play responses
Speech Rate: 1.0x
Pitch: 1.0
Volume: 80%
Voice: System Default
```

### Permissions

Required permissions:

**Android:**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS:**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Searvo needs microphone access for voice search</string>
```

Permissions requested on first use.

### Privacy

Voice data handling:

- **Local Processing** - On-device when possible
- **Cloud Processing** - Via system APIs (Google/Apple)
- **No Storage** - Voice data not stored by Searvo
- **No Sharing** - Audio never sent to Searvo servers

## Advanced Features

### Wake Word Detection (Coming Soon)

Activate voice search with custom wake words:
```
"Hey Searvo" - Activate listening
"Stop listening" - Deactivate
```

### Voice Shortcuts

Quick voice commands:

| Command | Action |
|---------|--------|
| "Search for..." | Perform search |
| "Read response" | Play TTS |
| "Pause" | Pause playback |
| "Stop" | Stop playback |
| "Settings" | Open settings |

### Contextual Understanding

Voice understands context:

```
You: "Search for best Italian restaurants in Seattle"
[Results shown]
You: "Call the first one"
[Opens phone dialer with restaurant number]

You: "Directions to that place"
[Opens maps with directions]
```

### Multi-Language Support

Switch languages mid-conversation:

```
You: "Search for French recipes"
[Results in English about French food]

You: "Chercher des recettes françaises" (French)
[Searvo detects French, searches accordingly]
```

## Accessibility

Voice features enhance accessibility:

### Visual Impairment
- Full screen reader support
- Complete voice-only navigation
- Audio cues for actions
- Descriptive TTS

### Motor Impairment
- Hands-free operation
- Voice-only control
- Customizable activation
- Minimal physical interaction

### Cognitive Support
- Natural language understanding
- Forgiving voice recognition
- Clear audio feedback
- Simple voice commands

## Troubleshooting

### Voice Input Issues

**Problem**: Microphone not working

**Solutions:**
- Check microphone permission
- Verify microphone hardware
- Test in other apps
- Restart application
- Check system settings

**Problem**: Poor recognition accuracy

**Solutions:**
- Speak more clearly
- Reduce background noise
- Check language settings
- Update speech recognition data
- Use external microphone

**Problem**: Voice input cuts off too soon

**Solutions:**
- Adjust sensitivity settings
- Use continuous listening mode
- Speak without long pauses
- Check microphone quality

### Voice Output Issues

**Problem**: No audio output

**Solutions:**
- Check device volume
- Verify TTS engine installed
- Test TTS in settings
- Check audio permissions
- Restart TTS service

**Problem**: Robotic/poor voice quality

**Solutions:**
- Install better TTS engine
- Download premium voices
- Adjust speech settings
- Update system TTS

**Problem**: TTS skipping words

**Solutions:**
- Update TTS engine
- Clear TTS cache
- Reduce speech rate
- Report to system TTS provider

## Performance

### Battery Impact

Voice features battery usage:

- **Speech Recognition**: Moderate impact
- **TTS Playback**: Low impact
- **Continuous Mode**: Higher impact

**Optimization:**
- Use single query mode when possible
- Disable auto-play if not needed
- Lower screen brightness during voice use

### Network Usage

- **Online Recognition**: Uses data for cloud processing
- **Offline Mode**: Some systems support offline recognition
- **TTS**: Usually processed locally

## Best Practices

1. **Quiet Environment** - Minimize background noise
2. **Natural Speech** - Speak normally, don't over-enunciate
3. **Clear Questions** - Be specific about what you want
4. **Check Text** - Verify recognized text before searching
5. **Adjust Settings** - Customize for your voice and environment

## Integration Examples

### With Search

```
Voice: "Search for Flutter tutorials"
Searvo: [Performs search and reads results]
```

### With Sharing

```
Voice: "Share these results via email"
Searvo: [Opens email with results]
```

### With Settings

```
Voice: "Change theme to dark mode"
Searvo: [Switches theme]
```

## Future Enhancements

Coming soon:

- 🎤 Wake word detection
- 🌍 Offline language packs
- 🎵 Voice emotion detection
- 🤖 Voice customization
- 🔊 3D audio positioning

## Next Steps

- [AI Search](ai-search.md) - Enhance voice search with AI
- [Web Scraping](web-scraping.md) - Understand content extraction
- [Configuration Guide](../getting-started/configuration.md) - Set up voice settings
