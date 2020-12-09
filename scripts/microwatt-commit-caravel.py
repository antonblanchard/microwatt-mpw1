#!/usr/bin/env python3

import os
import sys
import subprocess

compress_size = 100*1000*1000
gzip_compress_size_max = 200*1000*1000
gzip_compress_cmd = [ 'gzip', '-9', '-f' ]
xz_compress_cmd = [ 'xz', '-9', '-f' ]
gzip_uncompress_cmd = [ 'gzip', '-d', '-f' ]
xz_uncompress_cmd = [ 'xz', '-d', '-f' ]

files = [ "def/user_project_wrapper.def",
          "gds/user_project_wrapper.gds",
          "lef/user_project_wrapper.lef",
          "mag/user_project_wrapper.mag",
          "maglef/user_project_wrapper.mag",
          "spi/lvs/user_project_wrapper.spice",
          "verilog/gl/user_project_wrapper.v",
          "gds/caravel.gds"
]

# Check all the files exist
for fname in files:
    try:
        s = os.stat(fname)
    except:
        print("%s doesn't exist" % fname)
        sys.exit(1)


add_files = list()
rm_files = list()

for fname in files:
    sz = os.stat(fname).st_size
    if sz > gzip_compress_size_max:
        cmd = xz_compress_cmd.copy()
        cmd.append(fname)
        print(cmd)
        subprocess.check_call(cmd)

        rm_files.append(fname)
        rm_files.append(fname + '.gz')
        add_files.append(fname + '.xz')
    elif sz > compress_size or 'gds' in fname:
        cmd = gzip_compress_cmd.copy()
        cmd.append(fname)
        print(cmd)
        subprocess.check_call(cmd)

        rm_files.append(fname)
        rm_files.append(fname + '.xz')
        add_files.append(fname + '.gz')
    else:
        rm_files.append(fname + '.gz')
        rm_files.append(fname + '.xz')
        add_files.append(fname)


checked_rm_files = list()
for f in rm_files:
    cmd = [ 'git', 'rm', f ]
    try:
        print(cmd)
        subprocess.check_call(cmd)
        checked_rm_files.append(f)
    except:
        pass


cmd = [ 'git', 'add' ]
cmd.extend(add_files)
print(cmd)
subprocess.check_call(cmd)

cmd = [ 'git', 'commit', '-m', 'Tape out' ]
cmd.extend(checked_rm_files)
cmd.extend(add_files)
print(cmd)
subprocess.check_call(cmd)

# Uncompress files now they've been checked in
for fname in add_files:
    if fname.endswith('.gz'):
        cmd = gzip_uncompress_cmd.copy()
        cmd.append(fname)
        print(cmd)
        subprocess.check_call(cmd)
    elif fname.endswith('.xz'):
        cmd = xz_uncompress_cmd.copy()
        cmd.append(fname)
        print(cmd)
        subprocess.check_call(cmd)
