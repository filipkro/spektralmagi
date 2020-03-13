from music21 import *
piece = converter.parse("Vem_kan_segla.musicxml")

#print(piece.flat.tempo)

#for e in piece.flat.elements:
    #print(e)

#print(piece.flat.getElementsByClass(meter.TimeSignature)[0].numerator)

for i in range(40, 60, True):
    p = pitch.Pitch()
    p.midi = i
    print(p.nameWithOctave)