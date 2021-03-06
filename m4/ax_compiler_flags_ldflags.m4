# ==============================================================================
#  https://www.gnu.org/software/autoconf-archive/ax_compiler_flags_ldflags.html
# ==============================================================================
#
# SYNOPSIS
#
#   AX_COMPILER_FLAGS_LDFLAGS([VARIABLE], [IS-RELEASE], [EXTRA-BASE-FLAGS], [EXTRA-YES-FLAGS])
#
# DESCRIPTION
#
#   Add warning flags for the linker to VARIABLE, which defaults to
#   WARN_LDFLAGS.  VARIABLE is AC_SUBST-ed by this macro, but must be
#   manually added to the LDFLAGS variable for each target in the code base.
#
#   This macro depends on the environment set up by AX_COMPILER_FLAGS.
#   Specifically, it uses the value of $ax_enable_compile_warnings to decide
#   which flags to enable.
#
# LICENSE
#
#   Copyright (c) 2014, 2015 Philip Withnall <philip@tecnocode.co.uk>
#   Copyright (c) 2017, 2018 Reini Urban <rurban@cpan.org>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved.  This file is offered as-is, without any
#   warranty.

#serial 11

AC_DEFUN([AX_COMPILER_FLAGS_LDFLAGS],[
    AX_REQUIRE_DEFINED([AX_APPEND_LINK_FLAGS])
    AX_REQUIRE_DEFINED([AX_APPEND_FLAG])
    AX_REQUIRE_DEFINED([AX_CHECK_COMPILE_FLAG])
    AX_REQUIRE_DEFINED([AX_CHECK_LINK_FLAG])

    # Variable names
    m4_define([ax_warn_ldflags_variable],
              [m4_normalize(ifelse([$1],,[WARN_LDFLAGS],[$1]))])

    # Always pass -Werror=unknown-warning-option to get Clang to fail on bad
    # flags, otherwise they are always appended to the warn_ldflags variable,
    # and Clang warns on them for every compilation unit.
    # If this is passed to GCC, it will explode, so the flag must be enabled
    # conditionally.
    AX_CHECK_COMPILE_FLAG([-Werror=unknown-warning-option],[
        ax_compiler_flags_test="-Werror=unknown-warning-option"
    ],[
        ax_compiler_flags_test=""
    ])

    # as-needed only on elf
    case $host_os in
        mingw* |cygwin* | msys* | pw32 | os2* | cegcc* ) ;;
        # darwin* | rhapsody* ) ;;
        *)  AX_APPEND_LINK_FLAGS([-Wl,--as-needed],
                [AM_LDFLAGS],[$ax_compiler_flags_test])
            ;;
    esac
    AX_APPEND_LINK_FLAGS([-Wl,-z,relro],
        [AM_LDFLAGS],[$ax_compiler_flags_test])
    AX_APPEND_LINK_FLAGS([-Wl,-z,now],
        [AM_LDFLAGS],[$ax_compiler_flags_test])
    AX_APPEND_LINK_FLAGS([-Wl,-z,noexecstack],
        [AM_LDFLAGS],[$ax_compiler_flags_test])
    dnl /usr/bin/ld: warning: -z retpolineplt ignored.
    case $RETPOLINE_CFLAGS in
        *-mretpoline*|*-mindirect-branch=thunk-extern*)
            AX_APPEND_LINK_FLAGS(["$RETPOLINE_CFLAGS -Wl,-z,retpolineplt"],
                [RETPOLINE_LDFLAGS],[$ax_compiler_flags_test])
            if test -n "$RETPOLINE_LDFLAGS"; then
                AM_CFLAGS="$AM_CFLAGS $RETPOLINE_CFLAGS"
                AM_LDFLAGS="$AM_LDFLAGS $RETPOLINE_LDFLAGS"
                AX_APPEND_LINK_FLAGS([-Wl,-z,textonly],
                    [AM_LDFLAGS],[$ax_compiler_flags_test])
            else
                AC_MSG_WARN([Your LD does not support -z,retpolineplt try -fuse-ld=lld-7])
            fi
            ;;
    esac

    # macOS linker speaks with a different accent
    ax_compiler_flags_fatal_warnings_option=""
    AX_CHECK_LINK_FLAG([-Wl,--fatal-warnings], [
        ax_compiler_flags_fatal_warnings_option="-Wl,--fatal-warnings"
    ])
    AX_CHECK_LINK_FLAG([-Wl,-fatal_warnings], [
        ax_compiler_flags_fatal_warnings_option="-Wl,-fatal_warnings"
    ])

    # Base flags
    AX_APPEND_LINK_FLAGS([ dnl
         $3 dnl
    ],ax_warn_ldflags_variable,[$ax_compiler_flags_test])

    AS_IF([test "$ax_enable_compile_warnings" != "no"],[
        # "yes" flags
        AX_APPEND_LINK_FLAGS([$4 $5 $6 $7],
                             ax_warn_ldflags_variable,
                             [$ax_compiler_flags_test])
    ])
    AS_IF([test "$ax_enable_compile_warnings" = "error"],[
        # "error" flags; -Werror has to be appended unconditionally because
        # it's not possible to test for
        #
        # suggest-attribute=format is disabled because it gives too many false
        # positives
        AX_APPEND_LINK_FLAGS([ dnl
            $ax_compiler_flags_fatal_warnings_option dnl
        ],ax_warn_ldflags_variable,[$ax_compiler_flags_test])
    ])

    # Substitute the variables
    AC_SUBST(ax_warn_ldflags_variable)
])dnl AX_COMPILER_FLAGS
