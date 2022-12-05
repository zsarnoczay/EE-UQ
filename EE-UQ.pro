#-------------------------------------------------
#
# Project created by QtCreator 2017-06-06T06:31:52
#
#-------------------------------------------------

QT += core gui charts concurrent uitools webenginewidgets network sql qml 3dcore 3drender 3dextras printsupport quick

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets



CONFIG += c++17


MOC_DIR = $$OUT_PWD/.moc
UI_DIR = $$OUT_PWD/.ui
OBJECTS_DIR = $$OUT_PWD/.obj
RCC_DIR = $$OUT_PWD/.rcc

TARGET = EE_UQ
TEMPLATE = app

VERSION=2.2.5
DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += NOINTERNALFEM

include($$PWD/ConanHelper.pri)

win32{
    LIBS = $$replace(LIBS, .dll.lib, .dll)
    LIBS += -lAdvapi32
    LIBS +=CRYPT32.lib
    LIBS +=Ws2_32.lib
    LIBS+=User32.lib
    DEFINES += CURL_STATICLIB
}


linux{

}

win32 {
    RC_ICONS = icons/NHERI-EEUQ-Icon.ico
} else {
    mac {
    ICON = icons/NHERI-EEUQ-Icon.icns
    DEFINES += _GRAPHICS_Qt3D
    QMAKE_INFO_PLIST=$$PWD/Info.plist
    }
}

include(../SimCenterCommon/Common/Common.pri)
include(../SimCenterCommon/Workflow/Workflow.pri)
include(../SimCenterCommon/RandomVariables/RandomVariables.pri)
include(../SimCenterCommon/InputSheetBM/InputSheetBM.pri)
include(../QS3hark/QS3hark.pri)
include(./EarthquakeEvents.pri)

SOURCES += main.cpp \
    WorkflowAppEE_UQ.cpp \
    RunWidget.cpp

HEADERS  += \
    WorkflowAppEE_UQ.h\
    RunWidget.h 


RESOURCES += \
    images.qrc \
    $$PWD/styles.qrc


OTHER_FILES += conanfile.py

