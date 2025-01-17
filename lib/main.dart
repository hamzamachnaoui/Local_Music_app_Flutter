import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer player = AudioPlayer();
  final AudioCache cache = AudioCache();

  final List<String> musicFiles = [
    'music/music6.mp3',
    'music/music.mp3',
    'music/music01.wav',
    'music/music3.mp3',
    'music/music4.mp3',
    'music/music5.mp3',
    'music/music7.mp3',
    'music/music8.mp3',
    'music/music9.mp3',
    'music/music10.mp3',
    'music/music11.mp3',
    'music/music12.mp3',
    'music/music13.mp3',
  ];

  int currentIndex = 0;
  bool isPlaying = false;
  bool isShuffle = false;
  bool isRepeat = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  Timer? positionTimer;
  double volume = 1.0;

  @override
  void initState() {
    super.initState();
    loadAudio(currentIndex);

    player.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });

    positionTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      final positionInMilliseconds = await player.getCurrentPosition();
      if (positionInMilliseconds != null) {
        setState(() {
          currentPosition = Duration(milliseconds: positionInMilliseconds);
        });
      }
    });

    player.onPlayerCompletion.listen((_) {
      if (isRepeat) {
        startAudioPlayback();
      } else {
        nextTrack();
      }
    });
  }

  void loadAudio(int index) async {
    try {
      await player.stop();
      String fileName = musicFiles[index];
      final filePath = await cache.load(fileName);
      setState(() {
        currentIndex = index;
        isPlaying = false;
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
      });
    } catch (e) {
      print("Error during loading: $e");
    }
  }

  void startAudioPlayback() async {
    try {
      String fileName = musicFiles[currentIndex];
      final filePath = await cache.load(fileName);
      await player.play(filePath.path, isLocal: true, volume: volume);
      setState(() {
        isPlaying = true;
      });

      Future.delayed(Duration(seconds: 1), () async {
        final duration = await player.getDuration();
        if (duration != null) {
          setState(() {
            totalDuration = Duration(milliseconds: duration);
          });
        }
      });
    } catch (e) {
      print("Playback failed: $e");
    }
  }

  void pauseAudio() async {
    await player.pause();
    setState(() {
      isPlaying = false;
    });
  }

  void resumeAudio() async {
    startAudioPlayback();
  }

  void nextTrack() {
    if (isShuffle) {
      currentIndex = Random().nextInt(musicFiles.length);
    } else {
      currentIndex = (currentIndex + 1) % musicFiles.length;
    }
    loadAudio(currentIndex);
  }

  void previousTrack() {
    currentIndex = (currentIndex - 1 + musicFiles.length) % musicFiles.length;
    loadAudio(currentIndex);
  }

  void toggleShuffle() {
    setState(() {
      isShuffle = !isShuffle;
    });
  }

  void toggleRepeat() {
    setState(() {
      isRepeat = !isRepeat;
    });
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(
          "Music Player",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isShuffle ? Icons.shuffle_on : Icons.shuffle,
              color: Colors.white,
            ),
            onPressed: toggleShuffle,
          ),
          IconButton(
            icon: Icon(
              isRepeat ? Icons.repeat_on : Icons.repeat,
              color: Colors.white,
            ),
            onPressed: toggleRepeat,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(
                  "Music ${currentIndex + 1}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Slider(
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white30,
                  value: (currentPosition.inSeconds.toDouble() >
                          totalDuration.inSeconds.toDouble())
                      ? 0
                      : currentPosition.inSeconds.toDouble(),
                  max: totalDuration.inSeconds.toDouble() > 0
                      ? totalDuration.inSeconds.toDouble()
                      : 1,
                  onChanged: (value) async {
                    if (totalDuration.inSeconds > 0) {
                      final position = Duration(seconds: value.toInt());
                      await player.seek(position);
                      setState(() {
                        currentPosition = position;
                      });
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDuration(currentPosition),
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      formatDuration(totalDuration),
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Slider(
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white30,
                  value: volume,
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    setState(() {
                      volume = value;
                    });
                    player.setVolume(volume);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous, size: 40),
                      color: Colors.white,
                      onPressed: previousTrack,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          pauseAudio();
                        } else {
                          resumeAudio();
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, size: 40),
                      color: Colors.white,
                      onPressed: nextTrack,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: musicFiles.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => loadAudio(index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentIndex == index
                          ? Colors.blueAccent.withOpacity(0.5)
                          : Colors.grey[850],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentIndex == index
                              ? Icons.play_circle_fill
                              : Icons.music_note,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(width: 20),
                        Text(
                          musicFiles[index].split('/').last,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    positionTimer?.cancel();
    player.dispose();
    super.dispose();
  }
}
