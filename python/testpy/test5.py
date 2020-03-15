# plotting
from PyQt5 import QtCore, QtWidgets
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

        CHANNELS = 1
        self.RATE  = RATE
        self.CHUNK = CHUNK#2*2048
        self.swipesPerChunk = math.floor(CHUNK/(RATE*0.02)) # 20 ms per swipe estimate
        FORMAT   = pyaudio.paInt16
        self.cnt = 0
        tsave    = 10

        self.t0 = time.time()
        self.t  = self.t0

        self.sound    = mp.Queue()
        self.times    = mp.Queue()
        self.swipes   = mp.Queue()
        self.shutDown = mp.Queue()

        self.audio= pyaudio.PyAudio()
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

    def audioCallback(self, in_data, frame_count, time_info, status):
        #print('in callback')
        sound = np.frombuffer(in_data,dtype=np.int16)
        times = np.linspace(self.t-self.t0,time.time()-self.t0,
                            self.swipesPerChunk,True)
        self.t = time.time()
        self.sound.put(sound)
        self.times.put(times)
        #print("Sound len: " + str(len(sound)))
        return(in_data,pyaudio.paContinue)

    def swipeSound(self):
        while True:
            if not self.shutDown.empty():
                break
            try:
                data = self.sound.get_nowait()
            except queue.Empty:
                #print('queue empty')
                time.sleep(0.04)
            else:
                #print(self.sound.empty())
                # self.cnt = 0
                #print('Data length: ', len(data))
                data = data.astype('float64')
                #print(len(data))
                t0 = time.perf_counter()
                sw = swipe(data, self.RATE, int(self.CHUNK/self.swipesPerChunk),
                            min=self.minfreq, max=self.maxfreq,
                            threshold=self.threshold)
                #print('swipe time: ', time.perf_counter()-t0)
                self.swipes.put(sw)
                #print('swipe length: ', len(sw))
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

        self.timeSig = self.piece.flat.getElementsByClass(meter.TimeSignature)[0].numerator
        self.tempo   = self.piece.flat.getElementsByClass(tempo.MetronomeMark)[0].number

        midimax = 0
        midimin = 9999
        t = 0
        for e in self.piece.flat.notesAndRests:
            setattr(e,"time",t)
            setattr(e,"globBeat",e.measureNumber+e.beat-2)
            if e.isNote:
                # print(e.pitch.midi)
                midimax = max(midimax,e.pitch.midi)
                midimin = min(midimin,e.pitch.midi)
                rect = pg.QtGui.QGraphicsRectItem(t, e.pitch.midi-1/2, e.seconds, 2**(1/12))
                rect.setPen(pg.mkPen((0, 0, 0, 100)))
                rect.setBrush(pg.mkBrush((127, 127, 127)))
                setattr(e,"rect",rect)
                setattr(e,'nbr_hits', 0)
                setattr(e,'nbr_tries',0)
                setattr(e,'ratio',0.5)

            t += e.seconds

        self.notes_iter = self.piece.flat.notes
        self.current_note = next(self.notes_iter)
        self.finished = False


    def getNotesAndRests(self):
        return self.piece.flat.notesAndRests

    def getTimeSig(self):
        return self.timeSig

    def getTempo(self):
        return self.tempo

    def set_current(self, time):
        # print('in set', time)
        # print('cond in set', self.current_note.time + self.current_note.seconds)
        if time >= (self.current_note.time + self.current_note.seconds) and not self.finished:
            try:
                self.current_note = next(self.notes_iter)
            except StopIteration:
                self.finished = True


    def assess_pitch(self, pitches, times):
        # print('assesspitch', times)
        for (p,t) in zip(pitches,times):
            # print('in for', t)
            self.set_current(t)
            if t >= self.current_note.time:
                self.current_note.nbr_tries += 1
                if p >= self.current_note.pitch.midi-2 and p <= self.current_note.pitch.midi+2: #ändra till +- 1/2 när någon som kan ta toner ska testa...
                    self.current_note.nbr_hits += 1
                self.current_note.ratio = self.current_note.nbr_hits/self.current_note.nbr_tries
                self.current_note.rect.setBrush(pg.mkBrush((255*(1-self.current_note.ratio),255*self.current_note.ratio,0)))
                print(self.current_note.ratio)




class RollWindow(pg.GraphicsWindow):
    def __init__(self,sweeper,notesWizard,parent=None,updateInterval=20,timeWindow=10):
        super().__init__(parent=parent)
        self.notesWizard = notesWizard
        self.sweeper = sweeper
        self.updateInterval = updateInterval
        self.timeWindow = timeWindow
        self.t0 = time.time()
        self.t  = 0
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.setLayout(self.mainLayout)

        self.swipes = []
        self.times  = []

        self.timer = QtCore.QTimer(self)
        self.timer.setInterval(updateInterval) # in milliseconds
        self.timer.start()
        self.timer.timeout.connect(self.update)

        timeSig = notesWizard.getTimeSig()
        tempo   = notesWizard.getTempo()


        self.plotSwipe = self.addPlot(title="Swipe pitch estimates")
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
        # self.current_note = next(self.notes_iter)


    def set_current(self, time):
        print('in set', time)
        print('cond in set', self.current_note.time + self.current_note.seconds)
        if time >= self.current_note.time + self.current_note.seconds:
            self.current_note = next(self.notes_iter)

    def assess_pitch(self, pitches, times):
        print('assesspitch', times)
        for (p,t) in zip(pitches,times):
            print('in for', t)
            self.set_current(t)
        print('after assesspitch', self.current_note.time)

    def update(self):
        newSwipes, newTimes = self.sweeper.getSwipes()

        if len(newSwipes) > 0:
            # print('in update', newTimes)
            self.notesWizard.assess_pitch(newSwipes, newTimes)
        self.swipes += newSwipes
        self.times  += newTimes
        if len(self.swipes) > 0:
            self.plot_swipe_item.setData(self.times,self.swipes)
        dt = (time.time()-self.t0 - self.t)
        xRange = self.xAxisSwipe.range
        self.plotSwipe.setXRange(xRange[0]+dt, xRange[1]+dt, padding=0)
        self.t = time.time()-self.t0
        self.nowLine.setValue(self.t)
        # test = self.notesWizard.getNotesAndRests().__iter__()
        # print(test)

def main():
    app = QtWidgets.QApplication([])
    pg.setConfigOptions(antialias=False) # True seems to work as well

    sweeper    = RTSwipe()
    wizard     = NotesWizard("Vem_kan_segla.musicxml")
    rollWindow = RollWindow(sweeper, wizard,updateInterval=70)
    app.aboutToQuit.connect(sweeper.exitHandler)
    rollWindow.show()
    rollWindow.raise_()
    app.exec_()

if __name__ == "__main__":
    main()
