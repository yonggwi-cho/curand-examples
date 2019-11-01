#!/usr/bin/env python

import sys
import matplotlib.pyplot as plt
import argparse as ae
import math

parser=ae.ArgumentParser()
parser.add_argument("-f","--file",type=str,required=True)
args = parser.parse_args()

# read file
f = open(args.file,"r")
data = f.readlines()
for i in range(len(data)):
    data[i] = float(data[i])
f.close()

# plot
plt.hist(data,bins=100)
plt.show()
