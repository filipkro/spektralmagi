#! /usr/local/bin/python

import pyaudio
import struct
import numpy as np
import matplotlib.pyplot as plt
import time


CHUNK = 4000
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000

x = range(1,100)
plt.plot(x)
plt.show()

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
 input_device_index=chosen_device_index,
 input=True,
 output=True,
 frames_per_buffer=CHUNK
 )

plt.ion()
fig, ax = plt.subplots()

x = np.arange(0, CHUNK)
data = stream.read(CHUNK)
data_int16 = struct.unpack(str(CHUNK) + 'h', data)
line, = ax.plot(x, data_int16)
#ax.set_xlim([xmin,xmax])
ax.set_ylim([-2**15,(2**15)-1])

# fig = plt.gcf()
# fig.show()
# fig.canvas.draw()

data = struct.unpack(str(CHUNK) + 'h', stream.read(CHUNK))
plt.plot()

while True:
#for i in range(500)
    data = struct.unpack(str(CHUNK) + 'h', stream.read(CHUNK))
    # line.set_ydata(data)
    # fig.canvas.draw()
    # fig.show()
    # fig.canvas.flush_events()


    print(data)
    x = range(len(data))

    plt.plot(x,data) # plot something
    plt.show()

    # update canvas immediately
    # plt.xlim([0, 100])
    # plt.ylim([0, 100])
    #plt.pause(0.01)  # I ain't needed!!!
    # fig.canvas.draw()

plt.plot(data)
