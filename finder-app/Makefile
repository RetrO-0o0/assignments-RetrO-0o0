CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Werror

TARGET = writer
SRC = writer.c
OBJ = writer.o

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(TARGET)

$(OBJ): $(SRC)
	$(CC) $(CFLAGS) -c $(SRC) -o $(OBJ)

clean:
	rm -f $(TARGET) *.o