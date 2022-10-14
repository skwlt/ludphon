import os 
from pydub import AudioSegment
import speech_recognition as sr
from pydub.silence import split_on_silence

recognizer = sr.Recognizer()

def load_chunks(filename):
    long_audio = AudioSegment.from_file(filename, format="mp4")
    # long_audio = AudioSegment.from_mp3(filename)
    audio_chunks = split_on_silence(
        long_audio, min_silence_len=500,
        silence_thresh=-40
        # long_audio, min_silence_len=1800,
        # silence_thresh=-17
    )
    return audio_chunks
    # return long_audio

def readFile(filename):
    for audio_chunk in load_chunks(filename):
        audio_chunk.export("temp", format="wav")
        with sr.AudioFile("temp") as source:
            audio = recognizer.listen(source)
            try:
                text = recognizer.recognize_google(audio)
                print("Chunk : {}".format(text))
                print(text)
                return text
            except Exception as ex:
                print("Error occured")
                print(ex)

# readMp3('./sample_audio/long_audio.mp3')
print("++++++")



