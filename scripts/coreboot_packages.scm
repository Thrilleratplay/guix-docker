(use-modules
    (guix build-system gnu)
    (guix licenses)
    (guix packages)
    (guix download)
    (gnu packages gcc)
    (gnu packages multiprecision)
    (gnu packages commencement)
    (guix utils)

)

;*******************************************************************************
;**************************** coreboot packages ********************************
;*******************************************************************************

(define gcc-8.3
  (package
    (inherit gcc-7)
    (version "8.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://gnu.mirror.constant.com/gcc/gcc-"
                                  version "/gcc-" version ".tar.xz"))
              (sha256
               (base32
                "0b3xv411xhlnjmin2979nxcbnidgvzqdf4nbhix99x60dkzavfk4"))
              (patches (search-patches "gcc-8-strmov-store-file-names.patch"
                                       "gcc-5.0-libvtv-runpath.patch"))))))

(define-public coreboot-gcc-toolchain
    (make-gcc-toolchain gcc-8.3  glibc-2.30)) ; 2.27

(define-public coreboot-mpfr
  (package
   (name "coreboot-mpfr")
   (version "4.1.0")
   (source (origin
            (method url-fetch)
            (uri (string-append "http://gnu.mirror.constant.com/mpfr/mpfr-" version
                                ".tar.gz"))
            (sha256 (base32
                     "1mm2zxjqxxqlacd87cxlyi63pwrxwafqks7lmpqa3wqq6a0zw9ri"))))
   (build-system gnu-build-system)
   (outputs '("out" "debug"))
   (propagated-inputs `(("gmp", gmp)))            ; <mpfr.h> refers to <gmp.h>
   (synopsis "C library for arbitrary-precision floating-point arithmetic")
   (description
    "GNU@tie{}@acronym{MPFR, Multiple Precision Floating-Point Reliably} is a C
library for performing multiple-precision, floating-point computations with
correct rounding.")
   (license lgpl3+)
   (home-page "https://www.mpfr.org/")))

(define coreboot-mpc
  (package
   (name "coreboot-mpc")
   (version "1.2.0")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://gnu.mirror.constant.com/mpc/mpc-" version ".tar.gz"))
            (sha256
              (base32
                "19pxx3gwhwl588v496g3aylhcw91z1dk1d5x3a8ik71sancjs3z9"))))
   (build-system gnu-build-system)
   (outputs '("out" "debug"))
   (propagated-inputs `(("gmp", gmp)              ; <mpc.h> refers to both
             ("mpfr", coreboot-mpfr)))
   (synopsis "C library for arbitrary-precision complex arithmetic")
   (description
    "GNU@tie{}@acronym{MPC, Multiple Precision Complex library} is a C library
for performing arithmetic on complex numbers.  It supports arbitrarily high
precision and correctly rounds the results.")
   (license lgpl3+)
   (home-page "http://www.multiprecision.org/mpc/")))


;*******************************************************************************
;**************************** Package manifest *********************************
;*******************************************************************************
(concatenate-manifests
 (list (specifications->manifest
        (list
          "bzip2"
          "coreutils-minimal"
          "diffutils"
          "grep"
          "gzip"
          "patch"
          "sed"
          "tar"
          "vim"
          "wget"
          "which"

          "acpica"
          "automake"
          "bash"
          "bc"
          "binutils"
          "bison"
          "ccache"
          "cmake"
          "crypto++"
          "curl"
          "flex"
          "font-gnu-unifont"
          "gawk"
          "git-minimal"
          "glibc-utf8-locales"
          "gmp@6.2.0"
          "go"
          "libelf"
          "libressl"
          "libxml2"
          "libyaml"
          "lzlib"
          "m4"
          "make"
          "nasm"
          "ncurses"
          "nss-certs"
          "openssl"
          "pbzip2" ; parallel bzip2
          "perl"
          "pkg-config"
          "python-minimal"
          "python2-minimal"
          "readline"
          "util-linux"
          "xz"
          "zlib"
         ))
       ;; voreboot packages.
       (packages->manifest
        (list
          coreboot-gcc-toolchain
          coreboot-mpc
          coreboot-mpfr
        ))
))
