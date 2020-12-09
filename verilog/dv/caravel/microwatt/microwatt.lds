MEMORY {
	FLASH(rx)	: ORIGIN = 0xf0000000, LENGTH = 0x400000	/* 4MB */
	RAM(xrw)	: ORIGIN = 0x00000000, LENGTH = 0x0400		/* 1024 kB */
}

SECTIONS
{
	. = 0xf0000000;
	_start = .;
	.text : {
		KEEP(*(.head))
		*(.text)
		*(.text.*)
		*(.sfpr)
		*(.eh_frame)
		*(.rodata)
		*(.rodata.*)
		. = ALIGN(8);
		_etext = .;		/* define a global symbol at end of code */
		_sidata = _etext;	/* This is used by the startup to initialize data */
 	} > FLASH

	.data : AT ( _sidata ) {
		. = ALIGN(8);
		_sdata = .;
		_ram_start = .;
		. = ALIGN(8);
		*(.data)
		*(.data*)
		*(.sdata)
		*(.sdata*)
		. = ALIGN(8);
		_edata = .;
	} > RAM

	.bss : {
		__bss_start = .;
		*(.dynsbss)
		*(.sbss)
		*(.scommon)
		*(.dynbss)
		*(.bss)
		*(.common)
		*(.bss.*)

		. = . + 0x300;
		__stack_top = .;

		. = ALIGN(0x80);
		__bss_end = .;
	} > RAM

	/DISCARD/ :
	{
		*(.note.gnu.build-id)
	}
}
