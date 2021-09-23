# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9,10} )
PYTHON_REQ_USE="ncurses,readline"

inherit eutils flag-o-matic python-r1 xdg-utils

DESCRIPTION="Original Xbox emulator."
HOMEPAGE="https://xemu.app/ https://github.com/mborgerson/xemu"
SHA="d7e926fc6342a28b4441df306b525b1aac016fad"
IMGUI_SHA="e18abe3619cfa0eced163c027d0349506814816c"
IMPLOT_SHA="dea3387cdcc1d6a7ee3607f8a37a9dce8a85224f"
KEYCODEMAPDB_SHA="d21009b1c9f94b740ea66be8e48a1d8ad8124023"
SOFTFLOAT_SHA="b64af41c3276f97f0e181920400ee056b9c88037"
SLIRP_SHA="a88d9ace234a24ce1c17189642ef9104799425e0"
TESTFLOAT_SHA="5a59dcec19327396a011a17fd924aed4fec416b3"
XXHASH_SHA="f2c52f1236a50d754b07f584ce4592de1df8c0f7"
SRC_URI="https://github.com/mborgerson/xemu/archive/${SHA}.tar.gz -> ${P}.tar.gz
	https://gitlab.com/qemu-project/keycodemapdb/-/archive/${KEYCODEMAPDB_SHA}/keycodemapdb-${KEYCODEMAPDB_SHA}.tar.gz -> ${PN}-keycodemapdb-${KEYCODEMAPDB_SHA:0:7}.tar.gz
	https://github.com/ocornut/imgui/archive/${IMGUI_SHA}.tar.gz -> ${PN}-imgui-${IMGUI_SHA:0:7}.tar.gz
	https://github.com/epezent/implot/archive/${IMPLOT_SHA}.tar.gz -> ${PN}-implot-${IMPLOT_SHA:0:7}.tar.gz
	https://gitlab.com/qemu-project/berkeley-softfloat-3/-/archive/${SOFTFLOAT_SHA}/berkeley-softfloat-3-${SOFTFLOAT_SHA}.tar.gz -> ${PN}-softfloat-${SOFTFLOAT_SHA:0:7}.tar.gz
	https://gitlab.com/qemu-project/berkeley-testfloat-3/-/archive/${TESTFLOAT_SHA}/berkeley-testfloat-3-${TESTFLOAT_SHA}.tar.gz -> ${PN}-testfloat-${TESTFLOAT_SHA:0:7}.tar.gz
	https://github.com/Cyan4973/xxHash/archive/${XXHASH_SHA}.tar.gz -> ${PN}-xxhash-${XXHASH_SHA:0:7}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="xattr aio alsa cpu_flags_x86_avx2 cpu_flags_x86_avx512f debug io-uring jack +lto malloc-trim membarrier nls doc pulseaudio sdl test"
REQUIRED_USE="debug? ( !lto  )"
RESTRICT="!test? ( test )"

DEPEND="media-libs/libepoxy
	dev-libs/libxml2[static-libs(+)]
	media-libs/libsdl2
	net-libs/libslirp
	media-libs/libsamplerate
	dev-libs/openssl
	virtual/opengl
	x11-libs/gtk+:3
	dev-libs/glib
	net-libs/libpcap
	pulseaudio? ( media-sound/pulseaudio )
	io-uring? ( sys-libs/liburing:=[static-libs(+)] )
	sys-libs/zlib
	alsa? ( media-libs/alsa-lib )
	jack? ( virtual/jack )
	aio? ( dev-libs/libaio )
	xattr? ( sys-apps/attr[static-libs(+)] )"
RDEPEND="${DEPEND}"
BDEPEND="dev-util/meson
	dev-lang/perl
	sys-apps/texinfo
	dev-util/ninja
	virtual/pkgconfig
	$(python_gen_impl_dep)
	doc? (
			dev-python/sphinx
			dev-python/sphinx_rtd_theme
	)
	test? (
			dev-libs/glib[utils]
			sys-devel/bc
	)"

PATCHES=( "${FILESDIR}/${PN}-bin-name.patch" )
DOCS=( README.md )

S="${WORKDIR}/${PN}-${SHA}"

src_prepare() {
	{ rmdir hw/xbox/nv2a/xxHash && mv "${WORKDIR}/xxHash-${XXHASH_SHA}" hw/xbox/nv2a/xxHash; } || die
	{ rmdir tests/fp/berkeley-softfloat-3 && mv "${WORKDIR}/berkeley-softfloat-3-${SOFTFLOAT_SHA}" tests/fp/berkeley-softfloat-3; } || die
	{ rmdir tests/fp/berkeley-testfloat-3 && mv "${WORKDIR}/berkeley-testfloat-3-${TESTFLOAT_SHA}" tests/fp/berkeley-testfloat-3; } || die
	{ rmdir ui/imgui && mv "${WORKDIR}/imgui-${IMGUI_SHA}" ui/imgui; } || die
	{ rmdir ui/implot && mv "${WORKDIR}/implot-${IMPLOT_SHA}" ui/implot; } || die
	{ rmdir ui/keycodemapdb &&	mv "${WORKDIR}/keycodemapdb-${KEYCODEMAPDB_SHA}" ui/keycodemapdb; } || die
	default
}

src_configure() {
	local audio_drv_list=()
	local build_cflags=("-I${S}/ui/imgui")
	local debug_flag
	if use debug; then
		filter-flags '-O*'
		build_cflags+=(-O0 -g -DXEMU_DEBUG_BUILD=1)
		debug_flag=--enable-debug
	fi
	use alsa && audio_drv_list+=( alsa )
	use jack && audio_drv_list+=( jack )
	use pulseaudio && audio_drv_list+=( pa )
	use sdl && audio_drv_list+=( sdl )
	local other_opts=(
		--docdir=/usr/share/doc/${PF}/html
		--libdir=/usr/$(get_libdir)
		--disable-bsd-user
		--disable-containers # bug #732972
		--disable-guest-agent
		--disable-tcg-interpreter
		--cc="$(tc-getCC)"
		--cxx="$(tc-getCXX)"
		--host-cc="$(tc-getBUILD_CC)"
		$(use_enable debug debug-info)
		$(use_enable debug debug-tcg)
		$(use_enable doc docs)
		$(use_enable nls gettext)
		$(use_enable xattr attr)
		# From qemu ebuild
		# We support gnutls/nettle for crypto operations.  It is possible
		# to use gcrypt when gnutls/nettle are disabled (but not when they
		# are enabled), but it's not really worth the hassle.  Disable it
		# all the time to avoid automatically detecting it. #568856
		--disable-gcrypt
		# use prebuilt keymaps, bug #759604
		--disable-xkbcommon
		--enable-libxml2
	)
	econf \
		$(use_enable malloc-trim) \
		$(use_enable lto) \
		${debug_flag} \
		$(use_enable io-uring linux-io-uring) \
		--disable-blobs \
		--disable-qom-cast-debug \
		$(use_enable membarrier) \
		--disable-strip \
		$(use_enable cpu_flags_x86_avx2 avx2) \
		$(use_enable cpu_flags_x86_avx512f avx512f) \
		--disable-werror \
		$(use_enable aio linux-aio) \
		--enable-slirp=system \
		"--extra-cflags=-DXBOX=1 ${build_cflags[@]} -Wno-error=redundant-decls ${CFLAGS}" \
		--target-list=i386-softmmu \
		--with-git-submodules=ignore \
		"--audio-drv-list=${audio_drv_list[*]}" \
		"${other_opts[@]}"
}

src_compile() {
	MAKEOPTS+=" V=1"
	emake "${PN}"
}

src_install() {
	default
	rm -r "${ED}/usr/share/qemu" || die
	while IFS=$'\n' read -r name; do
		mv "${name}" "${name/qemu/${PN}}" || die
	done < <(find "${ED}/usr/share" -name 'qemu.*')
	einstalldocs
}

src_test() {
	cd "${S}/build"
	pax-mark m */xemu #515550
	emake check
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
