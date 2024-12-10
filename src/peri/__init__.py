import time
import os
import fileinput
import sys
from threading import Thread

import IOBluetooth
from PyObjCTools import AppHelper
from Foundation import NSObject
from PIL import Image, ImageOps, ImageEnhance
from tqdm import tqdm

debug = False

def log(*s):
    if not debug:
        return

    print(*s)

def ui(*s):
    print(*s)

class Delegate(NSObject):
    def rfcommChannelData_data_length_(self, chan, data, length):
        log("received", length, data)
        self.printer.received = data

    def rfcommChannelOpenComplete_status_(self, chan, status):
        log("status", status)

    def rfcommChannelClosed_(self, chan):
        log("closed")

    def rfcommChannelWriteComplete_refcon_status_bytesWritten_(self, chan, ref,
                                                               status, length):
        log("did write", length, status)

class PeriPage:
    def __init__(self, address, delegate):
        self.delegate = delegate
        self.delegate.printer = self
        self.received = None

        ui("connecting...")
        self.dev = IOBluetooth.IOBluetoothDevice.deviceWithAddressString_("c8:47:8c:00:d9:89")
        log(self.dev.openConnection())
        log(self.dev.isConnected())

        result, self.chan = self.dev.openRFCOMMChannelSync_withChannelID_delegate_(
                None,
                1,
                self.delegate,
                )

        self.reset()

    def wait(self, t = 0.02):
        log("waiting", t)
        time.sleep(t)

    def send(self, data):
        return self.write(data)

    def write(self, data):
        log("will write", data)
        if self.chan.writeSync_length_(data, len(data)) != 0:
            raise Exception("write failed")

    def recv(self, text = ""):
        log("receiving")

        while self.received is None:
            self.wait()

        log("received " + text, len(self.received))

        result = self.received
        self.received = None
        return result

    def reset(self):
        ui("resetting...")
        self.wait(0.2)
        cmd = bytes.fromhex("10ff50f1")
        self.write(cmd)
        data = self.recv("reset")

    def printImage(self, img):
        img = img.convert("L")

        img_width = img.size[0]
        img_height = img.size[1]

        # brightness / contrast
        img = ImageOps.invert(img)

        new_width = 384 #Peripage A6 image width
        scale = new_width / float(img_width)
        new_height = int(img_height * scale)

        log ("Source image dimensions: ", img_width, img_height)
        log ("Printing image dimensions:", new_width, new_height)

        if (new_height>65535):
            log ("Target image height is too large. Can't print this (yet)")
            sys.exit(1)

        img = img.resize((384, new_height), Image.LANCZOS)

        img = img.convert("1")
        # write chunks of 122 bytes to printer
        cmd = bytes.fromhex("10fffe01")
        self.send(cmd)
        chunksize = 122
        self.send(bytes.fromhex("000000000000000000000000"))
        height_bytes=(new_height).to_bytes(2, byteorder="little")
        cmd = bytes.fromhex("1d7630003000")+height_bytes
        self.send(cmd)

        # send image to printer
        image_bytes = img.tobytes()

        log("Printing %d chunks" % (len(image_bytes)/chunksize))
        log()
        for i in tqdm(range(0, len(image_bytes), chunksize)):
            chunk = image_bytes[i:i + chunksize]
            self.send(chunk)
            self.wait()

        self.feed()
        self.end()

    def feed(self):
        log("Feeding...")
        emptyLine=[0 for i in range(1,122)];
        for i in range(1,35):
            self.send(bytes(emptyLine))
            self.wait()

    def end(self):
        self.send(bytes.fromhex("1b4a4010fffe45"))
        log("Printing complete")

    def printString(self, outputString):
        self.reset()
        ui("sending...")

        if len(outputString) < 32:
            outputString = outputString + (" " * (34 - len(outputString)))

        cmd = bytes.fromhex("10fffe01")
        self.send(cmd)
        line = bytes(outputString, "ascii")
        self.send(line)
        self.end()

    def printFrom(self, stream):
        self.reset()
        ui("sending...")

        cmd = bytes.fromhex("10fffe01")
        self.send(cmd)

        line = stream.readline()

        while line:
            self.wait()
            line = bytes(line, "ascii")
            self.send(line)

            line = stream.readline()

        self.end()

    def getDeviceName(self):
        cmd = bytes.fromhex("10ff3011")
        self.send(cmd)
        data = self.recv("device name")
        return str(data)

    def getFWDPI(self):
        cmd = bytes.fromhex("10ff20f1")
        self.send(cmd)
        data = self.recv("fwdpi")
        return str(data)

    def getSerial(self):
        cmd = bytes.fromhex("10ff20f2")
        self.send(cmd)
        data = self.recv("serial")
        return str(data)

def loadImageFromFileName(filename):
    # Load Image and process it
    img = Image.open(filename)
    return img

class PrinterThread(Thread):
    def run(self):
        try:
            printer = PeriPage("c8:47:8c:00:d9:89", Delegate.new())

            ui("Serial: " + printer.getSerial())
            ui("FWDIP: " + printer.getFWDPI())
            ui("Name: " + printer.getDeviceName())

            # printer.printFrom(sys.stdin)

            for file in sys.argv[1:]:
                printer.printImage(loadImageFromFileName(file))
        except Exception as e:
            print(e)
        finally:
            os._exit(0)

t = PrinterThread()
t.start()
AppHelper.runConsoleEventLoop()
