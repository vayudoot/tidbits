TARGETS=part1 part2 part3 part4
ENTRY_POINT=main
ASM_FLAGS=-f macho64
LINK_FLAGS=-macosx_version_min 10.6 -e $(ENTRY_POINT)


all: $(TARGETS)

run: all
	./part4

r: run


%: %.o
	ld $(LINK_FLAGS) -o $@ $<

%.o: %.asm
	nasm $(ASM_FLAGS) -o $@ $<

clean:
	rm -f $(TARGETS) *.o
