from PyQt5 import QtCore, QtWidgets
import pyqtgraph as pg
import numpy as np

import struct
import pyaudio
import sys
import time

from pysptk.sptk import swipe
from music21 import *

pg.setConfigOption('background', 'k')

def musicxml2notes(file):
    notes = []
    t = 0
    for element in file.flat.notesAndRests:
        tStart = t
        t+=element.seconds
        tEnd   = t
        if element.isNote:
            notes.append((tStart, tEnd, element.pitch.freq440))
    return notes

piece = converter.parse("Vem_kan_segla.musicxml")
notes = musicxml2notes(piece)

def notesTimeMap(times,notes):
    timeNotes = np.zeros(len(times))
    curTime   = 0
    for note in notes:
        while curTime < len(times) and times[curTime] < note[0]:
            curTime += 1
        while curTime < len(times) and times[curTime] < note[1]:
            timeNotes[curTime] = note[2]
            curTime += 1
    return timeNotes

class MyWidget(pg.GraphicsWindow):

    def __init__(self, notes, parent=None):
        super().__init__(parent=parent)
        self.notes = notes
        self.simstep = 0
        self.loop = 0.2     # time between updates of plot in sec, not faster than 0.15-0.2
        self.nbr_pitch = 10      # number of pitches to look for in each loop
        startTime = -2
        endTime   = notes[2,-1]

        self.setup_pyaudio(self.loop)
        self.setup_datavar(self.loop, startTime, endTime, self.nbr_pitch, self.loop)
        self.setup_plot(self.loop)

    def setup_pyaudio(self,loop):
        FORMAT     = pyaudio.paInt16
        CHANNELS   = 1
        self.RATE  = 44100
        self.CHUNK = int(loop*self.RATE)

        p = pyaudio.PyAudio()
        self.stream = p.open(
            format   = FORMAT,
            channels = CHANNELS,
            rate     = self.RATE,
            input    = True,
            output   = True,
            #stream_callback=self.audio_callback,
            frames_per_buffer=self.CHUNK
        )

    def setup_datavar(loop, startTime, endTime, nbr_pitch, loop):
        dTime = endTime-startTime

        self.sound = np.zeros(dTime*self.RATE)
        self.t     = np.linspace(startTime,endTime,len(sound))

        
        self.pitch = np.zeros(int(dTime*nbr_pitch/loop))
        self.tp    = np.linspace(startTime,endTime,num=len(self.pitch))
        

    def setup_plot(self,loop):
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)


        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(loop*1000) # in milliseconds
        self.timer.start()
        self.timer.timeout.connect(self.onNewData2)

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates", row=1, col=0)
        self.plotSound = self.addPlot(title="Sound", row=0, col=0)
        #self.plotSwipe.setLogMode(False,True)
        #self.plotSwipe.enableAutoScale()

        self.plotPitches = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        self.plotNotesUpper = self.plotSwipe.plot([], pen=None,
            symbolBrush=(0,0,255), symbolSize=2, symbolPen=None)
        self.plotNotesLower = self.plotSwipe.plot([], pen=None,
            symbolBrush=(0,0,255), symbolSize=2, symbolPen=None)
        self.plotSound = self.plotSound.plot()


    # def audio_callback(self, in_data, frame_count, time_info, status):
    #     audio_data = np.frombuffer(in_data, dtype=np.int16)
    #     audio_data = audio_data.astype('float16')
    #     self.sound = np.roll(self.sound,-len(audio_data))
    #     np.put(self.sound,range(-len(audio_data),-1),audio_data)

    #     return(in_data,pyaudio.paContinue)


    def onNewData2(self):
        noteTimes = notesTimeMap(self.tp+self.simstep*self.loop,notes)
        self.plotNotesLower.setData(self.tp, noteTimes/1.03)
        self.plotNotesUpper.setData(self.tp, noteTimes*1.03)

        data = np.frombuffer(self.stream.read(self.CHUNK,exception_on_overflow=False), dtype=np.int16)
        data = data.astype('float64')

        samples = self.RATE*self.loop
        self.sound[(0:samples-1)+simstep*samples] = data
        np.put(self.sound,range(-len(data),-1),data)

        sw = swipe(data,self.RATE,self.dt,min=40,max=700,threshold=0.25)
        self.pitch[0:] = np.roll(self.pitch,-len(sw))
        np.put(self.pitch,range(-len(sw),-1),sw)
        
        self.plotPitches.setData(self.tp, self.pitch)
        self.plotSound.setData(self.t, self.sound)

        self.simstep += 1

        

    def onNewData(self):
        # data = np.array(struct.unpack(str(self.CHUNK) + 'h', self.stream.read(self.CHUNK,exception_on_overflow = False)))
        data = np.frombuffer(self.stream.read(self.CHUNK,exception_on_overflow=False), dtype=np.int16)
        data = data.astype('float64')

        self.sound = np.roll(self.sound,-len(data))
        np.put(self.sound,range(-len(data),-1),data)

        sw = swipe(data,self.RATE,self.dt,min=40,max=700,threshold=0.25)
        self.pitch = np.roll(self.pitch,-len(sw))
        np.put(self.pitch,range(-len(sw),-1),sw)

        
        self.plotPitches.setData(self.tp, self.pitch)
        self.plotSound.setData(self.t, self.sound)


def main():
    app = QtWidgets.QApplication([])

    pg.setConfigOptions(antialias=True) # True seems to work as well

    win = MyWidget(notes)
    win.show()
    win.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
