# Copyright 2021-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit cmake flag-o-matic xdg

DESCRIPTION="Nintendo Switch emulator"
HOMEPAGE="https://yuzu-emu.org/ https://github.com/yuzu-emu/yuzu-mainline"

MY_PV="mainline-${PV/./-}"
CPP_JWT_SHA="e12ef06218596b52d9b5d6e1639484866a8e7067"
DYNARMIC_SHA="bd570e093ca1d1206961296b90df65cda7de8e87"
FMT_PV="9.1.0"
HTTPLIB_SHA="305a7abcb9b4e9e349843c6d563212e6c1bbbf21"
MBEDTLS_SHA="8c88150ca139e06aa2aae8349df8292a88148ea1"
SDL_SHA="f17058b562c8a1090c0c996b42982721ace90903"
SIRIT_SHA="d7ad93a88864bda94e282e95028f90b5784e4d20"
SRC_URI="https://github.com/yuzu-emu/yuzu-mainline/archive/${MY_PV}.tar.gz -> ${P}.tar.gz
	https://github.com/arun11299/cpp-jwt/archive/${CPP_JWT_SHA}.tar.gz -> ${PN}-cpp-jwt-${CPP_JWT_SHA:0:7}.tar.gz
	https://github.com/yuzu-emu/mbedtls/archive/${MBEDTLS_SHA}.tar.gz -> ${PN}-mbedtls-${MBEDTLS_SHA:0:7}.tar.gz
	https://github.com/MerryMage/dynarmic/archive/${DYNARMIC_SHA}.tar.gz -> ${PN}-dynarmic-${DYNARMIC_SHA:0:7}.tar.gz
	https://github.com/ReinUsesLisp/sirit/archive/${SIRIT_SHA}.tar.gz -> ${PN}-sirit-${SIRIT_SHA:0:7}.tar.gz
	https://github.com/yhirose/cpp-httplib/archive/${HTTPLIB_SHA}.tar.gz -> ${PN}-httplib-${HTTPLIB_SHA:0:7}.tar.gz
	https://github.com/libsdl-org/SDL/archive/${SDL_SHA}.tar.gz -> ${PN}-sdl-${SDL_SHA:0:7}.tar.gz"

LICENSE="BSD GPL-2 GPL-2+ LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+compatibility-reporting +cubeb +web-service"
REQUIRED_USE="compatibility-reporting? ( web-service )"

DEPEND=">=app-arch/zstd-1.5.0
	>=dev-libs/xbyak-6.03
	>=media-video/ffmpeg-4.3
	app-arch/lz4
	cubeb? ( media-libs/cubeb )
	dev-cpp/robin-map
	dev-libs/boost:=[context]
	dev-libs/inih
	dev-libs/libfmt
	dev-libs/libzip
	dev-libs/openssl
	dev-qt/qtcore
	dev-qt/qtdbus
	dev-qt/qtgui
	dev-qt/qtmultimedia
	dev-qt/qtmultimedia
	dev-qt/qtwebengine
	dev-qt/qtwidgets
	media-libs/libsdl2
	media-libs/libva
	media-libs/opus
	net-libs/enet:=
	sys-libs/libunwind
	sys-libs/zlib
	virtual/libusb:="
RDEPEND="${DEPEND}
	media-libs/vulkan-loader"
BDEPEND="dev-cpp/nlohmann_json
	dev-util/glslang
	>=dev-util/vulkan-headers-1.3.216
	dev-util/spirv-headers"

S="${WORKDIR}/${PN}-mainline-${MY_PV}"

PATCHES=(
	"${FILESDIR}/${PN}-4949-high-dpi.patch"
	"${FILESDIR}/${PN}-6858-disable-collecttoolinginfo.patch"
)

pkg_setup() {
	wget -O "${T}/compatibility_list.json" https://api.yuzu-emu.org/gamedb/ || die
}

src_prepare() {
	rm .gitmodules || die
	rmdir "${S}/externals/"{dynarmic,mbedtls,sirit,cpp-httplib,cpp-jwt,SDL} || die
	mv "${WORKDIR}/dynarmic-${DYNARMIC_SHA}" "${S}/externals/dynarmic" || die
	mv "${WORKDIR}/sirit-${SIRIT_SHA}" "${S}/externals/sirit" || die
	mv "${WORKDIR}/cpp-httplib-${HTTPLIB_SHA}" "${S}/externals/cpp-httplib" || die
	mv "${WORKDIR}/cpp-jwt-${CPP_JWT_SHA}" "${S}/externals/cpp-jwt" || die
	mv "${WORKDIR}/SDL-${SDL_SHA}" "${S}/externals/SDL" || die
	mv "${WORKDIR}/mbedtls-${MBEDTLS_SHA}" "${S}/externals/mbedtls" || die
	sed -e 's/find_package(Boost .*/find_package(Boost 1.71 COMPONENTS context REQUIRED)/' -i src/common/CMakeLists.txt || die
	sed -e '/enable_testing.*/d' -e 's/add_subdirectory(externals\/SPIRV-Headers.*/find_package(SPIRV-Headers REQUIRED)/' -i externals/sirit/CMakeLists.txt || die
	sed -e '/-Werror=missing-declarations/d' -i src/CMakeLists.txt || die
	cmake_src_prepare
	mkdir -p "${BUILD_DIR}/dist/compatibility_list" || die
	mv -f "${T}/compatibility_list.json" "${BUILD_DIR}/dist/compatibility_list/compatibility_list.json" || die
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_FULLNAME="${MY_PV}"
		-DBUILD_SHARED_LIBS=OFF
		-DENABLE_COMPATIBILITY_LIST_DOWNLOAD=OFF
		-DENABLE_CUBEB=$(usex cubeb)
		-DENABLE_WEB_SERVICE=$(usex web-service)
		-DGIT_BRANCH="${PN}"
		-DGIT_DESC="${PV}"
		-DGIT_REV="${PV}"
		-DSIRIT_USE_SYSTEM_SPIRV_HEADERS=ON
		-DUSE_DISCORD_PRESENCE=OFF
		-DYUZU_ENABLE_COMPATIBILITY_REPORTING=$(usex compatibility-reporting)
		-DYUZU_TESTS=OFF
		-DYUZU_USE_EXTERNAL_SDL2=OFF
		-DYUZU_USE_QT_MULTIMEDIA=ON
		-DYUZU_USE_QT_WEB_ENGINE=ON
 		-Wno-dev
	)
	cmake_src_configure
}
