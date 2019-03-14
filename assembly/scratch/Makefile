TARGETS=off_by_0x100.o.disas off_by_0x100.x.gdbdisas off_by_1.o.disas off_by_1.x.gdbdisas
ENTRY_POINT=main
ASM_FLAGS=-f macho64
LINK_FLAGS=-macosx_version_min 10.6 -e $(ENTRY_POINT)
NASM=nasm


all: $(TARGETS)


%.disas: %
	otool -tv $< > $@

%.gdbdisas: %
	cat disas.gdb | gdb $< > $@

%.x: %.o
	ld $(LINK_FLAGS) -o $@ $<

%.o: %.asm
	$(NASM) $(ASM_FLAGS) -o $@ $<

clean:
	rm -f $(TARGETS) *.o

