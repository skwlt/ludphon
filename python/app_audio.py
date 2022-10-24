import speech_recognition as sr

def appAudio(filename):
    recognizer = sr.Recognizer()

    ''' recording the sound '''

    with sr.AudioFile(filename) as source:
        recorded_audio = recognizer.listen(source)
        print("Done recording")

    ''' Recorgnizing the Audio '''
    try:
        print("Recognizing the text")
        text = recognizer.recognize_google(
                recorded_audio, 
                language="en-US"
            )
        # print("Decoded Text : {}".format(text))
        return text

    except Exception as ex:
        print(ex)