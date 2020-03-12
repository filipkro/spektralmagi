# -*- coding: utf-8 -*-
from pyqtgraph.Qt import QtGui, QtCore
import numpy as np
from numpy import arange, sin, cos, pi
import pyqtgraph as pg
import sys

class Plot2D():
    def __init__(self):
        self.traces = dict()
        # self.plot = pg.PlotWidget()

        #QtGui.QApplication.setGraphicsSystem('raster')
        self.app = QtGui.QApplication([])
        # #mw = QtGui.QMainWindow()
        # #mw.resize(800,800)
        #
        self.win = pg.GraphicsWindow(title="Basic plotting examples")
        self.win.resize(1000,600)
        self.win.setWindowTitle('pyqtgraph example: Plotting')

        # Enable antialiasing for prettier plots
        pg.setConfigOptions(antialias=True)

        # self.canvas = self.win.addPlot(title="Pytelemetry")
        self.s = pg.ScatterPlotItem()


    def start(self):
        if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
            QtGui.QApplication.instance().exec_()

    def trace(self,name,dataset_x,dataset_y,symb):
        self.s.addPoints(dataset_x, dataset_y, symbol=symb)


## Start Qt event loop unless running in interactive mode or using pyside.
if __name__ == '__main__':
    p = Plot2D()
    i = 0
    symb = QtGui.QPainterPath()
    symb.addRect(0,0,3,1)

    def update():
        global p, i, symb
        t = np.arange(0,3.0,0.01)
        si = sin(2 * pi * t + i)
        c = cos(2 * pi * t + i)
        p.trace("sin",t,si,symb)
        # p.trace("cos",t,c)
        i += 0.1

    timer = QtCore.QTimer()
    timer.timeout.connect(update)
    timer.start(50)

    p.start()
