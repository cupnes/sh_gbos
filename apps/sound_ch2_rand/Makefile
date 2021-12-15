TARGET = sound_ch2_rand.exe
SRCS = main.sh

all: $(TARGET)

$(TARGET): $(SRCS)
	./main.sh >$@

clean:
	rm -f *~ *.o map.sh asm.lst $(TARGET)

.PHONY: clean
