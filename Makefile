## This is curate; for my Photos and maybe other arc files

## This section is for Dushoff-style vim-setup and vim targeting
## You can delete it if you don't want it
current: target
-include target.mk
Ignore = target.mk

vim_session:
	bash -cl "vmt"

## -include makestuff/perl.def

######################################################################

key = $(wildcard /media/*/*/Photos)

down:
	rsync -a --update --progress --itemize-changes Photos/ $(key)/

up:
	rsync -a --update --progress --itemize-changes $(key)/ Photos/

out:
	sudo umount $(dir $(key))

## ln -s ~/Dropbox/Photos . ##
Ignore += Photos

Ignore += album

######################################################################

mirrors += files

### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

## ln -s ../makestuff . ## Do this first if you want a linked makestuff
Makefile: makestuff/00.stamp
makestuff/%.stamp: | makestuff
	- $(RM) makestuff/*.stamp
	cd makestuff && $(MAKE) pull
	touch $@
makestuff:
	git clone --depth 1 $(msrepo)/makestuff

-include makestuff/os.mk

-include makestuff/mirror.mk

-include makestuff/git.mk
-include makestuff/visual.mk
