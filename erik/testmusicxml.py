from music21 import *
import numpy as np

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

# for note in notes:
#     print(note)

def notesTimeMap(times,notes):
    timeNotes = np.zeros(len(times))
    curTime   = 0
    for note in notes:
        while curTime < len(times) and time[curTime] < note[0]:
            curTime += 1
        while curTime < len(times) and time[curTime] < note[1]:
            timeNotes[curTime] = note[2]
            curTime += 1
    return timeNotes

time = np.linspace(-1,32,100)
n = notesTimeMap(time,notes)
