import numpy as np
from pyqtgraph.Qt import QtGui, QtCore
import pyqtgraph as pg

import struct
import pyaudio
from scipy.fftpack import fft

import sys
import time

from pysptk.sptk import swipe


class AudioStream(object):
    def __init__(self):

        # pyqtgraph stuff
        pg.setConfigOptions(antialias=True)
        self.traces = dict()
        self.app = QtGui.QApplication(sys.argv)
        self.win = pg.GraphicsWindow(title='Spectrum Analyzer')
        self.win.setWindowTitle('Spectrum Analyzer')
        self.win.setGeometry(5, 115, 900, 500)

        wf_xlabels = [(0, '0'), (2048, '2048'), (4096, '4096')]
        wf_xaxis = pg.AxisItem(orientation='bottom')
        wf_xaxis.setTicks([wf_xlabels])

        wf_ylabels = [(0, '0'), (127, '128'), (255, '255')]
        wf_yaxis = pg.AxisItem(orientation='left')
        wf_yaxis.setTicks([wf_ylabels])

        sp_xlabels = [
            (np.log10(10), '10'), (np.log10(100), '100'),
            (np.log10(1000), '1000'), (np.log10(22050), '22050')
        ]
        sp_xaxis = pg.AxisItem(orientation='bottom')
        sp_xaxis.setTicks([sp_xlabels])

        self.waveform = self.win.addPlot(
            title='Sound', row=1, col=1, axisItems={'bottom': wf_xaxis, 'left': wf_yaxis},
        )
        self.spectrum = self.win.addPlot(
            title='Swipe', pen=None, symbol='o', row=2, col=1, axisItems={'bottom': sp_xaxis},
        )
        # self.scatter = pg.ScatterPlotItem(pen=pg.mkPen(width=5, color='r'), symbol='o', size=1)
        # self.spectrum = self.win.addItem(self.scatter)

        self.loop = 0.2
        # pyaudio stuff
        self.FORMAT = pyaudio.paInt16
        self.CHANNELS = 1
        self.RATE = 44100
        self.CHUNK = int(self.loop*self.RATE)

        self.traces['sound'] = self.waveform.plot(pen='c', width=3)
        self.waveform.setYRange(-7000, 7000, padding=0)
        self.waveform.setXRange(-10, 0, padding=0.005)

        symb = QtGui.QPainterPath()
        symb.addRect(QtCore.QRectF(-0.0, -0.5, 1, 1))
        # self.traces['swipe'] = self.spectrum.plot([], pen=None,
        #     symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        self.traces['swipe'] = self.spectrum.ScatterPlotItem()
        self.spectrum.setYRange(0, 700, padding=0)
        self.spectrum.setXRange(-10, 0, padding=0.005)

        self.p = pyaudio.PyAudio()
        self.stream = self.p.open(
            format=self.FORMAT,
            channels=self.CHANNELS,
            rate=self.RATE,
            input=True,
            output=True,
            frames_per_buffer=self.CHUNK,
        )
        # waveform and spectrum x points

        self.t = np.linspace(-10,0,num=10*self.RATE)
        self.sound = np.zeros(10*self.RATE)
        self.dt = int(self.loop/10*self.RATE)
        self.pitch = np.zeros(int(10/self.dt*self.RATE))
        self.tp = np.linspace(-10,0,num=len(self.pitch))

    def start(self):
        if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
            QtGui.QApplication.instance().exec_()

    def set_plotdata(self):
        self.traces['sound'].setData(self.t, self.sound)
        # self.traces['swipe'].setData(self.tp, self.pitch)
        self.traces['swipe'].setData(self.tp,self.pitch)

    def update(self):

        data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
        data = data.astype('float64')
        self.sound = np.roll(self.sound,-len(data))

        sw = swipe(data,self.RATE,self.dt,min=40,max=700,threshold=0.25)

        self.pitch = np.roll(self.pitch,-len(sw))

        np.put(self.sound,range(-len(data),-1),data)
        np.put(self.pitch,range(-len(sw),-1),sw)

        self.set_plotdata()


    def animation(self):
        timer = QtCore.QTimer()
        timer.timeout.connect(self.update)
        timer.start(self.loop*1000)
        self.start()


if __name__ == '__main__':

    audio_app = AudioStream()
    audio_app.animation()
