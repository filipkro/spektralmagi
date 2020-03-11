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

        loop = 0.2          # time between updates of plot in sec, not faster than 0.15-0.2
        nbr_pitch = 10      # number of pitches to look for in each loop
        nbr_sec = 10        # number of seconds to display
        self.nbr_chunks = 4

        self.setup_pyaudio(loop)
        self.setup_datavar(nbr_pitch, nbr_sec, loop)
        self.setup_plot(loop)


    def setup_pyaudio(self,loop):
        FORMAT = pyaudio.paInt16

        CHANNELS = 1
        self.RATE = 44100
        # self.CHUNK = int(loop*self.RATE)
        self.CHUNK = self.nbr_chunks*2048


        p = pyaudio.PyAudio()
        self.stream = p.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=self.RATE,
            input=True,
            output=True,
            stream_callback=self.audio_callback,
            frames_per_buffer=self.CHUNK
        )

    def setup_datavar(self,nbr_pitch,nbr_sec,loop):
        self.t = np.linspace(-nbr_sec,0,num=nbr_sec*self.RATE)
        self.sound = np.zeros(10*self.RATE)
        # self.dt = int(loop/nbr_sec*self.RATE)
        self.dt = int(self.nbr_chunks*self.CHUNK/nbr_pitch)
        self.pitch = np.zeros(int(nbr_pitch/self.dt*self.RATE))
        self.tp = np.linspace(-nbr_sec,0,num=len(self.pitch))

    def setup_plot(self,loop):
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(loop*1000) # in milliseconds
        self.timer.start()
        # self.timer.timeout.connect(self.onNewData)

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates", row=1, col=0)
        self.plotSound = self.addPlot(title="Sound", row=0, col=0)
        # self.plotSwipe.setLogMode(False,True)
        # self.plotSwipe.enableAutoScale()

        self.plotDataItem = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        self.plotSoundData = self.plotSound.plot()

    def audio_callback(self, in_data, frame_count, time_info, status):
        t = time.perf_counter()
        audio_data = np.frombuffer(in_data, dtype=np.int16)
        self.sound = np.roll(self.sound,-len(audio_data))
        np.put(self.sound,range(-len(audio_data),-1),audio_data)
        audio_data = audio_data.astype('float64')

        sw = swipe(audio_data,self.RATE,self.dt,min=40,max=1200,threshold=0.25)
        # sw[sw==0] = np.nan
        self.pitch = np.roll(self.pitch,-len(sw))
        np.put(self.pitch,range(-len(sw),-1),sw)

        self.update_plot()
        print(time.perf_counter()-t)
        return(in_data,pyaudio.paContinue)

    def onNewData(self):
        # data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
        data = np.frombuffer(self.stream.read(self.CHUNK,exception_on_overflow=False), dtype=np.int16)
        self.sound = np.roll(self.sound,-len(data))
        np.put(self.sound,range(-len(data),-1),data)
        data = data.astype('float64')

        sw = swipe(data,self.RATE,self.dt,min=40,max=1200,threshold=0.25)


        self.pitch = np.roll(self.pitch,-len(sw))
        np.put(self.pitch,range(-len(sw),-1),sw)

        self.plotDataItem.setData(self.tp, self.pitch)
        self.plotSoundData.setData(self.t, self.sound)

    def update_plot(self):

        self.plotDataItem.setData(self.tp, self.pitch)
        self.plotSoundData.setData(self.t, self.sound)


def main():
    app = QtWidgets.QApplication([])

    pg.setConfigOptions(antialias=False) # True seems to work as well

    win = MyWidget()
    win.show()
    win.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
