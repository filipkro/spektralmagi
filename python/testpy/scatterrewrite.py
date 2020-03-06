from PyQt5 import QtCore, QtWidgets
import pyqtgraph as pg
import numpy as np

import struct
import pyaudio
import sys
import time

from pysptk.sptk import swipe


class MyWidget(pg.GraphicsWindow):

    def __init__(self, parent=None):
        super().__init__(parent=parent)

        # self.loop = 0.2
        # # pyaudio stuff
        # self.FORMAT = pyaudio.paInt16
        # self.CHANNELS = 1
        # self.RATE = 44100
        # self.CHUNK = int(self.loop*self.RATE)

        # self.p = pyaudio.PyAudio()
        # self.stream = self.p.open(
        #     format=self.FORMAT,
        #     channels=self.CHANNELS,
        #     rate=self.RATE,
        #     input=True,
        #     output=True,
        #     frames_per_buffer=self.CHUNK,
        # )

        # self.t = np.linspace(-10,0,num=10*self.RATE)
        # self.sound = np.zeros(10*self.RATE)
        # self.dt = int(self.loop/10*self.RATE)
        # self.pitch = np.zeros(int(10/self.dt*self.RATE))
        # self.tp = np.linspace(-10,0,num=len(self.pitch))

        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        # self.timer = QtCore.QTimer(self)
        # self.timer.setInterval(15) # in milliseconds
        # self.timer.start()
        # self.timer.timeout.connect(self.onNewData)

        self.plotItem = self.addPlot(title="Swipe pitch estimates")

        self.plotDataItem = self.plotItem.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)


    def setData(self, x, y):
        print(y)
        self.plotDataItem.setData(x, y)


    def onNewData(self):

        # data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
        # data = data.astype('float64')
        # self.sound = np.roll(self.sound,-len(data))
        #
        # sw = swipe(data,self.RATE,self.dt,min=40,max=1000,threshold=0.25)
        #
        # self.pitch = np.roll(self.pitch,-len(sw))
        #
        # np.put(self.sound,range(-len(data),-1),data)
        # np.put(self.pitch,range(-len(sw),-1),sw)

        self.setData(self.tp, self.pitch)


def main():

    loop = 0.2
    # pyaudio stuff
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = 44100
    CHUNK = int(loop*RATE)

    p = pyaudio.PyAudio()
    stream = p.open(
        format=FORMAT,
        channels=CHANNELS,
        rate=RATE,
        input=True,
        output=True,
        frames_per_buffer=CHUNK,
    )

    t = np.linspace(-10,0,num=10*RATE)
    sound = np.zeros(10*RATE)
    dt = int(loop/10*RATE)
    pitch = np.zeros(int(10/dt*RATE))
    tp = np.linspace(-10,0,num=len(pitch))



    app = QtWidgets.QApplication([])

    pg.setConfigOptions(antialias=False) # True seems to work as well

    win = MyWidget()
    win.show()
    win.resize(800,600)
    win.raise_()
    # app.exec_()

    while True:
        t0 = time.process_time()
        data = np.array(struct.unpack(str(CHUNK) + 'h', stream.read(CHUNK,exception_on_overflow = False)))
        data = data.astype('float64')
        sound = np.roll(sound,-len(data))

        sw = swipe(data,RATE,dt,min=40,max=1000,threshold=0.25)

        pitch = np.roll(pitch,-len(sw))

        np.put(sound,range(-len(data),-1),data)
        np.put(pitch,range(-len(sw),-1),sw)

        win.setData(tp, pitch)

        twait = loop - (time.process_time()-t0)
        if twait > 0:
            time.sleep(twait)
            print(twait)



if __name__ == "__main__":
    main()
