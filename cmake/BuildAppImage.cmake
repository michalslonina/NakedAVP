# Invoked by `cpack` for the "External" generator (see CPACK_EXTERNAL_PACKAGE_SCRIPT
# in CMakeLists.txt). CPACK_EXTERNAL_ENABLE_STAGING is ON, so CPACK_TEMPORARY_DIRECTORY
# already holds a full `cmake --install` tree by the time this script runs - but,
# unlike the DEB/RPM generators, the External generator does not prepend /usr, so
# the staged tree is CPACK_TEMPORARY_DIRECTORY/{bin,share}, not .../usr/{bin,share}.

set(_appdir "${CPACK_TOPLEVEL_DIRECTORY}/AppDir")
file(REMOVE_RECURSE "${_appdir}")
file(MAKE_DIRECTORY "${_appdir}/usr")
file(COPY "${CPACK_TEMPORARY_DIRECTORY}/bin" "${CPACK_TEMPORARY_DIRECTORY}/share"
     DESTINATION "${_appdir}/usr")

file(WRITE "${_appdir}/AppRun"
"#!/bin/sh\nHERE=\"$(dirname \"$(readlink -f \"$0\")\")\"\nexec \"$HERE/usr/bin/avp\" \"$@\"\n")
execute_process(COMMAND chmod +x "${_appdir}/AppRun")

file(COPY "${_appdir}/usr/share/applications/nakedavp.desktop" DESTINATION "${_appdir}")
file(COPY "${_appdir}/usr/share/icons/hicolor/256x256/apps/nakedavp.png" DESTINATION "${_appdir}")

find_program(APPIMAGETOOL_EXE appimagetool)
if(NOT APPIMAGETOOL_EXE)
    set(APPIMAGETOOL_EXE "${CPACK_TOPLEVEL_DIRECTORY}/appimagetool")
    if(NOT EXISTS "${APPIMAGETOOL_EXE}")
        message(STATUS "appimagetool not found on PATH, downloading it")
        file(DOWNLOAD
            "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
            "${APPIMAGETOOL_EXE}"
            SHOW_PROGRESS
            STATUS _dl_status)
        list(GET _dl_status 0 _dl_rc)
        if(NOT _dl_rc EQUAL 0)
            message(FATAL_ERROR "failed to download appimagetool: ${_dl_status}")
        endif()
        execute_process(COMMAND chmod +x "${APPIMAGETOOL_EXE}")
    endif()
endif()

set(_out "${CPACK_PACKAGE_DIRECTORY}/${CPACK_PACKAGE_FILE_NAME}-x86_64.AppImage")
file(REMOVE "${_out}")

set(ENV{APPIMAGE_EXTRACT_AND_RUN} "1")
set(ENV{ARCH} "x86_64")
execute_process(
    COMMAND "${APPIMAGETOOL_EXE}" "${_appdir}" "${_out}"
    RESULT_VARIABLE _rc
    OUTPUT_VARIABLE _out_log
    ERROR_VARIABLE _err_log)
if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "appimagetool failed (${_rc}):\n${_out_log}\n${_err_log}")
endif()

set(CPACK_EXTERNAL_BUILT_PACKAGES "${_out}")
message(STATUS "Built AppImage: ${_out}")
