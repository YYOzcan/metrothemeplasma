cmake_minimum_required(VERSION 3.20)
project(metro-kabuk LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml DBus Network Concurrent)
foreach(m Service KIO GlobalAccel WindowSystem Config CoreAddons Runner I18n)
    find_package(KF6${m} REQUIRED)
endforeach()
find_package(LayerShellQt REQUIRED)

qt_add_executable(metro-kabuk
    src/main.cpp
    src/katman.cpp
    src/uygulamalar.cpp
    src/sistem.cpp
    src/kabuk.cpp
    src/dosya.cpp
    src/simgerengi.cpp
    src/medya.cpp
    src/desen.cpp
)

# QML dosyaları ikilinin içine gömülmez: ~/.local/share/metrothemeplasma/kabuk/qml'den yüklenir
# (yerinde düzeltme/güncelleme için yeniden derleme gerekmez)

target_link_libraries(metro-kabuk PRIVATE
    Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::DBus Qt6::Network Qt6::Concurrent
    KF6::Service KF6::KIOGui KF6::KIOCore KF6::GlobalAccel KF6::WindowSystem KF6::ConfigCore
    KF6::CoreAddons KF6::Runner KF6::I18n
    LayerShellQt::Interface
)

install(TARGETS metro-kabuk RUNTIME DESTINATION bin)

# Windows 8.1 "Çalıştır" iletişim kutusu (Win+R): Qt Widgets + Kvantum Metro
find_package(Qt6 REQUIRED COMPONENTS Widgets)
qt_add_executable(metro-calistir calistir/main.cpp)
target_link_libraries(metro-calistir PRIVATE Qt6::Widgets KF6::KIOGui KF6::KIOCore KF6::Service)
install(TARGETS metro-calistir RUNTIME DESTINATION bin)
