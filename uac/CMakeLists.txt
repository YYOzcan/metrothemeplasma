# MetroThemePlasma — Windows 8.1 Kullanıcı Hesabı Denetimi (polkit kimlik doğrulama aracısı).
# AeroThemePlasma'nın uac-polkit-agent'ının (KDE polkit-kde-agent-1 çatalı, GPL-2.0-or-later) çatalı.
cmake_minimum_required(VERSION 3.16)
project(metro-uac)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(CheckIncludeFile)
include(CheckSymbolExists)

find_package(Qt6 REQUIRED COMPONENTS Core DBus Widgets Quick Qml)
find_package(KF6 REQUIRED COMPONENTS I18n WindowSystem Notifications DBusAddons CoreAddons Crash Config)
find_package(PolkitQt6-1 REQUIRED)

check_include_file("sys/prctl.h" HAVE_SYS_PRCTL_H)
check_symbol_exists(PR_SET_DUMPABLE "sys/prctl.h" HAVE_PR_SET_DUMPABLE)
check_include_file("sys/procctl.h" HAVE_SYS_PROCCTL_H)
check_symbol_exists(PROC_TRACE_CTL "sys/procctl.h" HAVE_PROC_TRACE_CTL)

configure_file(config.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.h)
include_directories(${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
set(PROJECT_VERSION "6.8.0")

add_definitions(-DQT_NO_KEYWORDS)
qt_add_dbus_adaptor(uac_SRCS org.kde.Polkit1AuthAgent.xml policykitlistener.h PolicyKitListener)

# yalnızca sınama: METRO_UAC_SINAMA_PAROLA ile parolayı kendisi girer (bu derleme kurulmaz)
option(METRO_UAC_SINAMA "sınama kancası" OFF)

add_executable(metro-uac ${uac_SRCS} main.cpp policykitlistener.cpp QuickAuthDialog.cpp IdentitiesModel.cpp uac.qrc)
if(METRO_UAC_SINAMA)
    target_compile_definitions(metro-uac PRIVATE METRO_UAC_SINAMA)
endif()
target_link_libraries(metro-uac
    KF6::DBusAddons KF6::WindowSystem KF6::CoreAddons KF6::I18n KF6::Crash KF6::I18nQml
    KF6::Notifications KF6::ConfigCore KF6::ConfigGui
    Qt::Qml Qt::Quick Qt::Widgets PolkitQt6-1::Agent)
