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

def getPieceLength(xml):
        t = 0;
        for e in xml.flat.notesAndRests:
            t += e.seconds
        return t

class MyWidget(pg.GraphicsWindow):

    def __init__(self, xml, parent=None):
        super().__init__(parent=parent)


        self.xml      = xml  # xml file
        self.notes    = musicxml2notes(xml)
        self.curNote  = 0
        self.displayedNotes = []

        self.notesf = []
        self.tn             = []
        self.threshold = 1.03

        self.simTime       = 0 # current time in simulation
        self.endTime       = getPieceLength(self.xml)
        self.displayBefore = 5  # seconds displayed ahead of time
        self.displayAfter  = 5  # seconds of displayed history

        self.loop       = 0.2 # time between updates of plot in sec, not faster than 0.15-0.2
        self.pitchBatch = 10  # number of pitches to look for in each loop

        self.setupAudio()
        self.setup_plot()

        self.sound   = np.zeros(self.displayAfter*self.SAMPLERATE) # vector to store sound
        self.ts      = np.linspace(0,self.endTime,len(self.sound))

        self.pitches = np.zeros(int(self.displayAfter*self.pitchBatch/self.loop)) # vector to store pitch estimates
        self.tp      = np.linspace(0,self.endTime,len(self.pitches))

        self.dt = int(self.loop/self.displayAfter*self.SAMPLERATE)

        self.startTimer()

        

    def startTimer(self):
        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(self.loop*1000) # in milliseconds
        self.timer.start()
        self.timer.timeout.connect(self.timerEvent)

    def setupAudio(self):
        FORMAT     = pyaudio.paInt16
        CHANNELS   = 1
        self.SAMPLERATE  = 48000   # TODO: find input sampling frequency
        self.CHUNK = int(self.loop*self.SAMPLERATE)

        p = pyaudio.PyAudio()
        self.stream = p.open(
            format   = FORMAT,
            channels = CHANNELS,
            rate     = self.SAMPLERATE,
            input    = True,
            output   = True,
            #stream_callback=self.audio_callback,
            frames_per_buffer=self.CHUNK
        )

    def setup_plot(self):
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        self.plotSwipe = self.addPlot(title="Swipe pitch estimates", row=1, col=0)
        self.plotSound = self.addPlot(title="Sound", row=0, col=0)
        #self.plotSwipe.setLogMode(False,True)
        #self.plotSwipe.enableAutoScale()

        self.plotPitches = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,0,0), symbolSize=5, symbolPen=None)
        self.plotNotes = self.plotSwipe.plot([], pen=None,
            symbolBrush=(0,0,255), symbolSize=2, symbolPen=None, connect='pairs')
        self.plotSound = self.plotSound.plot()

    def timerEvent(self):
        if self.simTime > self.endTime:
            self.timer.stop()
        self.simTime += self.loop
        self.updateSound()
        self.updateNotes()
        self.addNotes()
        self.draw()

    def updateSound(self):
        data = np.frombuffer(self.stream.read(self.CHUNK,exception_on_overflow=False), dtype=np.int16)
        data = data.astype('float64')

        self.sound = np.roll(self.sound,-len(data))
        np.put(self.sound,range(-len(data),-1),data)
        self.ts += self.loop

        sw = swipe(data,self.SAMPLERATE,self.dt,min=40,max=700,threshold=0.25)
        self.pitches = np.roll(self.pitches,-len(sw))
        np.put(self.pitches,range(-len(sw),-1),sw)
        self.tp += self.loop

    def updateNotes(self):
        while self.curNote < len(self.notes) and self.notes[self.curNote][1] < self.simTime:
            self.displayedNotes.append(self.notes[self.curNote])
            self.curNote += 1
        if len(self.displayedNotes) > 0 and self.displayedNotes[0][2] < self.simTime - self.displayBefore:
            del(self.displayedNotes[0])
            del(self.tn[0:7])
            del(self.notesf[0:7])

    def draw(self):
        self.plotPitches.setData(self.tp, self.pitches)
        self.plotSound.setData(  self.ts, self.sound)
        self.plotNotes.setData(  self.tn, self.notesf)

    def addNotes(self):
        for note in self.displayedNotes:
            t = [note[0], note[1]]
            t = [val for val in t for _ in (0, 1)]
            t = np.roll(t,1)
            f = [note[2]/self.threshold, note[2]*self.threshold]
            f = [val for val in t for _ in (0, 1)]
            f = np.roll(f,1)

        if len(self.displayedNotes) > 0:
            self.tn.append(t)
            self.notesf.append(f)


def main():
    app = QtWidgets.QApplication([])

    pg.setConfigOptions(antialias=True) # True seems to work as well

    win = MyWidget(piece)
    win.show()
    win.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
