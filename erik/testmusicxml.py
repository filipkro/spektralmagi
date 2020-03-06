from music21 import *

piece = converter.parse("Vem_kan_segla.mxl")
# print(piece.notes)

# for e in dir(piece.flat):
#     print(e)

t = 0
for note in piece.flat.notesAndRests:
    tStart = t
    t+=note.seconds
    tEnd   = t
    if note.isNote:
        print("t: \t%1.2f - %1.2f \t f: %1.2f" %(tStart, tEnd, note.pitch.freq440))
    else:
        print("t: \t%1.2f - %1.2f \t -" %(tStart, tEnd))


