# Makefile for time_to_1st_request.c
# Compiles the C utility for measuring time to first HTTP request

CC = gcc
CFLAGS = -Wall -Wextra -Werror -O2 -std=c11
LDFLAGS = 
TARGET = time_to_1st_request
SRC = time_to_1st_request.c
OBJ = $(SRC:.c=.o)

# Default target
all: $(TARGET)

# Build the executable
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

# Clean build artifacts
clean:
	rm -f $(TARGET) $(OBJ)

# Run tests (basic compilation check)
test: $(TARGET)
	@echo "Testing compilation..."
	@./$(TARGET) 2>&1 | grep -q "Usage:" && echo "✓ Binary compiled successfully" || echo "✗ Test failed"
	@echo "Runt test using python server"
	@./$(TARGET) "python3 -m http.server 8080" /dev/null "http://127.0.0.1:8080"

# Help target
help:
	@echo "Makefile for time_to_1st_request"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build the time_to_1st_request binary (default)"
	@echo "  clean      - Remove build artifacts"
	@echo "  install    - Install binary to /usr/local/bin (requires sudo)"
	@echo "  uninstall  - Remove binary from /usr/local/bin (requires sudo)"
	@echo "  test       - Run basic tests"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Usage example:"
	@echo "  make"
	@echo "  ./time_to_1st_request \"java -jar app.jar\" /dev/null http://localhost:8080/health"

.PHONY: all clean test help