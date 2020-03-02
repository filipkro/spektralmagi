import matplotlib.pyplot as plt
import pyaudio
import struct
import numpy as np
import pysptk.sptk as sptk
import time

FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 44100
CHUNK = 13000 #int(wlen*RATE)
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
 input_device_index=chosen_device_index,
 input=True,
 output=True,
 frames_per_buffer=CHUNK
 )


#data = stream.read(CHUNK)
# data_int16 = struct.unpack(str(CHUNK) + 'h', data)

# draw the figure so the animations will work
fig = plt.gcf()
fig.show()
fig.canvas.draw()

t = np.linspace(-10,0,num=10*RATE)
sound = np.zeros(10*RATE)
dt = int(wlen/10*RATE)
pitch = np.zeros(int(10/dt*RATE))
tp = np.linspace(-10,0,num=len(pitch))

while True:
    # compute something
    t0 = time.process_time()
    data = np.array(struct.unpack(str(CHUNK) + 'h', stream.read(CHUNK,exception_on_overflow = False)))
    t1 = time.process_time()
    # print('53',t1-t0)

    data = data.astype('float64')
    sound = np.roll(sound,-len(data))

    p = sptk.swipe(data,RATE,dt,min=50,max=500,threshold=0.3)
    t2 = time.process_time()
    # print('60',t2-t1)
    # print(len(sound))
    pitch = np.roll(pitch,-len(p))
    # print(len(p))
    # print(len(pitch))


    # print(CHUNK)
    # # print(data)

    print(p)


    # print(pitch)

    np.put(sound,range(-len(data),-1),data)
    np.put(pitch,range(-len(p),-1),p)
    t10 = time.process_time()
    # print('75',t10-t2)
    plt.figure(1)
    plt.clf()
    t3 = time.process_time()
    # print('78',t3-t10)
    plt.plot(t,sound) # plot something
    t4 = time.process_time()
    # print('81',t4-t3)
    #
    # plt.pause(0.001)  # I ain't needed!!!
    # fig.canvas.draw()
    #
    plt.figure(2)
    plt.clf()
    plt.plot(tp,pitch,'.') # plot something


    plt.pause(0.005)  # I ain't needed!!!
    t5 = time.process_time()
    # print('93',t5-t4)
    fig.canvas.draw()
    # print(time.process_time()-t5)



    # plt.figure(2)
    # plt.clf()
    # plt.plot(tp,pitch,'.')
    # plt.pause(0.005)  # I ain't needed!!!
    # fig.canvas.draw()

    # update canvas immediately
    #plt.xlim([0, 100])
    #plt.ylim([0, 1000])

    # print(data)
