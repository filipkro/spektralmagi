import multiprocessing as mp
import pyaudio
import numpy as np
import time
from pysptk.sptk import swipe
import queue
import pyqtgraph as pg
from PyQt5 import QtCore, QtWidgets

CHANNELS = 1
RATE = 44100
CHUNK = 6000#2*2048
FORMAT = pyaudio.paInt16
cnt = 0
tsave = 10

unprocessed_sound = mp.Queue()
swipes_toplot = mp.Queue()
pitch = np.zeros(int(tsave*5*RATE/CHUNK))
tp = np.linspace(-tsave,0,num=len(pitch))

# app = QtWidgets.QApplication([])
wid = pg.GraphicsWindow()
wid.show()
wid.raise_()
mainLayout = QtWidgets.QVBoxLayout()
wid.setLayout(mainLayout)
# app.exec_()
plot_swipe = wid.addPlot(title='Swipe mp')
plot_swipe_item = plot_swipe.plot([], pen=None,
    symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)


def audio_callback(in_data, frame_count, time_info, status):
    print('in callback')
    data = np.frombuffer(in_data,dtype=np.int16)
    unprocessed_sound.put(data)

    return(in_data,pyaudio.paContinue)

def do_job():
    # global unprocessed_sound
    global cnt,pitch,tp
    print('in do_job')
    while True:
        try:
            data = unprocessed_sound.get_nowait()
        except queue.Empty:
            print('swipe empty')
            cnt += 1
            print('queue empty, cnt: ', cnt)
            if cnt > 3:
                break
            time.sleep(0.1)
        else:
            cnt = 0
            print('Data length: ', len(data))
            data = data.astype('float64')
            t0 = time.perf_counter()
            sw = swipe(data,RATE,int(CHUNK/5),min=30,max=800,threshold=0.25)
            print('swipe time: ', time.perf_counter()-t0)
            swipes_toplot.put(sw)
            print('swipe length: ', len(sw))
    return True

def setup_pyqt():
    app = QtWidgets.QApplication([])
    pg.setConfigOptions(antialias=False)
    mainLayout = QtWidgets.QVBoxLayout()
    setLayout(mainLayout)

def update_plot():
    try:
        data = swipes_toplot.get_nowait()
    except queue.Empty:
        print('no swipes')
    else:
        pitch = np.roll(pitch,-len(data))
        np.put(pitch,range(-len(data),-1),data)
        plot_swipe_item.setData(tp,pitch)

def main():

    p = pyaudio.PyAudio()
    stream = p.open(
        rate=RATE,
        channels=CHANNELS,
        format=FORMAT,
        input=True,
        stream_callback=audio_callback,
        frames_per_buffer=CHUNK
    )
    time.sleep(1)
    timer = QtCore.QTimer(wid)
    timer.setInterval(50) # in milliseconds
    timer.start()
    timer.timeout.connect(update_plot)

    proc = mp.Process(target=do_job)
    proc.start()
    # time.sleep(5)
    x = 0
    while x <1000:
        print(x)
        x += 1
        time.sleep(0.02)
    p.close(stream)
    proc.join()

    print('done??')

if __name__ == '__main__':
    main()
