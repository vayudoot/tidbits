TARGETS=hello
ENTRY_POINT=main
ASM_FLAGS=-f macho64
LINK_FLAGS=-macosx_version_min 10.6 -e $(ENTRY_POINT)


all: $(TARGETS)

run: all
	./hello

r: run


%: %.o
	ld $(LINK_FLAGS) -o $@ $<

%.o: %.asm
	nasm $(ASM_FLAGS) -o $@ $<

clean:
	rm -f $(TARGETS) *.o

