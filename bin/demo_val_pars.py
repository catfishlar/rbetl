#!/usr/bin/python

import sys
import re
import os

if len(sys.argv) < 2:
    print "Usage: " + sys.argv[0] + " <demographic values table dump file>"
    sys.exit(2)


overall = {}
f = open(sys.argv[1])
try:
    insert_statement = re.compile(r"INSERT INTO `Demographic_Values_Table` VALUES")
    row_pattern = re.compile(r"\(('(\w+)',(\w+),'((?:[^'\\]|\\.)*)',(\w*),(\w*),'([^']*)')\)")

    for line in f:
        if insert_statement.match(line):
            rows = row_pattern.findall(line)
            for row in rows:
                group = overall.setdefault(row[2],[])
                group.append(row[0])
except:
    print "ERROR: Failed to load file " + sys.argv[0] + " error in part 1: safe to rerun"
    raise
finally:
    f.close()

try:
    os.stat('did')
except:
    os.mkdir('did')

for key in overall:
    dir = "did/"+str(int(key)/1000)+'/'
    try:
        os.stat(dir)
    except:
        os.mkdir(dir)
    f = open(dir+key+".csv",'a')
    try:
        for row in overall[key]:
            f.write(row+'\n')
    except:
        print "ERROR: Failed to load file " + sys.argv[0] + " error in part 2: not safe to rerun. died on key " + key
        raise
    finally:
        f.close()

