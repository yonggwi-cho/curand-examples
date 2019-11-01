#!/usr/bin/env python

import os
import sys
import matplotlib.pyplot as plt
import argparse as ae
import math

ierr = os.system("./test > output ")

if ierr == 1 :
    print("failed ./test execution.")
    sys.exit(1)
# read file
f = open("output","r")
data = f.readlines()
for i in range(len(data)):
    data[i] = float(data[i])
f.close()

# plot
plt.hist(data,bins=100)
plt.show()

# remove cache
os.system("rm -f output")
