TARGET = sound_ch1.exe
SRCS = main.sh

all: $(TARGET)

$(TARGET): $(SRCS)
	./main.sh >$@

clean:
	rm -f *~ *.o map.sh asm.lst $(TARGET)

.PHONY: clean
