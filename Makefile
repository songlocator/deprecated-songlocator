SRC = $(shell find src -name '*.coffee')
LIB = $(SRC:src/%.coffee=lib/%.js)
AMD = $(LIB:lib/%.js=lib/amd/%.js)

all: lib amd

lib: $(LIB)
amd: lib $(AMD)

watch:
	watch -n 1 $(MAKE) all

lib/%.js: src/%.coffee
	@echo `date "+%H:%M:%S"` - compiled $<
	@mkdir -p $(@D)
	@coffee -bcp $< > $@

lib/amd/%.js: lib/%.js
	@echo `date "+%H:%M:%S"` - AMD compiled $<
	@mkdir -p $(@D)
	@echo 'define(function(require, exports, module) {' > $@
	@cat $< >> $@
	@echo '});' >> $@

clean:
	rm -rf $(LIB) $(AMD)
