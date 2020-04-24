from PyQt5 import QtCore, QtWidgets
import pyqtgraph as pg
import numpy as np

import struct
import pyaudio
import sys
import time

import multiprocessing as mp
import queue

from pysptk.sptk import swipe


class MyWidget(pg.GraphicsWindow):

    def __init__(self, parent=None):
        super().__init__(parent=parent)
        CHANNELS = 1
        self.RATE = 44100
        self.CHUNK = 6000#2*2048
        FORMAT = pyaudio.paInt16
        self.cnt = 0
        tsave = 10

        self.unprocessed_sound = mp.Queue()
        self.swipes_toplot = mp.Queue()
        self.shut_down_queue = mp.Queue()
        self.pitch = np.zeros(int(tsave*5*self.RATE/self.CHUNK))
        self.tp = np.linspace(-tsave,0,num=len(self.pitch))
        self.setup_plot()

        self.p = pyaudio.PyAudio()
        self.stream = self.p.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=self.RATE,
            input=True,
            output=True,
            stream_callback=self.audio_callback,
            frames_per_buffer=self.CHUNK
        )
        self.proc = mp.Process(target=self.do_job)
        self.proc.start()

    def do_job(self):
        print('in do_job')
        while True:
            try:
                self.wshut_down_queue.get_nowait()
            except:
                try:
                    data = self.unprocessed_sound.get_nowait()
                except queue.Empty:
                    print('queue empty')
                    time.sleep(0.04)
                else:
                    # self.cnt = 0
                    print('Data length: ', len(data))
                    data = data.astype('float64')
                    t0 = time.perf_counter()
                    sw = swipe(data,self.RATE,int(self.CHUNK/5),min=30,max=800,threshold=0.25)
                    print('swipe time: ', time.perf_counter()-t0)
                    self.swipes_toplot.put(sw)
                    print('swipe length: ', len(sw))
            else:
                break
        return True

    def setup_plot(self):
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(50) # in milliseconds
        self.timer.start()
        self.timer.timeout.connect(self.update_plot)

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates")
        # self.plotSwipe.setLogMode(x=False,y=True)
        # self.plotSwipe.setXRange(-10, 0, padding=0)
        self.plotSwipe.setYRange(1, 3, padding=0)
        # self.plotSwipe.enableAutoScale()

        self.plot_swipe_item = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        # self.plot_swipe_item.setLogMode(False,True)
        # self.plot_swipe_item.setXRange(-10, 0, padding=0)
        # self.plot_swipe_item.setYRange(1, 3, padding=0)
        # self.plot_swipe_item.setLogMode(x=None,y=True)

    def audio_callback(self, in_data, frame_count, time_info, status):
        print('in callback')
        data = np.frombuffer(in_data,dtype=np.int16)
        self.unprocessed_sound.put(data)

        return(in_data,pyaudio.paContinue)

    def myExitHandler(self):
        print('in exit')
        self.p.close(self.stream)
        self.shut_down_queue.put(True)
        self.proc.join()


    def update_plot(self):
        try:
            data = self.swipes_toplot.get_nowait()
        except queue.Empty:
            print('no swipes')
        else:
            self.pitch = np.roll(self.pitch,-len(data))
            np.put(self.pitch,range(-len(data),-1),data)
            t0 = time.perf_counter()
            self.plot_swipe_item.setData(self.tp,np.log10(self.pitch))
            print('plot time: ', time.perf_counter()-t0)



def main():
    app = QtWidgets.QApplication([])

    pg.setConfigOptions(antialias=False) # True seems to work as well

    win = MyWidget()
    app.aboutToQuit.connect(win.myExitHandler)
    win.show()
    win.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
