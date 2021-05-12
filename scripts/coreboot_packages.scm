(use-modules
    (guix build-system gnu)
    (guix build-system trivial)
    (guix licenses)
    (guix packages)
    (guix download)
    (gnu packages gcc)
    (gnu packages multiprecision)
    (gnu packages commencement)
    (guix utils)
    (gnu packages bootstrap)
    (gnu packages m4)
    (gnu packages version-control)
    (gnu packages bison)
    (gnu packages flex)
    (gnu packages perl)
    (gnu packages curl)
    (gnu packages base)
    (gnu packages linux)
    (gnu packages elf)
    (gnu packages python)
    (gnu packages glib)
    (gnu packages compression)
    (guix build-system trivial)
    (ice-9 match)
)

(define-public debzlib
  (package
    (name "debzlib")
    (version "1.2.8")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "http://ftp.us.debian.org/debian/pool/main/z/zlib/zlib1g_"  version  ".dfsg-5_i386.deb"))
              (sha256
               (base32 "158fhna62d9g72hnxcg8i81vfi0lihakjp761ly1qj92pivj5bb6"))))
    (build-system gnu-build-system)
    (arguments
         `(#:tests? #f            ; No tests
           #:validate-runpath? #f
           #:phases
           (modify-phases %standard-phases
             (replace `unpack
               (lambda* (#:key source #:allow-other-keys)
                  (invoke "ar" "x" source)
                  (invoke "tar" "-xJf" "./data.tar.xz")
                  (delete-file-recursively "./usr/share/"))
              )
              (delete `configure)
              (delete `build)
              (delete `reset-gzip-timestamps)
              (replace 'install
                (lambda* (#:key outputs #:allow-other-keys)
                  (let* ((outlib (string-append (assoc-ref outputs "out") "/lib")))
                    (mkdir-p outlib)
                    (install-file "./lib/i386-linux-gnu/libz.so.1.2.8" outlib)
                  )
                #t)
              )
             )))
    (native-inputs
     `(("binutils", binutils)
     ))
     (synopsis "FIXME")
     (description "FIXME")
     (home-page "FIXME")
     (license "FIXME")
     ))


(define-public zlibdev
  (package
    (name "zlibdev")
    (version "1.2.11")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "http://ftp.us.debian.org/debian/pool/main/z/zlib/zlib1g-dev_"  version  ".dfsg-1_i386.deb"))
              (sha256
               (base32 "14qwl017sap2pcmpmzs14d3f80v3g225cdh2xfaby2ndqf08ppii"))))
    (build-system gnu-build-system)
    (arguments
         `(#:tests? #f            ; No tests
           #:validate-runpath? #f
           #:phases
           (modify-phases %standard-phases
             (replace `unpack
               (lambda* (#:key source #:allow-other-keys)
                  (invoke "ar" "x" source)
                  (invoke "tar" "-xJf" "./data.tar.xz")
                  (delete-file-recursively "./usr/share/"))
              )
              (delete `configure)
              (delete `build)
              (delete `reset-gzip-timestamps)
              (replace 'install
                (lambda* (#:key inputs outputs #:allow-other-keys)
                  (let* ((out (assoc-ref outputs "out"))
                         (outinclude (string-append out "/include"))
                         (outlib (string-append out "/lib"))
                         (zlib (assoc-ref inputs "debzlib")))

                    (mkdir-p outinclude)
                    (copy-recursively "./usr/include/" outinclude)

                    (mkdir-p outlib)
                    (copy-recursively "./usr/lib/i386-linux-gnu/" outlib)

                    (install-file (string-append zlib "/lib/libz.so.1.2.8") outlib)
                  )
                #t)
              )
             )))
    (native-inputs
     `(("binutils", binutils)
       ("debzlib", debzlib)
     ))
     (synopsis "FIXME")
     (description "FIXME")
     (home-page "FIXME")
     (license "FIXME")
     ))



;*******************************************************************************
;**************************** coreboot packages ********************************
;*******************************************************************************

;;; FIXME: need to bootstrap ada/gnat
; https://bootstrapping.miraheze.org/w/index.php?title=Bootstrapping_Specific_Languages&mobileaction=toggle_view_desktop
; http://www.linuxfromscratch.org/blfs/view/8.3/general/gcc-ada.html

(define-public gnat-bootstrap
  (package
    (name "gnat-bootstrap")
    (version "2014")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://community.download.adacore.com/v1/"
                      (match (%current-target-system)
                        (i686-linux "c5e9e6fdff5cb77ed90cf8c62536653e27c0bed6?filename=gnat-gpl-2014-x86-linux-bin.tar.gz")
                        (x86_64-linux "4d99b7b2f212c8efdab2ba8ede474bb9fa15888d?filename=gnat-2020-20200429-x86_64-linux-bin.tar.gz"))))
              (sha256
               (base32
                 (match (%current-target-system)
                   (i686-linux "0hn0v7gqyh6cj7sa8qagdv6hrn6v39696d1hpc528anjyl83as9v")
                   (x86_64-linux "19pxx3gwhwl588v496g3aylhcw91z1dk1d5x3a8ik71sancjs3z9"))

                ))))
    (inputs `(("zlibdev", zlibdev)))
    (native-inputs `(("patchelf" ,patchelf)))
    (build-system gnu-build-system)
    (outputs '("out"))
    (arguments
      '(#:tests? #f
        #:validate-runpath? #f
        #:phases
          (modify-phases %standard-phases
           (delete 'configure)
           (delete 'build)
           (replace `install
             (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref outputs "out"))
                  (zlib (assoc-ref inputs "zlibdev"))
                  (libc (assoc-ref inputs "libc"))
                  (rpath (string-append out "/lib"))
                  (ld-so (string-append libc "/lib/ld-linux.so.2"))) ;; FIXME: 32 bit only

                (install-file "./bin/gcc" (string-append out "/bin/"))

                (for-each (lambda (file)
                    (let ((outdir (string-append out "/bin/")))
                    (install-file (string-append "./bin/" file) outdir)
                    (invoke "patchelf" "--set-rpath" rpath (string-append outdir file))
                    (invoke "patchelf" "--set-interpreter" ld-so (string-append outdir file)))
                ) `(
                  "c++"
                  "cpp"
                  "g++"
                  "gcc-ar"
                  "gcc-nm"
                  "gcc-ranlib"
                  "gcov"
                  "gdb"
                  "gdbserver"
                  "gnat"
                  "gnat2xml"
                  "gnat2xsd"
                  "gnatbind"
                  "gnatcheck"
                  "gnatchop"
                  "gnatclean"
                  "gnatdoc"
                  "gnatelim"
                  "gnatfind"
                  "gnatinspect"
                  "gnatkr"
                  "gnatlink"
                  "gnatls"
                  "gnatmake"
                  "gnatmem"
                  "gnatmetric"
                  "gnatname"
                  "gnatpp"
                  "gnatprep"
                  "gnatspark"
                  "gnatstub"
                  "gnattest"
                  "gnatxref"
                  "gprbuild"
                  "gprclean"
                  "gprconfig"
                  "gprinstall"
                  "gprslave"
                  "gps_exe"
                  "i686-pc-linux-gnu-c++"
                  "i686-pc-linux-gnu-g++"
                  "i686-pc-linux-gnu-gcc-4.7.4"
                  "i686-pc-linux-gnu-gcc-ar"
                  "i686-pc-linux-gnu-gcc-nm"
                  "i686-pc-linux-gnu-gcc-ranlib"
                  "xml2gnat"
                ))

                (for-each (lambda (file)
                    (let ((outdir (string-append out "/bin/")))
                    (install-file (string-append "./bin/" file) outdir)
                    (invoke "patchelf" "--set-rpath" rpath (string-append outdir file)))
                ) `("i686-pc-linux-gnu-gcc"))

                (for-each (lambda (file)
                    (let ((outdir (string-append out "/bin/")))
                    (install-file (string-append "./bin/" file) outdir)
                    (invoke "patchelf" "--set-interpreter" ld-so (string-append outdir file)))
                ) `("gcc"))

                (for-each (lambda (file)
                    (let ((outdir (string-append out "/libexec/gcc/i686-pc-linux-gnu/4.7.4/")))
                    (install-file (string-append "./libexec/gcc/i686-pc-linux-gnu/4.7.4/" file) outdir)
                    (invoke "patchelf" "--set-rpath" rpath (string-append outdir file)))
                ) `("cc1"))

                (copy-recursively (assoc-ref inputs "zlibdev") out)

                (chmod (string-append out "/lib/libz.so.1.2.8") #o777)
                (invoke "patchelf" "--set-rpath" rpath (string-append out "/lib/libz.so.1.2.8"))

                (chdir out)
                (symlink "lib" "lib32")
                (symlink "lib" "lib64")

                (chdir (string-append out "/bin"))
                (symlink "i686-pc-linux-gnu-gcc" "gnatgcc")

                (delete-file-recursively (string-append out "/lib/libz.so"))

                (chdir (string-append out "/lib"))
                (symlink "libz.so.1.2.8" "libz.so.1")
                (symlink "libz.so.1.2.8" "libz.so")
             )
             #t)
            )
            (delete `reset-gzip-timestamps)
          )
    ))
    (synopsis "FIXME")
    (description "FIXME")
    (home-page "https://www.adacore.com")
    (license "FIXME")))

(define-public coreboot-crossgcc
  (package
    (name "coreboot-crossgcc")
    (version "4.13")
    (source (origin
              (method url-fetch)
              (uri
                (string-append "https://www.coreboot.org/releases/coreboot-" version ".tar.xz"))
              (file-name (string-append name "-" version ".tar.xz"))
              (sha256
                (base32 "0sl50aajnah4a138sr3jjm3ydc8gfh5vvlhviz3ypp95b9jdlya7"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f            ; No tests
      #:make-flags (list "--directory=./util/crossgcc/" "all_without_gdb" "BUILD_LANGUAGES=c,ada" "CPUS=2" "DEST=/opt/crossgcc") ; "LD_DEBUG=all"
      #:phases
       (modify-phases %standard-phases
          (replace 'configure
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((gnatpath (assoc-ref inputs "gnat-bootstrap")))
                (setenv "PATH" (string-append gnatpath "/bin:" (getenv "PATH")))
                (setenv "LIBRARY_PATH" (string-append gnatpath "/lib:" (getenv "LIBRARY_PATH")))

                (setenv "CPPFLAGS" (string-append "-I" gnatpath  "/include"))
                (setenv "CFLAGS" (string-append "-I" gnatpath  "/include"))
                (setenv "LDFLAGS" (string-append "-L" gnatpath))
                (setenv "LD_LIBRARY_PATH" (string-append gnatpath "/lib/"))
              )
            #t)
          )
         )
    ))
    (native-inputs
     `(
       ; ("gcc-toolchain", gcc-toolchain-10)
       ("gnat-bootstrap", gnat-bootstrap)
       ("perl", perl)
       ("python-2", python-2)
       ("python", python)
       ("util-linux", util-linux)
     ))
    (inputs
     `(
        ("bison", bison)
        ("curl", curl)
        ("flex", flex)
        ("git-minimal", git-minimal)
        ("m4", m4)
        ("perl", perl)
    ))
    (synopsis "coreboot")
    (description "FIXME")
    (home-page "FIXME")
    (license #f)))

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
          ;"nss-certs"
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
          ;gnat-bootstrap
          coreboot-crossgcc
          ;coreboot-gcc-toolchain
          ;coreboot-mpc
          ;coreboot-mpfr
        ))
))
