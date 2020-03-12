import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import multiprocessing as mp
import time
import pyaudio


# global variables
fig = plt.figure(1)
# first sub-plot
ax1 = fig.add_subplot(211)
line1, = ax1.plot([], [], lw=2)
ax1.grid()
xdata1, ydata1 = [], []
# second sub-plot
ax2 = fig.add_subplot(212)
line2, = ax2.plot([], [], lw=2)
ax2.grid()
xdata2, ydata2 = [], []

# the multiprocessing queue
q = mp.Queue()

FORMAT = pyaudio.paInt16
nbr_chunks = 4
CHANNELS = 1
RATE = 44100
# self.CHUNK = int(loop*self.RATE)
CHUNK = nbr_chunks*2048

p = pyaudio.PyAudio()
stream = p.open(
    format=FORMAT,
    channels=CHANNELS,
    rate=RATE,
    input=True,
    output=True,
    stream_callback=audio_callback,
    frames_per_buffer=CHUNK
)

# data generator in separate process
# here would be your arduino data reader
def dataGen(output):
    data = np.frombuffer(stream.read(CHUNK,exception_on_overflow=False), dtype=np.int16)
    output.put((x, np.sin(x)))

def audio_callback(self, in_data, frame_count, time_info, status):
    data = np.frombuffer(in_data,dtype=np.int16)
    

# update first subplot
def update1(data):
    # update the data
    t, y = data
    xdata1.append(t)
    ydata1.append(y)
    xmin, xmax = ax1.get_xlim()
    ymin, ymax = ax1.get_ylim()

    if t >= xmax:
        ax1.set_xlim(xmin, 2*xmax)
    if y >= ymax:
        ax1.set_ylim(ymin, 2*ymax)
    if y <= ymin:
        ax1.set_ylim(2*ymin, ymax)
    line1.set_data(xdata1, ydata1)

    return line1,

# update second subplot
def update2(data):
    # update the data
    t, y = data
    xdata2.append(t)
    ydata2.append(y)
    xmin, xmax = ax2.get_xlim()
    ymin, ymax = ax2.get_ylim()

    if t >= xmax:
        ax2.set_xlim(xmin, 2*xmax)
    if y >= ymax:
        ax2.set_ylim(ymin, 2*ymax)
    if y <= ymin:
        ax2.set_ylim(2*ymin, ymax)
    line2.set_data(xdata2, ydata2)

    return line2,

# called at each drawing frame
def run(data):
    # get data from queue, which is filled in separate process, blocks until
    # data is available
    data = q.get(block=True, timeout=.5)
    # put here your variable separation
    data1 = (2*data[0], 3*data[1])
    data2 = (data[0], data[1])
    #provide the data to the plots
    a = update1(data1)
    b = update2(data2)
    fig.canvas.draw()
    return a+b

if __name__ == "__main__":
    # count of reader processes
    n_proc = 1
    # setup workers
    pool = [mp.Process(target=dataGen, args=(q,)) for x in range(n_proc)]
    for p in pool:
        p.daemon = True
        p.start()

    # wait a few sec for the process to become alive
    time.sleep(3)

    # start your drawing
    ani = animation.FuncAnimation(fig, run, frames=60, blit=True, interval=10,
                                  repeat=False)
    plt.show()

    print('done')
