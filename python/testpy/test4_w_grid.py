# plotting
from PyQt5 import QtCore, QtWidgets
import pyqtgraph as pg

#
#import struct
import pyaudio
import sys
import time

import multiprocessing as mp
import queue

from pysptk.sptk import swipe
import numpy as np
import math

class RTSwipe:
    def __init__(self,RATE=44800,CHUNK=6000,minfreq=50,maxfreq=1500,threshold=0.25):
        self.minfreq=minfreq
        self.maxfreq=maxfreq
        self.threshold=threshold



        CHANNELS = 1
        self.RATE  = RATE
        self.CHUNK = CHUNK#2*2048
        self.swipesPerChunk = math.floor(CHUNK/(RATE*0.02)) # 20 ms per swipe estimate
        FORMAT   = pyaudio.paInt16
        self.cnt = 0
        tsave    = 10

        self.t0 = time.time()
        self.t  = self.t0

        self.sound    = mp.Queue()
        self.times    = mp.Queue()
        self.swipes   = mp.Queue()
        self.shutDown = mp.Queue()

        self.audio= pyaudio.PyAudio()
        self.stream = self.audio.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=self.RATE,
            input=True,
            output=False,
            stream_callback=self.audioCallback,
            frames_per_buffer=self.CHUNK
        )
        self.process = mp.Process(target=self.swipeSound)
        self.process.start()

        print("Process started")

    def audioCallback(self, in_data, frame_count, time_info, status):
        #print('in callback')
        sound  = np.frombuffer(in_data,dtype=np.int16)
        times = np.linspace(self.t-self.t0,time.time()-self.t0,
                            self.swipesPerChunk,True)
        self.t = time.time()
        self.sound.put(sound)
        self.times.put(times)
        #print("Sound len: " + str(len(sound)))
        return(in_data,pyaudio.paContinue)

    def swipeSound(self):
        while True:
            if not self.shutDown.empty():
                break
            try:
                data = self.sound.get_nowait()
            except queue.Empty:
                #print('queue empty')
                time.sleep(0.04)
            else:
                #print(self.sound.empty())
                # self.cnt = 0
                #print('Data length: ', len(data))
                data = data.astype('float64')
                #print(len(data))
                t0 = time.perf_counter()
                sw = swipe(data, self.RATE, int(self.CHUNK/self.swipesPerChunk),
                            min=self.minfreq, max=self.maxfreq,
                            threshold=self.threshold)
                #print('swipe time: ', time.perf_counter()-t0)
                self.swipes.put(sw)
                #print('swipe length: ', len(sw))
        return True


    def getSwipes(self):
        if not self.swipes.empty():
            print('swipe')
            swipes = self.swipes.get_nowait()
            times  = self.times.get_nowait()
            newSwipes = []
            newTimes  = []
            for i in range(0,len(swipes)):
                if swipes[i] > 0:
                    newSwipes.append(np.log(swipes[i])/np.log(2**(1/12)))
                    newTimes.append(times[i])
            return newSwipes, newTimes
        else:
            print('empty swipe')
        return [], []

    def exitHandler(self):
        print('in exit')
        self.audio.close(self.stream)
        self.shutDown.put(True)
        self.process.join()

class RollWindow(pg.GraphicsWindow):
    def __init__(self,sweeper,parent=None,updateInterval=20,timeWindow=10):
        super().__init__(parent=parent)
        self.sweeper = sweeper
        self.updateInterval = updateInterval
        self.timeWindow = timeWindow
        self.t0 = time.time()
        self.t  = 0
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        self.swipes = []
        self.times  = []

        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(updateInterval) # in milliseconds
        self.timer.start()
        self.timer.timeout.connect(self.update)

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates")
        # self.plotSwipe.setLogMode(x=False,y=True)

        min_freq = np.log(80)/np.log(2**(1/12))
        max_freq = np.log(800)/np.log(2**(1/12))

        self.plotSwipe.setYRange(min_freq, max_freq, padding=0)

        self.plot_swipe_item = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)

        r2 = pg.QtGui.QGraphicsRectItem(5, 1, 6, 3.2)
        r2.setPen(pg.mkPen((0, 0, 0, 100)))
        r2.setBrush(pg.mkBrush((50, 50, 200)))
        self.plotSwipe.showGrid(True,True)



        ay = self.plotSwipe.getAxis('left')
        dy = [(value+0.5, str(value+0.5)) for value in range(int(min_freq),int(max_freq))]
        ay.setTicks([dy, []])
        self.ax = self.plotSwipe.getAxis('bottom')

        self.plotSwipe.addItem(r2)
        self.ticks = np.arange(self.t-self.timeWindow/2,
                                 self.t+self.timeWindow/2,0.75)


    def update(self):
        self.plotSwipe.setXRange(self.t-self.timeWindow/2,
                                 self.t+self.timeWindow/2, padding=0)

        if self.t+self.timeWindow/2 > max(self.ticks):
            self.ticks = np.roll(self.ticks,-1)
            np.put(self.ticks,-1,max(self.ticks)+0.75)
            dx = [(val, str(int(val/0.75))) for val in self.ticks]
            print(dx)
            self.ax.setTicks([dx,[]])

        newSwipes, newTimes = self.sweeper.getSwipes()
        self.swipes += newSwipes
        self.times  += newTimes


        if len(self.swipes) > 0:
            self.plot_swipe_item.setData(self.times,self.swipes)
        # try:
        #     data, tp = self.sweeper.getPitches().get_nowait()
        # except queue.Empty:
        #     print('no swipes')
        # else:
        #     self.pitch = np.roll(self.pitch,-len(data))
        #     np.put(self.pitch,range(-len(data),-1),data)
        #     t0 = time.perf_counter()
        #     self.plot_swipe_item.setData(self.tp,np.log10(self.pitch))
        #     print('plot time: ', time.perf_counter()-t0)
        self.t = time.time()-self.t0


def main():
    app = QtWidgets.QApplication([])
    pg.setConfigOptions(antialias=False) # True seems to work as well

    sweeper    = RTSwipe()
    rollWindow = RollWindow(sweeper,updateInterval=40)
    app.aboutToQuit.connect(sweeper.exitHandler)
    rollWindow.show()
    rollWindow.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
