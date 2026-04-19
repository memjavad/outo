import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void writeWav(String path, List<double> samples, int sampleRate) {
  var file = File(path);
  var bytes = BytesBuilder();
  
  bytes.add('RIFF'.codeUnits);
  bytes.add([0, 0, 0, 0]); 
  bytes.add('WAVE'.codeUnits);
  bytes.add('fmt '.codeUnits);
  bytes.add([16, 0, 0, 0]); 
  bytes.add([1, 0]); 
  bytes.add([1, 0]); 
  bytes.add([sampleRate & 0xFF, (sampleRate >> 8) & 0xFF, 0, 0]); 
  int byteRate = sampleRate * 2;
  bytes.add([byteRate & 0xFF, (byteRate >> 8) & 0xFF, (byteRate >> 16) & 0xFF, (byteRate >> 24) & 0xFF]); 
  bytes.add([2, 0]); 
  bytes.add([16, 0]); 
  bytes.add('data'.codeUnits);
  int dataSize = samples.length * 2;
  bytes.add([dataSize & 0xFF, (dataSize >> 8) & 0xFF, (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF]); 
  
  for (var sample in samples) {
    int val = (sample * 32767).round().clamp(-32768, 32767);
    if (val < 0) val += 65536;
    bytes.add([val & 0xFF, (val >> 8) & 0xFF]);
  }
  
  var result = bytes.takeBytes();
  var length = result.length - 8;
  result[4] = length & 0xFF;
  result[5] = (length >> 8) & 0xFF;
  result[6] = (length >> 16) & 0xFF;
  result[7] = (length >> 24) & 0xFF;
  
  file.writeAsBytesSync(result);
}

void main() {
  Directory('assets/audio').createSync(recursive: true);
  
  int sampleRate = 44100;
  
  // 1. Pop Sound (for node appearance)
  List<double> pop = [];
  for (int i = 0; i < sampleRate ~/ 5; i++) { 
    double t = i / sampleRate;
    double env = exp(-t * 20);
    double freq = 400 + 600 * exp(-t * 30);
    pop.add(sin(2 * pi * freq * t) * env);
  }
  writeWav('assets/audio/pop.wav', pop, sampleRate);
  
  // 2. Thud Sound (locked node)
  List<double> thud = [];
  for (int i = 0; i < sampleRate ~/ 4; i++) { 
    double t = i / sampleRate;
    double env = exp(-t * 20);
    double noise = (Random().nextDouble() * 2 - 1) * 0.8;
    double freq = 100 * exp(-t * 30);
    thud.add((sin(2 * pi * freq * t) + noise) * env);
  }
  writeWav('assets/audio/thud.wav', thud, sampleRate);
  
  // 3. Ambient Jungle (Wind/Noise)
  List<double> jungle = [];
  for (int i = 0; i < sampleRate * 5; i++) { 
    double t = i / sampleRate;
    double noise1 = Random().nextDouble() * 2 - 1;
    double noise2 = Random().nextDouble() * 2 - 1;
    double wind = noise1 * 0.05 * (sin(t * 0.5) * 0.5 + 0.5);
    double cricket = (t * 10 % 1 < 0.05) ? noise2 * 0.02 : 0;
    jungle.add(wind + cricket);
  }
  writeWav('assets/audio/jungle.wav', jungle, sampleRate);
  print('Audio files generated successfully.');
}
