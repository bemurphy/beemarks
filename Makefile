MKDIR_P = mkdir -p
ALL     = all
APP     = app
HASH    = openssl sha1 | cut -c1-8

STATIC_DIR = public
SUB_DIR    = compiled
CSS_DIR    = $(STATIC_DIR)/css
JS_DIR     = $(STATIC_DIR)/js
DIST       = $(STATIC_DIR)/$(SUB_DIR)

.PHONY : clean all watch

all: directories compile_assets css_lint signature_assets

directories: ${DIST}

${DIST}:
	${MKDIR_P} ${DIST}

clean:
	rm -f $(DIST)/*.css
	rm -f $(DIST)/*.js

watch:
	fswatch -1 $(CSS_DIR)/*.css $(JS_DIR)/*.js
	make clean && make all && make watch

compile_assets: $(DIST)/$(ALL).css $(DIST)/$(ALL).js

$(DIST)/$(ALL).css:
	cpp -P $(CSS_DIR)/$(APP).css > $(DIST)/$(ALL).css

$(DIST)/$(ALL).js:
	cpp -P $(JS_DIR)/$(APP).js > $(DIST)/$(ALL).js

css_lint:
	@csslint --quiet $(DIST)

signature_assets:
	$(eval CSS_DIGEST = `cat $(DIST)/$(ALL).css | $(HASH)`)
	$(eval CSS_DIGEST_FILE = $(ALL)-$(CSS_DIGEST).css)
	cat $(DIST)/$(ALL).css | yuicompressor --type css >> $(DIST)/$(CSS_DIGEST_FILE)

	$(eval JS_DIGEST = `cat $(DIST)/$(ALL).js | $(HASH)`)
	$(eval JS_DIGEST_FILE = $(ALL)-$(JS_DIGEST).js)
	cat $(DIST)/$(ALL).js | uglifyjs > $(DIST)/$(JS_DIGEST_FILE)

	$(eval MANIFEST = "{\n  \"$(ALL).css\": \"/$(SUB_DIR)/$(CSS_DIGEST_FILE)\",\n  \"$(ALL).js\": \"/$(SUB_DIR)/$(JS_DIGEST_FILE)\"\n}")

	rm -f assets.json
	@echo $(MANIFEST) > assets.json

