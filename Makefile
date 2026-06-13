KEYS := pkgname pkgver pkgrel arch
$(foreach key,$(KEYS),\
	$(eval $(subst .,_,$(key)) := $(shell awk -F'[=:]' -v k="$(key)" '$$1 ~ "^[ \t]*"k"[ \t]*$$" {gsub(/^[ \t]+|[ \t]+$$/, "", $$2); gsub(/['"'"'()]/, "", $$2); print $$2; exit}' PKGBUILD))\
)
SRCFILE=$(pkgname)-$(pkgver).tar.gz
PKGFILE=$(pkgname)-$(pkgver)-$(pkgrel)-$(arch).pkg.tar.zst

.PHONY: all check build test install update publish clean distclean

all: check build test

check: PKGBUILD
	namcap PKGBUILD
	makepkg --geninteg
#	updpkgsums

build: PKGBUILD
	makepkg

$(PKGFILE):
	make build

test: $(PKGFILE)
	pacman -Qilp $(PKGFILE)
	namcap PKGBUILD $(PKGFILE)
#	pkgctl build

install: $(PKGFILE)
#	makepkg --syncdeps
#	makepkg --install
#	makepkg --rmdeps
#	makepkg --clean
	sudo pacman -U $(PKGFILE)

.nvchecker.toml:
	pkgctl version setup

update: .nvchecker.toml
	pkgctl version check
#	pkgctl version upgrade

.SRCINFO: PKGBUILD
	makepkg --printsrcinfo > .SRCINFO

publish: PKGBUILD .SRCINFO
	git add PKGBUILD .SRCINFO
	git commit --message "$(pkgname)-$(pkgver)"
	git push # --set-upstream origin main
#	gh pr create --draft

clean:
	-rm $(PKGFILE)
	-rm -rf pkg src

distclean:
	-rm $(SRCFILE)
	-rm .nvchecker.toml
	-rm .SRCINFO
