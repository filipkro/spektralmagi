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
            output=False,
            stream_callback=self.audio_callback,
            frames_per_buffer=self.CHUNK
        )
        self.proc = mp.Process(target=self.do_job)
        self.proc.start()

    def do_job(self):
        #print('in do_job')
        while True:
            try:
                self.shut_down_queue.get_nowait()
            except:
                try:

                    data = self.unprocessed_sound.get_nowait()
                except queue.Empty:
                    #print('queue empty')
                    time.sleep(0.04)
                else:
                    print(self.unprocessed_sound.empty())
                    # self.cnt = 0
                    #print('Data length: ', len(data))
                    data = data.astype('float64')
                    #print(len(data))
                    t0 = time.perf_counter()
                    sw = swipe(data,self.RATE,int(self.CHUNK/5),min=30,max=1200,threshold=0.25)
                    print('swipe time: ', time.perf_counter()-t0)
                    self.swipes_toplot.put(sw)
                    #print('swipe length: ', len(sw))
            else:
                break
        return True

    def setup_plot(self):
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(20) # in milliseconds
        self.timer.start()
        self.timer.timeout.connect(self.update_plot)

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates")
        # self.plotSwipe.setLogMode(x=False,y=True)
        # self.plotSwipe.setXRange(-10, 0, padding=0)
        min_freq = np.log(80)/np.log(2**(1/12))
        max_freq = np.log(800)/np.log(2**(1/12))
        # min_freq = 80
        # max_freq = 500
        self.plotSwipe.setYRange(min_freq,max_freq, padding=0)
        self.plotSwipe.showGrid(True,True,1)

        # to fix grid, the same for x axis
        ay = self.plotSwipe.getAxis('left')
        # np.exp(np.log(2**(1/12)*(value+0.5)))
        dy = [(value+0.5, str(value+0.5)) for value in range(int(min_freq),int(max_freq))]
        ay.setTicks([dy, []])

        ax = self.plotSwipe.getAxis('bottom')
        dx = [(value, str(value)) for value in np.arange(-10,0,0.75)]
        ax.setTicks([dx, []])
        # time_

        # self.plotSwipe.enableAutoScale()

        self.plot_swipe_item = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        # self.plot_swipe_item.setLogMode(False,True)
        # self.plot_swipe_item.setXRange(-10, 0, padding=0)
        # self.plot_swipe_item.setYRange(1, 3, padding=0)
        # self.plot_swipe_item.setLogMode(x=None,y=True)

    def audio_callback(self, in_data, frame_count, time_info, status):

        #print(time.time())
        #print('in callback')
        data = np.frombuffer(in_data,dtype=np.int16)
        #print(type(data.astype('float64')))
        self.unprocessed_sound.put(data)

        return(in_data,pyaudio.paContinue)

    def myExitHandler(self):
        #print('in exit')
        self.p.close(self.stream)
        self.shut_down_queue.put(True)
        self.proc.join()


    def update_plot(self):
        try:
            data = self.swipes_toplot.get_nowait()
        except queue.Empty:
            pass
            #print('no swipes')
        else:
            self.pitch = np.roll(self.pitch,-len(data))
            np.put(self.pitch,range(-len(data),-1),data)
            t0 = time.perf_counter()
            self.plot_swipe_item.setData(self.tp,np.log(self.pitch)/np.log(2**(1/12)))
            #print('plot time: ', time.perf_counter()-t0)



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
