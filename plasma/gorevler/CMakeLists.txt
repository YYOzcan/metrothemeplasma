# MetroThemePlasma — Windows 8.1 görev çubuğu. AeroThemePlasma'nın SevenTasks'inden çatallanmıştır
# (renk izleyen parıltı, atlama listeleri, küçük resimler); düğme görselleri kurulumda aero.msstyles'tan
# (TaskBand2Composited8) üretilir. Çalışmak için AeroThemePlasma'nın aeroshell.taskmanager QML modülü gerekir.
cmake_minimum_required(VERSION 3.16)
project(metrogorevler)
set(CMAKE_CXX_STANDARD 20)
find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
set(CMAKE_AUTOMOC ON)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
remove_definitions(-DQT_NO_CAST_FROM_ASCII)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick)
find_package(KF6 REQUIRED COMPONENTS I18n WindowSystem Svg Config CoreAddons)
find_package(Plasma REQUIRED)
find_package(PlasmaQuick REQUIRED)
add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_io.github.yyozcan.metrogorevler\")
add_library(io.github.yyozcan.metrogorevler MODULE seventasks.cpp)
target_link_libraries(io.github.yyozcan.metrogorevler Qt6::Gui Qt6::Quick KF6::I18n KF6::WindowSystem
                      Plasma::Plasma Plasma::PlasmaQuick KF6::Svg KF6::ConfigCore KF6::ConfigGui KF6::CoreAddons)
