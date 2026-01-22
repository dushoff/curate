## This is curate; for my Photos and maybe other arc files

## This section is for Dushoff-style vim-setup and vim targeting
## You can delete it if you don't want it
current: target
-include target.mk
Ignore = target.mk

vim_session:
	bash -cl "vmt notes.md"

-include makestuff/perl.def

######################################################################

Sources += notes.md

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

Sources += $(wildcard slow/*)
mirrors += files

Ignore += *.out
examine.out: files/list.tsv examine.pl
	$(PUSH)

album: link.out ;
link.out: slow/Photos.files.tsv link.pl
	$(PUSH)

slides: | album
	feh -FzZrD 3 album/

Ignore += reels
reels: mlink.out ;
mlink.out: slow/Photos.files.tsv mlink.pl
	$(PUSH)

documentary:
	mplayer -fs reels/**/*.* 

######################################################################

## Movie pipelines NOt really working
theatre: | Photos
	mpv --shuffle --recursive $|

studio: | Photos
	vlc --random --playlist-autostart $|

Sources += $(wildcard *.py)
Ignore += *.files.tsv
slowtarget/%.files.tsv: filetree.py %
	python $< $* > $@

######################################################################

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
-include makestuff/slowtarget.mk

-include makestuff/git.mk
-include makestuff/visual.mk
