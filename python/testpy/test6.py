# plotting
from PyQt5 import QtCore, QtWidgets, QtGui
import pyqtgraph as pg
from music21 import *

import pyaudio
import sys
import time

import multiprocessing as mp
import queue

from pysptk.sptk import swipe
import numpy as np
import math

global BASE
BASE = np.log(2**(1/12))

class RTSwipe:
    def __init__(self,RATE=48000,CHUNK=6000,minfreq=50,maxfreq=1500,threshold=0.25):
        self.minfreq=minfreq
        self.maxfreq=maxfreq
        self.threshold=threshold

        # CHANNELS = 1
        self.RATE  = RATE
        self.CHUNK = CHUNK#2*2048
        self.swipesPerChunk = math.floor(CHUNK/(RATE*0.02)) # 20 ms per swipe estimate
        # FORMAT   = pyaudio.paInt16
        self.cnt = 0

        # self.t0 = time.time()
        # self.t  = self.t0

        self.sound    = mp.Queue()
        self.times    = mp.Queue()
        self.swipes   = mp.Queue()
        self.shutDown = mp.Queue()

        self.audio= pyaudio.PyAudio()

    def start_swipe(self,t):
        CHANNELS = 1
        FORMAT   = pyaudio.paInt16
        self.t0 = t
        self.t  = self.t0
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

    def set_time(self,t):
        self.t0 = t
        self.t  = self.t0

    def audioCallback(self, in_data, frame_count, time_info, status):
        #print('in callback')
        sound = np.frombuffer(in_data,dtype=np.int16)
        times = np.linspace(self.t-self.t0,time.time()-self.t0,
                            self.swipesPerChunk,True)
        self.t = time.time()
        self.sound.put(sound)
        self.times.put(times)
        return(in_data,pyaudio.paContinue)

    def swipeSound(self):
        while True:
            if not self.shutDown.empty():
                break
            try:
                data = self.sound.get_nowait()
            except queue.Empty:

                time.sleep(0.04)
            else:
                data = data.astype('float64')
                sw = swipe(data, self.RATE, int(self.CHUNK/self.swipesPerChunk),
                            min=self.minfreq, max=self.maxfreq,
                            threshold=self.threshold)
                self.swipes.put(sw)
        return True

    def getSwipes(self):
        if not self.swipes.empty():
            swipes = self.swipes.get_nowait()
            times  = self.times.get_nowait()
            newSwipes = []
            newTimes  = []
            for i in range(0,len(swipes)):
                if swipes[i] > 0:
                    newSwipes.append(np.log(swipes[i]/8.17578)/BASE + 1/2)
                    newTimes.append(times[i])
            return newSwipes, newTimes
        return [], []

    def exitHandler(self):
        print('in exit')
        self.audio.close(self.stream)
        self.shutDown.put(True)
        self.process.join()


class NotesWizard:
    def __init__(self, filePath):
        self.piece = converter.parse(filePath)

        self.timeSig = (self.piece.flat.
                        getElementsByClass(meter.TimeSignature)[0].numerator)
        self.tempo   = (self.piece.flat.
                        getElementsByClass(tempo.MetronomeMark)[0].number)

        midimax = 0
        midimin = 9999
        t = 0
        for e in self.piece.flat.notesAndRests:
            setattr(e,"time",t)
            setattr(e,"globBeat",e.measureNumber+e.beat-2)
            if e.isNote:
                midimax = max(midimax,e.pitch.midi)
                midimin = min(midimin,e.pitch.midi)
                rect = pg.QtGui.QGraphicsRectItem(t, e.pitch.midi-1/2,
                                                    e.seconds, 2**(1/12))
                rect.setPen(pg.mkPen((0, 0, 0, 100)))
                rect.setBrush(pg.mkBrush((127, 127, 127)))
                setattr(e,"rect",rect)
                setattr(e,'nbr_hits', 0)
                setattr(e,'nbr_tries',0)
                setattr(e,'ratio',0.5)

            t += e.seconds



    def getNotesAndRests(self):
        return self.piece.flat.notesAndRests

    def getTimeSig(self):
        return self.timeSig

    def getTempo(self):
        return self.tempo



class RollWindow(pg.GraphicsWindow):
    def __init__(self,sweeper,notesWizard,parent=None,updateInterval=20,timeWindow=10):
        super().__init__(parent=parent)
        self.notesWizard = notesWizard
        self.sweeper = sweeper
        self.updateInterval = updateInterval
        self.timeWindow = timeWindow
        # self.t0 = time.time()
        self.t  = 0

        # self.setLayout(self.mainLayout)
        # self.btn_box = self.addLayout()
        # self.btn_box.setLayout(self.mainLayout)
        # btn_box.addWidget(self.start_button)
        # box = super().addVeiwBox()
        # self.addWidget(self.start_button)

        # print(dir(self))

        # print(super())
        # self.layout.setRowStretchFactor(0, 0)
        # self.layout.setRowStretchFactor(1, 13)
        lay = self.ci.layout
        lay.setRowStretchFactor(0, 1)
        lay.setRowStretchFactor(1, 10)

        # self.addViewBox(row=0,col=0)
        # btn_layout = QtWidgets.QVBoxLayout()
        #
        # self.start_button = QtGui.QPushButton("Start")
        # self.start_button.move(0,-100)
        #
        # self.start_button.clicked.connect(self.start_pressed)
        # btn_layout.addWidget(self.start_button)
        # self.setLayout(btn_layout)

        btn_layout = QtWidgets.QHBoxLayout()
        proxy = QtGui.QGraphicsProxyWidget()
        start_button = QtGui.QPushButton("Start")
        start_button.clicked.connect(self.start_pressed)
        btn_layout.addWidget(start_button)
        proxy.setWidget(start_button)
        p1 = self.addLayout(row=0,col=0)
        p1.addItem(proxy)

        # print(dict(self.getItem(0,0)))
        # self.getItem(0,0).addWidget(self.start_button)


        # self.layout.setMaximumHeight(10)
        # print(dict(self.layout))
        # self.layoutRowStretch = [0, 13, 8]
        #
        # self.plot_box = self.addViewBox(row=1,col=0)
        # print(dir(self.btn_box))


        self.swipes = []
        self.times  = []

        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(updateInterval) # in milliseconds
        # self.timer.start()
        self.timer.timeout.connect(self.update)

        timeSig = notesWizard.getTimeSig()
        tempo   = notesWizard.getTempo()


        self.plotSwipe = self.addPlot(row=1,col=0,title="Swipe pitch estimates")
        self.plotSwipe.setYRange(36, 83, padding=0)
        self.plotSwipe.setXRange(-timeWindow/2, timeWindow/2, padding=0)

        self.xAxisSwipe = self.plotSwipe.getAxis("bottom")
        self.xAxisSwipe.setTickSpacing(major=60/tempo*timeSig, minor=60/tempo)
        self.yAxisSwipe = self.plotSwipe.getAxis("left")
        self.rightAxisSwipe = self.plotSwipe.getAxis("right")
        self.rightAxisSwipe.setTickSpacing(levels=[(12,-0.5), (1,-0.5)])

        majorTicks = []
        minorTicks = []
        for i in range(0,127):
            p = pitch.Pitch()
            p.midi = i
            if i%12==0:
                majorTicks.append((i-1/2, p.nameWithOctave))
            minorTicks.append((i-1/2, p.nameWithOctave))
        self.yAxisSwipe.setTicks([majorTicks,minorTicks])
        self.plotSwipe.showGrid(x=True, y=True, alpha=0.5)
        self.yAxisSwipe.setTickSpacing(levels=[(12,-0.5), (1,-0.5)])

        # Notes
        for e in notesWizard.getNotesAndRests():
            if e.isNote:
                self.plotSwipe.addItem(e.rect)
        # Swipe estimates
        self.plot_swipe_item = self.plotSwipe.plot([], pen=None,
            symbolBrush=(255,255,255), symbolSize=5, symbolPen=None)
        # Now line
        self.nowLine = pg.InfiniteLine(0,90)
        self.plotSwipe.addItem(self.nowLine)

        # self.notes_iter = self.notesWizard.getNotesAndRests()
        self.notes_iter = self.notesWizard.piece.flat.notes
        self.current_note = next(self.notes_iter)
        self.notes_done = False
        self.score = 0
        self.total_swipes = 0



        # hbox = QHBoxLayout(self.start_button)
        # hbox.addWidget()

        # self.mainLayout.addWidget(self.start_button)




    def start_pressed(self):
        self.t0 = time.time()
        if not self.timer.isActive():
            print('start')
            self.sweeper.start_swipe(self.t0)
            self.timer.start()
        else:
            self.sweeper.set_time(self.t0)

    def update_score(self):
        if self.current_note.isNote:
            prev_hits           =   self.score*self.total_swipes
            self.total_swipes   +=  (self.current_note.seconds*
                                    self.sweeper.swipesPerChunk*
                                    self.sweeper.RATE/self.sweeper.CHUNK)
            self.score          =   ((prev_hits+self.current_note.nbr_hits)
                                    /self.total_swipes)

        # swipes = (self.current_note.seconds*self.sweeper.swipesPerChunk*
        #                             self.sweeper.RATE/self.sweeper.CHUNK)
        # self.score += self.current_note.nbr_hits/swipes
        # print(self.score)


    def set_current(self, time):

        if (time >= (self.current_note.time + self.current_note.seconds) and
                                                    not self.notes_done):
            self.update_score()
            try:
                self.current_note = next(self.notes_iter)
            except StopIteration:
                self.notes_done = True

    def assess_pitch(self, pitches, times):
        for (p,t) in zip(pitches,times):
            self.set_current(t)
            if self.current_note.isNote:
                self.current_note.nbr_tries += 1
                if (p >= self.current_note.pitch.midi-3 and
                                p <= self.current_note.pitch.midi+3): #ändra till +- 1/2 när någon som kan ta toner ska testa...
                    self.current_note.nbr_hits += 1
                ratio = self.current_note.nbr_hits/self.current_note.nbr_tries
                self.current_note.rect.setBrush(pg.mkBrush((255*(1-ratio),
                                                                255*ratio,0)))


    def update(self):
        newSwipes, newTimes = self.sweeper.getSwipes()
        if len(newSwipes) > 0 and not self.notes_done:
            # self.notesWizard.assess_pitch(newSwipes, newTimes)
            self.assess_pitch(newSwipes, newTimes)
        self.swipes += newSwipes
        self.times  += newTimes
        if len(self.swipes) > 0:
            self.plot_swipe_item.setData(self.times,self.swipes)
        dt = (time.time()-self.t0 - self.t)
        xRange = self.xAxisSwipe.range
        self.plotSwipe.setXRange(xRange[0]+dt, xRange[1]+dt, padding=0)
        self.t = time.time()-self.t0
        self.nowLine.setValue(self.t)

def main():
    app = QtWidgets.QApplication([])
    pg.setConfigOptions(antialias=False) # True seems to work as well

    sweeper    = RTSwipe()
    wizard     = NotesWizard("Vem_kan_segla.musicxml")
    rollWindow = RollWindow(sweeper,wizard,updateInterval=70)
    app.aboutToQuit.connect(sweeper.exitHandler)
    rollWindow.show()
    rollWindow.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
