# Microwatt Tests

To run these you need icarus verilog, a riscv toolchain and a ppc64le
toolchain. On Fedora these are available as packages:

```
sudo dnf install iverilog gcc-riscv64-linux-gnu gcc-powerpc64le-linux-gnu
```

And on Ubuntu:

```
sudo apt install iverilog gcc-riscv64-linux-gnu gcc-powerpc64le-linux-gnu
```

The test cases need a path to the PDK, eg:

```
make PDK_PATH=/home/anton/pdk/sky130A
```

## minimal
This is probably where you should start. This is a minimal test that verifies
that Microwatt is running. The SPI flash controller is lightly tested because
Microwatt uses it to fetch instructions for the test case. The logic analyzer
is also lightly tested because Microwatt uses that to signal back to the
management engine that it is alive.

## uart
This tests the management engine handing over the TX and RX I/O pins to
Microwatt, and Microwatt receiving a character and echoing it back.

## logic_analyzer
Microwatt has 32 LA inputs and 32 LA outputs hooked up.  This tests that
functionality by ping ponging an LFSR sequence between the management engine
and Microwatt. Each value in the sequence is checked before emitting the next
one.

## spi_flash
Before starting flash is initialized with a hash of the offset. The test case
then does reads at various offsets and checks if the values returned are
correct.

## memory_test
A simple memory tester. Writes hashes of the offset of memory into memory,
then reads them back.
