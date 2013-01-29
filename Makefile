SRC = $(shell find src -name '*.coffee')
LIB = $(SRC:src/%.coffee=lib/%.js)

all: lib

run: all
	@./bin/songlocator

lib: $(LIB)
watch:
	coffee -bc --watch .

lib/%.js: src/%.coffee
	@echo `date "+%H:%M:%S"` - compiled $<
	@mkdir -p $(@D)
	@coffee -bcp $< > $@

clean:
	rm -rf $(LIB)
