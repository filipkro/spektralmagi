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

        loop = 0.2
        # pyaudio stuff
        FORMAT = pyaudio.paInt16
        CHANNELS   = 1
        self.RATE  = 44100
        self.CHUNK = int(loop*self.RATE)

        p = pyaudio.PyAudio()
        self.stream = p.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=self.RATE,
            input=True,
            output=True,
            #stream_callback=self.audio_callback,
            frames_per_buffer=self.CHUNK
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

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates", row=1, col=0)
        self.plotSound = self.addPlot(title="Sound", row=0, col=0)

        self.plotDataItem = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        self.plotSoundData = self.plotSound.plot()



    def audio_callback(self, in_data, frame_count, time_info, status):
        audio_data = np.frombuffer(in_data, dtype=np.int16)
        audio_data = audio_data.astype('float16')
        self.sound = np.roll(self.sound,-len(audio_data))
        np.put(self.sound,range(-len(audio_data),-1),audio_data)

        return(in_data,pyaudio.paContinue)

    def onNewData(self):
        data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
        data = data.astype('float64')
        self.sound = np.roll(self.sound,-len(data))
        np.put(self.sound,range(-len(data),-1),data)
        sw = swipe(data,self.RATE,self.dt,min=40,max=1000,threshold=0.2)
        self.pitch = np.roll(self.pitch,-len(sw))
        np.put(self.pitch,range(-len(sw),-1),sw)

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
