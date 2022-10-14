from crypt import methods
from urllib import request
from flask import Flask, make_response, jsonify, request
from long_audio import readFile
from app_audio import appAudio

app = Flask(__name__)

@app.route('/', methods=['POST'])
def postLongAudio():
    request_data = request.files['file']
    message = readFile(request_data)
    return jsonify({ 'message': message })

@app.route('/appAudio', methods=['POST'])
def postShortAudio():
    request_data = request.files['file']
    message = appAudio(request_data)
    return jsonify({ 'message': message })

app.run(port=3000)