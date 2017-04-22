DIRS = $(basename $(wildcard */))

.PHONY: all test clean $(DIRS)

all: ACTION = all
all: $(DIRS)

test: ACTION = test
test: $(DIRS)

clean: ACTION = clean
clean: $(DIRS)

$(DIRS):
	$(MAKE) $(ACTION) -C $@
