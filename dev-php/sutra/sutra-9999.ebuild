# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit git-2 depend.php

EAPI=4

DESCRIPTION="An extension upon Flourish."
HOMEPAGE="http://www.poluza.com/"
EGIT_REPO_URI="git://github.com/tatsh/sutra.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="site"

DEPEND=""
RDEPEND=">=dev-lang/php-5.2.3
				 dev-php/flourish[sutra-patches]
				 dev-php/moor[sutra-patches]"

src_prepare() {
	mkdir sutra
	
	if use site ; then
		cp -R classes model routers sutra
		mv site htdocs
	else
		cp -R classes/*.php sutra
	fi
}

src_install() {
	insinto /usr/share/php
	doins -r sutra
	
	if use site ; then
		insinto /usr/share/webapps/sutra/${PV}
		doins -r htdocs
	fi
	
	einfo "To begin a site, copy /usr/share/webapps/${PV}/htdocs to where your site roots are."
}
