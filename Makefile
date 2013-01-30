SRC = $(shell find src -name '*.coffee')
LIB = $(SRC:src/%.coffee=lib/%.js)
AMD = $(LIB:%.js=%.amd.js)

all: lib amd

run: all
	@./bin/songlocator

lib: $(LIB)
amd: lib $(AMD)

watch:
	coffee -bc --watch .

lib/%.js: src/%.coffee
	@echo `date "+%H:%M:%S"` - compiled $<
	@mkdir -p $(@D)
	@coffee -bcp $< > $@

%.amd.js: %.js
	@echo `date "+%H:%M:%S"` - AMD compiled $<
	@echo 'define(function(require, exports, module) {' > $@
	@cat $< >> $@
	@echo '});' >> $@

clean:
	rm -rf $(LIB) $(AMD)
