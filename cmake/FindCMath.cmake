include(CheckLibraryExists)
check_library_exists(m ceil "" LIBM)
if(LIBM)
    set(CMATH_LIBRARIES m)
else()
    set(CMATH_LIBRARIES)
endif()

if(NOT TARGET CMath::CMath)
    add_library(CMath::CMath INTERFACE IMPORTED)
    set_target_properties(CMath::CMath PROPERTIES
        INTERFACE_LINK_LIBRARIES "${CMATH_LIBRARIES}"
    )
endif()
