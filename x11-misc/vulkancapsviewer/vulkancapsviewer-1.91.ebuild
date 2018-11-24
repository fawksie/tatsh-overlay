# Copyright 2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit qmake-utils

DESCRIPTION="Vulkan hardware capability viewer"
HOMEPAGE="https://vulkan.gpuinfo.org https://github.com/SaschaWillems/VulkanCapsViewer"
SRC_URI="https://github.com/SaschaWillems/VulkanCapsViewer/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-qt/qtcore dev-qt/qtnetwork dev-qt/qtwidgets dev-qt/qtgui"
RDEPEND="${DEPEND}"
BDEPEND=""

PATCHES=( "${FILESDIR}/55.patch" )

S="${WORKDIR}/VulkanCapsViewer-${PV}"

src_prepare() {
	eqmake5
	default
}

src_install() {
	exeinto /usr/bin/
	doexe Win32/Release/vulkanCapsViewer
	default
}
