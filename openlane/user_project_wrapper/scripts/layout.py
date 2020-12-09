#!/usr/bin/python3

import re
import os

X=0
Y=1

# Wrapper size
die_size   = (2920, 3520)

r = re.compile('SIZE ([0-9\.]+) BY ([0-9\.]+) ;')

def get_macro_size(name):
    lef_file = os.path.dirname(os.path.abspath(__file__)) + '/../../../lef/' + name + '.lef'
    with open(lef_file) as f:
        for line in f:
            m = r.search(line)
            if m:
                lx = float(m.group(1))
                ly = float(m.group(2))
                return (lx, ly)


# Macro sizes
#ram        = (2800,  550)
#icache     = ( 660,  660)
#dcache     = ( 720,  720)
#multiply_4 = ( 800,  800)
#regfile    = (1000, 1000)
ram = get_macro_size('RAM_512x64')
icache = get_macro_size('icache')
dcache = get_macro_size('dcache')
multiply_4 = get_macro_size('multiply_4')
regfile = get_macro_size('register_file')

horizontal_margin = 16
vertical_margin   = 100

# Macro layout

# RAM at top
ram_l    =     (horizontal_margin,                        die_size[Y]-ram[Y]-vertical_margin)

# Caches in the middle
icache_l     = (horizontal_margin,                        die_size[Y]-icache[Y]-1100)
dcache_l     = (die_size[X]-dcache[X]-horizontal_margin,  die_size[Y]-dcache[Y]-1050)

# Multiply and regfile at bottom
multiply_4_l = (horizontal_margin,                        vertical_margin)
regfile_l    = (die_size[X]-regfile[X]-horizontal_margin, vertical_margin)

print('microwatt_0.soc0.bram.bram0.ram_0.memory_0       %8.3f %8.3f N' % ram_l)
print('microwatt_0.soc0.processor.icache_0              %8.3f %8.3f N' % icache_l)
print('microwatt_0.soc0.processor.dcache_0              %8.3f %8.3f N' % dcache_l)
print('microwatt_0.soc0.processor.execute1_0.multiply_0 %8.3f %8.3f N' % multiply_4_l)
print('microwatt_0.soc0.processor.register_file_0       %8.3f %8.3f N' % regfile_l)

def print_obs(sz, base, last=False):
    sep = ''
    if not last:
        sep = ', '
    print('met5 %.3f %.3f %.3f %.3f, ' % (base[X], base[Y], base[X]+sz[X], base[Y]+sz[Y]), end='')
    print('met4 %.3f %.3f %.3f %.3f%s' % (base[X], base[Y], base[X]+sz[X], base[Y]+sz[Y], sep), end='')

print()
print('set ::env(GLB_RT_OBS) "', end='')
print_obs(ram, ram_l)
print_obs(icache, icache_l)
print_obs(dcache, dcache_l)
print_obs(multiply_4, multiply_4_l)
print_obs(regfile, regfile_l, last=True)
print('"')
