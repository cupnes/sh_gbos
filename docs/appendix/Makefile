NAME = appendix
TARGET = $(NAME).txt
SRC = $(NAME).orig
OBJ = $(NAME).o
TMP = $(NAME).t.o

all: $(TARGET)

$(TARGET): $(OBJ)
	../../tools/conv_char_code $< $@

# ファイル末尾の改行を削除する
$(OBJ): $(SRC)
	tr '\n' '#' <$< >$(TMP)
	sed -i -r 's/^(.*[^#])#+$$/\1/' $(TMP)
	tr '#' '\012' <$(TMP) >$@

clean:
	rm -f *~ *.o $(TARGET)

.PHONY: clean
