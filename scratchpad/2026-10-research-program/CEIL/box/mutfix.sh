#!/bin/bash
# box: mutfix.sh — after mut3.py's DONE, rerun M10b with the corrected sed
until grep -q DONE /w/raw/mut/table.txt; do sleep 20; done
python3 /w/box/mut3fix.py
