from   mido import MidiFile
import pyqtgraph as pg


midi = MidiFile("Vem_kan_segla.mid")

for msg in midi:
    print(msg)

notes = []
times = []

for msg in midi:
    if msg.type == "note_on" & msg.velocity == 0:
        print("Length: " + str(msg.time) + ", Note: " + str(msg.note))

