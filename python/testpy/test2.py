import matplotlib.pyplot as plt
import pyaudio
import struct
import numpy as np
import pysptk.sptk as sptk
import time
import pyqtgraph as pg


FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 44100
loop = 0.2
CHUNK = int(loop * RATE)  # 13000 #int(wlen*RATE)
wlen = float(CHUNK / RATE)

p = pyaudio.PyAudio()

chosen_device_index = -1
for x in range(0, p.get_device_count()):
    info = p.get_device_info_by_index(x)
    # print p.get_device_info_by_index(x)
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

t = np.linspace(-10, 0, num=10 * RATE)
sound = np.zeros(10 * RATE)
dt = int(loop / 10 * RATE)
pitch = np.zeros(int(10 / dt * RATE))
tp = np.linspace(-10, 0, num=len(pitch))

t0 = time.process_time()
while True:
    # compute something
    print('loop', time.process_time() - t0)
    t0 = time.process_time()
    data = np.array(struct.unpack(str(CHUNK) + 'h',
                                  stream.read(CHUNK, exception_on_overflow=False)))
    t55 = time.process_time()
    print('get rec ', t55 - t0)
    data = data.astype('float64')
    sound = np.roll(sound, -len(data))
    t59 = time.process_time()
    print('roll sound ', t59 - t55)

    sw = sptk.swipe(data, RATE, dt, min=40, max=700, threshold=0.25)
    t63 = time.process_time()
    print('swipe', t63 - t59)
    # print(len(sw))
    # t2 = time.process_time()
    # print('Swipe time ',t2-t1)

    pitch = np.roll(pitch, -len(sw))
    t70 = time.process_time()
    print('roll pitch ', t70 - t63)
    # print('length from swipe ',len(sw))
    # print('length of pitch ', len(pitch))

    # print('Pitch len ',len(pitch))
    # print('sw len ', len(sw))
    # print('pitch time ',dt*len(pitch)/RATE)

    # print(pitch)

    np.put(sound, range(-len(data), -1), data)
    t84 = time.process_time()
    print('put sound ', t84 - t70)
    np.put(pitch, range(-len(sw), -1), sw)
    t87 = time.process_time()
    print('put pitch ', t87 - t84)
    # t10 = time.process_time()
    # print('75',t10-t2)
    plt.figure(1)
    plt.clf()
    # t3 = time.process_time()
    # # print('78',t3-t10)
    plt.plot(t, sound)  # plot something

    #
    # plt.pause(0.001)  # I ain't needed!!!
    # fig.canvas.draw()
    #
    plt.figure(2)
    plt.clf()
    t103 = time.process_time()
    print('clf ', t103 - t87)
    plt.plot(tp, pitch, '.')  # plot something

    t4 = time.process_time()
    print('plot', t4 - t103)
    # print('Before pause ',t4-t0)
    # pg.plot(tp, pitch, pen=None, symbol='o')
    # t5 = time.process_time()
    # print('Pause',t5-t4)
    fig.canvas.draw()
    t1 = time.process_time()
    print('canvas draw', t1 - t4)
    twait = loop - (t1 - t0)
    print('twait ', twait)
    if twait > 0.0:
        plt.pause(twait)  # I ain't needed!!!
        # time.sleep(twait)
        # time.sleep(0.1)
    else:
        plt.pause(0.001)
    #     time.sleep(1)
    #     print('wtf')
    print(time.process_time() - t1)

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
