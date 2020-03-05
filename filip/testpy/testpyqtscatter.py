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

        loop = 0.15
        # pyaudio stuff
        FORMAT = pyaudio.paInt16
        CHANNELS = 1
        self.RATE = 44100
        self.CHUNK = int(loop*self.RATE)

        p = pyaudio.PyAudio()
        self.stream = p.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=self.RATE,
            input=True,
            output=True,
            frames_per_buffer=self.CHUNK,
        )

        nbr_pitch = 10
        nbr_sec = 10
        self.t = np.linspace(-nbr_sec,0,num=nbr_sec*self.RATE)
        self.sound = np.zeros(10*self.RATE)
        self.dt = int(loop/nbr_sec*self.RATE)
        self.pitch = np.zeros(int(nbr_pitch/self.dt*self.RATE))
        self.tp = np.linspace(-nbr_sec,0,num=len(self.pitch))

        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(loop*1000) # in milliseconds
        self.timer.start()
        self.timer.timeout.connect(self.onNewData)

        self.plotItem = self.addPlot(title="Swipe pitch estimates")

        self.plotDataItem = self.plotItem.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)

        self.t0 = time.process_time()


    def onNewData(self):
        print(time.process_time()-self.t0)
        self.t0 = time.process_time()
        try:
            data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK)))#,exception_on_overflow = False)))

        except:
            data = np.take(self.sound,range(-self.CHUNK,-1))
            #data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
            print('overflow')
        data = data.astype('float64')
        print(len(data))
        self.sound = np.roll(self.sound,-len(data))

        t1 = time.process_time()
        sw = swipe(data,self.RATE,self.dt,min=40,max=1000,threshold=0.25)
        print(time.process_time()-t1)

        self.pitch = np.roll(self.pitch,-len(sw))

        np.put(self.sound,range(-len(data),-1),data)
        np.put(self.pitch,range(-len(sw),-1),sw)

        self.plotDataItem.setData(self.tp, self.pitch)


def main():
    app = QtWidgets.QApplication([])
    app.aboutToQuit.connect(myExitHandler)
    pg.setConfigOptions(antialias=False) # True seems to work as well

    win = MyWidget()
    win.show()
    win.resize(800,600)
    win.raise_()
    app.exec_()



def myExitHandler():
    print('in exit')
    time.sleep(0.5)

if __name__ == "__main__":
    main()
