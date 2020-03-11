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

        self.loop = 0.2          # time between updates of plot in sec, not faster than 0.15-0.2
        self.nbr_pitch = 10      # number of pitches to look for in each loop
        nbr_sec = 10        # number of seconds to display
        self.busy = False
        self.temp = np.empty(0,dtype=np.int16)
        self.t0 = time.perf_counter()
        self.cnt = 1



        self.setup_plot(self.loop)
        self.setup_pyaudio(self.loop)
        self.setup_datavar(self.nbr_pitch, nbr_sec, self.loop)

    def setup_pyaudio(self,loop):
        FORMAT = pyaudio.paInt16
        CHANNELS = 1
        self.RATE = 44100
        self.CHUNK = 2048#int(loop*self.RATE/4)

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
        self.dt = int(loop/nbr_pitch*self.RATE)
        self.pitch = np.zeros(int(nbr_sec/self.dt*self.RATE))
        self.tp = np.linspace(-nbr_sec,0,num=len(self.pitch))

    def setup_plot(self,loop):
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        # self.timer = QtCore.QTimer(self)
        # self.timer.setInterval(loop*1000) # in milliseconds
        # self.timer.start()
        # self.timer.timeout.connect(self.onNewData)

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates", row=1, col=0)
        self.plotSound = self.addPlot(title="Sound", row=0, col=0)
        # self.plotSwipe.setLogMode(False,True)
        # self.plotSwipe.enableAutoScale()

        self.plotDataItem = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        self.plotSoundData = self.plotSound.plot()

    def audio_callback(self, in_data, frame_count, time_info, status):
        audio_data = np.frombuffer(in_data, dtype=np.int16)
        # audio_data = audio_data.astype('float16')
        if self.busy:
            self.temp = np.append(self.temp,audio_data)
        else:
            if len(self.temp) > 0:
                audio_data = np.append(self.temp,audio_data)
                self.temp = np.empty(0,dtype=np.int16)

            self.sound = np.roll(self.sound,-len(audio_data))
            np.put(self.sound,range(-len(audio_data),-1),audio_data)

        tloop = time.perf_counter()-self.t0
        print('time: ', tloop)
        if tloop > self.loop:
            self.t0 = time.perf_counter()
            self.calc_pitch()
            self.plotDataItem.setData(self.tp, self.pitch)
            self.cnt = 0
        else:
            self.cnt = self.cnt+1

        # audio_data = audio_data.astype('float64')
        # sw = swipe(audio_data,self.RATE,self.dt,min=40,max=700,threshold=0.15)
        # self.pitch = np.roll(self.pitch,-len(sw))
        # np.put(self.pitch,range(-len(sw),-1),sw)
        #
        # self.plotDataItem.setData(self.tp, self.pitch)
        # self.plotSoundData.setData(self.t, self.sound)
        self.plotSoundData.setData(self.t, self.sound)
        return(in_data,pyaudio.paContinue)

    def calc_pitch(self):
        print('calc')
        self.busy = True
        dl = self.cnt*self.CHUNK
        dt = int(dl/self.nbr_pitch)
        data = self.sound[range(-dl,-1)]
        data = data.astype('float64')
        print(dl)
        sw = swipe(data,self.RATE,dt,min=40,max=700,threshold=0.15)
        self.pitch = np.roll(self.pitch,-len(sw))

        # self.plotSoundData.setData(self.t, self.sound)
        self.busy = False

    def onNewData(self):

        tp = time.clock()-self.t0
        dt = int(tp/self.nbr_pitch*self.RATE)
        print('tp: ', tp)
        self.t0 = time.clock()
        # data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
        # data = np.frombuffer(self.stream.read(self.CHUNK,exception_on_overflow=False), dtype=np.int16)
        # data = data.astype('float64')
        # self.sound = np.roll(self.sound,-len(data))
        data = self.sound[range(-int(tp*self.RATE),-1)]
        # np.put(self.sound,range(-len(data),-1),data)
        # sw = swipe(data,self.RATE,dt,min=40,max=700,threshold=0.15)
        # self.pitch = np.roll(self.pitch,-len(sw))
        # np.put(self.pitch,range(-len(sw),-1),sw)

        # self.plotDataItem.setData(self.tp, self.pitch)
        # self.plotSoundData.setData(self.t, self.sound)


def main():
    app = QtWidgets.QApplication([])

    pg.setConfigOptions(antialias=False) # True seems to work as well

    win = MyWidget()
    win.show()
    win.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
