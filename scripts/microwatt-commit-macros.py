#!/usr/bin/env python3

import os
import sys
import subprocess

compress_size = 100*1000*1000
gzip_compress_cmd = [ 'gzip', '-9', '-f' ]
gzip_uncompress_cmd = [ 'gzip', '-d', '-f' ]

macros = [ 'RAM_512x64',
           'dcache',
           'icache',
           'multiply_4',
           'register_file'
]

# Directories and extensions
dirs = [ ('def', 'def'),
         ('gds', 'gds'),
         ('lef', 'lef'),
         ('mag', 'mag'),
         ('maglef', 'mag'),
         ('spi/lvs', 'spice'),
         ('verilog/gl', 'v')
]

# Check all the files exist
for (dir, ext) in dirs:
    for macro in macros:
        fname = '%s/%s.%s' % (dir, macro, ext)
        try:
            s = os.stat(fname)
        except:
            print("%s doesn't exist" % fname)
            sys.exit(1)


add_files = list()
rm_files = list()

for (dir, ext) in dirs:
    for macro in macros:
        fname = '%s/%s.%s' % (dir, macro, ext)
        sz = os.stat(fname).st_size
        if sz > compress_size or 'gds' in dir:
            cmd = gzip_compress_cmd.copy()
            cmd.append(fname)
            print(cmd)
            subprocess.check_call(cmd)

            rm_files.append(fname)
            add_files.append(fname + '.gz')
        else:
            rm_files.append(fname + '.gz')
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

cmd = [ 'git', 'commit', '-m', 'Build macros' ]
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
