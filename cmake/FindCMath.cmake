find_library(CMATH_LIBRARY NAMES m)

if (CMATH_LIBRARY)
    add_library(CMath::CMath INTERFACE IMPORTED)
    set_target_properties(CMath::CMath PROPERTIES
        INTERFACE_LINK_LIBRARIES "${CMATH_LIBRARY}"
    )
    set(CMATH_FOUND TRUE)
endif()
