from PyQt5 import QtCore, QtWidgets
import pyqtgraph as pg
import numpy as np

import struct
import pyaudio
import sys
import time

from pysptk.sptk import swipe

# win = None
# app = None


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
            stream_callback=self.audio_callback,
            frames_per_buffer=self.CHUNK
        )

        nbr_pitch = 9
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

        # print(self.plotSwipe.getViewBox())

        self.plotDataItem = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        self.plotSoundData = self.plotSound.plot()

        self.t0 = time.process_time()
        self.tcallb = time.process_time()

    def audio_callback(self, in_data, frame_count, time_info, status):

        # print('callb period: ', time.process_time() - self.tcallb) this print fucks things up sometimes..
        # self.tcallb = time.process_time()
        # audio_data = np.frombuffer(in_data, dtype=np.int16)
        # audio_data = audio_data.astype('float16')
        audio_data = np.array(struct.unpack(str(self.CHUNK) + 'h', in_data))
        audio_data = audio_data.astype('float64')
        # print(audio_data)
        # print(len(audio_data))
        # print(self.CHUNK)
        self.sound = np.roll(self.sound,-len(audio_data))
        np.put(self.sound,range(-len(audio_data),-1),audio_data)

        # print(audio_data)
        sw = swipe(audio_data,self.RATE,self.dt,min=40,max=1000,threshold=0.2)
        self.pitch = np.roll(self.pitch,-len(sw))
        np.put(self.pitch,range(-len(sw),-1),sw)

        # print('in_data: ',len(in_data))
        print('audio_data: ', len(audio_data))
        return(in_data,pyaudio.paContinue)

        #np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK))

    def onNewData(self):
        tp = time.process_time()-self.t0
        self.t0 = time.process_time()
        print('tp: ', tp)
        #
        # data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
        # data = data.astype('float64')
        # self.sound = np.roll(self.sound,-len(data))
        # np.put(self.sound,range(-len(data),-1),data)
        # data = self.sound[range(-int(tp*self.RATE),-1)]

        # print(-int(tp/self.RATE))
        # print(len(data))
        # print(len(self.sound))
        # print('len data: ', len(data))

        # t1 = time.process_time()
        # sw = swipe(data,self.RATE,self.dt,min=40,max=1000,threshold=0.2)
        # print('swipe time: ', time.process_time()-t1)
        # print(time.process_time()-t1)

        # self.pitch = np.roll(self.pitch,-len(sw))

        # np.put(self.pitch,range(-len(sw),-1),sw)

        # t3 = time.process_time()
        self.plotDataItem.setData(self.tp, self.pitch)
        # t4 = time.process_time()
        # print('plot pitch: ', t4-t3)
        self.plotSoundData.setData(self.t, self.sound)
        # print('plot sound: ',time.process_time()-t4)


def main():
    # global win, app
    app = QtWidgets.QApplication([])

    pg.setConfigOptions(antialias=False) # True seems to work as well

    win = MyWidget()
    app.aboutToQuit.connect(myExitHandler)
    win.show()
    # win.resize(800,600)
    win.raise_()
    app.exec_()

def myExitHandler():
    # global win, app
    time.sleep(0.2)
    # app = None
    # print(win.plotSwipe.getViewBox())
    # win.plotSwipe.clear()
    # win.plotSound.clear()
    # print('cleared')

    # del win

if __name__ == "__main__":
    main()
