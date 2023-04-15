PROJECT := ledger
VERSION := 3.3.2
LOCALE  := en

# TODO: Replace relative path (../src) with absolute path based on Makefile
SRCS    := $(wildcard ../src/*.h ../src/*.cc)
POS     := $(wildcard *.po)
MOS     := $(patsubst %.mo,locale/%/LC_MESSAGES/$(PROJECT).mo, $(POS:.po=.mo))

new: extract init format
	echo Edit $(LOCALE).po and rerun make format

update: extract merge format
	echo Edit $(LOCALE).po and rerun make format

# Extract strings from sources
$(PROJECT).pot: $(SRCS)
	xgettext \
		--default-domain $(basename $@) \
		--package-name $(basename $@) \
		--package-version $(VERSION) \
		--copyright-holder="John Wiegley" \
		--msgid-bugs-address=ledgercli@googlegroups.com \
		--keyword='_' \
		--keyword='_f' \
		--keyword='_n:1,2' \
		--keyword='_fn:1,2' \
		--keyword='proper_name:1,"This is a proper name. See the gettext manual, section Names."' \
		--add-comments=TRANSLATORS \
		--c++ \
		--boost \
		--no-wrap \
		--sort-by-file \
		--output $@ \
		$(SRCS) \
		# xgettext
		#--directory ../src \

# Merge existing translation file with updated extracted strings
merge: $(LOCALE).po
%.po: $(PROJECT).pot
	if [ -s "$@" ] ; then msgmerge $@ $< --output-file $@; \
	else msginit --no-translator --locale $(basename $@) --input $< --output-file $@; fi \
	# if msgmerge else msgini

# Create distribution .mo file
format: $(MOS)
locale/%/LC_MESSAGES/$(PROJECT).mo : %.po
	mkdir -p $(dir $@)
	msgfmt --check --verbose --output-file $@ $<
