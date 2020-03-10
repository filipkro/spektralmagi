import pyaudio

def callback(in_data, frame_count, time_info, status):
    print('in callback')
    return (in_data,pyaudio.paContinue)


def main():

    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = 1
    loop = 0.2
    CHUNK = int(loop*RATE) #13000 #int(wlen*RATE)
    wlen = float(CHUNK/RATE)

    p = pyaudio.PyAudio()

    chosen_device_index = -1
    for x in range(0,p.get_device_count()):
        info = p.get_device_info_by_index(x)
        #print p.get_device_info_by_index(x)
        if info["name"] == "pulse":
            chosen_device_index = info["index"]
            print("Chosen index: ", chosen_device_index)

    stream = p.open(format=FORMAT,
     channels=CHANNELS,
     rate=RATE,
     input=True,
     output=True,
     stream_callback=callback,
     start=True
     )

    while True:
        a = 1
