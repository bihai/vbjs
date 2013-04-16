LANGUAGE = ./node_modules/.bin/language
DOCTEST = ./node_modules/.bin/doctest
MOCHA = ./node_modules/.bin/mocha --compilers coffee:coffee-script -u tdd

all: expr.parser.js vb.parser.js

# TODO use `language -t` to stop repeating generated parser code
%.parser.js : %.language common.language
	@echo "/* Generated by language.js (see Makefile) */" > $@
	cat $< | ./preprocess | $(LANGUAGE) >> $@

# PEG.js reports errors better than language.js, let's run it before testing
test/%.peg.js: %.language common.language test/pegjs_build
	cat $< | ./preprocess | test/pegjs_build $<_preprocessed > $@

doctest:
	$(DOCTEST) test/vbobject.js

# run test/doctest.html in the browser
doctest-browse: test/vb-browser.js FORCE
	python -m webbrowser -t "http://localhost:8008/test/doctest.html"
	python -m SimpleHTTPServer 8008

test/vb-browser.js: vb.coffee *.parser.js
	./node_modules/.bin/browserbuild -g vb -m vb -b node_modules/underscore/,node_modules/escodegen/ $^ node_modules/underscore/underscore.js node_modules/escodegen/escodegen.js > $@

test: test/vb.peg.js vb.parser.js test/expr.peg.js expr.parser.js doctest
    # Usage:
    #     $ make test TEST="grep pattern"
    ifdef TEST
	env TESTING=1 $(MOCHA) -g "$(TEST)" test/*.coffee
    else
	env TESTING=1 $(MOCHA) test/*.coffee
    endif

.PHONY: test doctest FORCE
