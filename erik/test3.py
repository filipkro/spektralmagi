from music21 import *
from tkinter import *
from tkinter import filedialog
import threading


#path = filedialog.askopenfilename()
path  = "Vem_kan_segla.musicxml"
piece = converter.parse("Vem_kan_segla.musicxml")




upcoming = []

t = 0
midimax = 0
midimin = 9999
for e in piece.flat.notesAndRests:
    if e.isNote:
        #print(e.pitch.midi)
        midimax = max(midimax,e.pitch.midi)
        midimin = min(midimin,e.pitch.midi)
    setattr(e,"time",t)
    setattr(e,"passed",0)
    setattr(e,"hits",0)
    setattr(e,"misses",0)
    t += e.seconds
    upcoming.append(e)

midirange = midimax-midimin+1

time  = 0
dTime = 12

class Pitch():
    def __init__(self, time, freq):
        self.time = time
        self.freq = freq

class RollCanvas(Canvas):
    def __init__(self,midimin,midimax,dTime=10, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.midimin   = midimin
        self.midimax   = midimax
        self.midirange = midimax-midimin+1
        self.freqmin   = self.midi2freq(midimin)/(2**(1/24))
        self.freqmax   = self.midi2freq(midimax)*(2**(1/24))
        self.freqrange = self.freqmax-self.freqmin
        self.dTime = dTime

    def w(self):
        return self.winfo_width()

    def h(self):
        return self.winfo_height()

    def time2px(self,time, cTime):
        return (time-cTime)/self.dTime*self.w() + self.w()

    def midi2px(self,midi):
        return self.h()-(midi-self.midimin)*self.h()/self.midirange

    def freq2px(self,freq):
        pass

    def midi2freq(self,midi):
        a = 440 #frequency of A (coomon value is 440Hz)
        return (a / 32) * (2 ** ((midi - 9) / 12))

    def drawLines(self, nPitches):
        w = self.winfo_width()
        h = self.winfo_height()
        for i in range(1,nPitches):
            y = h/nPitches*i
            self.create_line(0,y,w,y,fill="#555555")
        self.create_line(w/2,0,w/2,h,fill="white")

    def drawNote(self,note,cTime):
        x0 = self.time2px(note.time,cTime)
        x1 = self.time2px(note.time+note.seconds,cTime)
        y0 = self.midi2px(note.pitch.midi)
        y1 = y0 - self.h()/self.midirange
        if note.time < time:
            color = "red"
        else:
            color = "grey"
        self.create_rectangle(x0, y0, x1, y1, fill=color)

    def drawPitch(self,pitch):
        w = self.winfo_width()
        h = self.winfo_height()


master = Tk()
master.title("StarSingers")

wRef   = 100
wCan   = 900
hNotes = 250
hRoll  = 350

notesFrame = Frame(master)
notesFrame.pack()

rollFrame  = Frame(master)
rollFrame.pack()

notesReference = Canvas(notesFrame, width=wRef,height=hNotes)
notesReference.grid(row=0,column=0)

notesCanvas = Canvas(notesFrame, width=wCan,height=hNotes)
notesCanvas.grid(row=0,column=1)

rollReference = Canvas(rollFrame, width=wRef,height=hRoll,bg="black")
rollReference.grid(row=0,column=0)

rollCanvas = RollCanvas(midimin,midimax,10,rollFrame, width=wCan,height=hRoll,bg="black")
rollCanvas.grid(row=0,column=1)

master.update()

rollCanvas.drawLines(midirange)

def drawUpcoming():
    for e in upcoming:
        if e.isNote:
            rollCanvas.drawNote(e,time)

looplen = 50; # length of loop in milliseconds

def loop():
    global time
    time += looplen/1000
    rollCanvas.delete("all")
    rollCanvas.drawLines(midirange)
    drawUpcoming()
    master.after(looplen,loop)

master.after(looplen,loop)
master.mainloop()