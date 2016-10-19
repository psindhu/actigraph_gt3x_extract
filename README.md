#Extract accelerometer and metadata from GT3X files. 
Adapted from https://github.com/informaton/padaco 

Python has no apparant way of unpacking a 12bit float so to do that Matlab is used. However, Matlab for some reason unpacks the timestamps incorrectly so here Python is used. To get all data you need to run matlab/gt3x_to_csv.m and python/unpack_gt3x.py. 
