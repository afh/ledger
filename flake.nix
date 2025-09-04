{
  description = "A double-entry accounting system with a command-line reporting interface";

  nixConfig.bash-prompt = "ledger$ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: let
    usePython = true;
    gpgmeSupport = true;
    useLibedit = true;
    useReadline = false;
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in {

    packages = forAllSystems (system: let
        pkgs = nixpkgsFor.${system};
      in with pkgs; rec {
      lpy = ledger.overrideAttrs({nativeBuildInputs ? [], ...}: {
        pname = "lpy";
        nativeBuildInputs = ledger.nativeBuildInputs ++ (with python3.pkgs; [
          pipx
          uv
          build
          scikit-build-core
          pkgs.ninja
          pkgs.writableTmpDirAsHomeHook
        ]);

        outputs = [ "out" ];

        dontConfigure = true;
        dontFixup = true;
        doCheck = false;

        buildPhase = ''
          runHook preBuild

          # Build Python wheel using scikit-build-core
          export CMAKE_BUILD_PARALLEL_LEVEL=$NIX_BUILD_CORES
          ${python3.interpreter} -m build --wheel --outdir dist/pip
          ${lib.getExe python3.pkgs.pipx} run build --wheel --outdir dist/pipx
          ${lib.getExe python3.pkgs.uv} build --wheel --out-dir dist/uv

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          mv dist/* $out

          runHook postInstall
        '';
      });

      ledger = stdenv.mkDerivation {
        pname = "ledger";
        version = "3.3.2-${self.shortRev or "dirty"}";

        src = self;

        outputs = [ "out" "dev" ] ++ lib.optionals usePython [ "py" ];

        buildInputs = [
          gmp mpfr gnused icu
        ] ++ lib.optionals useLibedit [
          libedit
        ] ++ lib.optionals useReadline [
          readline
        ] ++ lib.optionals gpgmeSupport [
          gpgme
        ] ++ (if usePython
              then [ python3 (boost.override { enablePython = true; python = python3; }) ]
              else [ boost ]);

        nativeBuildInputs = [
          cmake texinfo tzdata
        ] ++ lib.optionals useLibedit [
          libedit.dev
        ] ++ lib.optionals useReadline [
          readline.dev
        ];

        enableParallelBuilding = true;

        cmakeFlags = [
          "-DCMAKE_INSTALL_LIBDIR=lib"
          "-DBUILD_DOCS:BOOL=ON"
          "-DUSE_PYTHON:BOOL=${if usePython then "ON" else "OFF"}"
          "-DUSE_GPGME:BOOL=${if gpgmeSupport then "ON" else "OFF"}"
        ];

        # by default, it will query the python interpreter for its sitepackages location
        # however, that would write to a different nixstore path, pass our own sitePackages location
        prePatch = lib.optionalString usePython ''
          substituteInPlace CMakeLists.txt \
            --replace-fail 'PYPKG_DEST "''${Python3_SITEARCH}' 'PYPKG_DEST "${placeholder "py"}/${python3.sitePackages}'
        '';

        installTargets = [ "doc" "install" ];

        checkPhase = ''
          runHook preCheck
          env LD_LIBRARY_PATH=$PWD \
            DYLD_LIBRARY_PATH=$PWD \
            ctest -j$NIX_BUILD_CORES
          runHook postCheck
        '';

        doCheck = true;

        meta = with lib; {
          description = "A double-entry accounting system with a command-line reporting interface";
          homepage = "https://ledger-cli.org/";
          changelog = "https://github.com/ledger/ledger/raw/v${version}/NEWS.md";
          license = lib.licenses.bsd3;
          longDescription = ''
            Ledger is a powerful, double-entry accounting system that is accessed
            from the UNIX command-line. This may put off some users, as there is
            no flashy UI, but for those who want unparalleled reporting access to
            their data, there really is no alternative.
          '';
          platforms = lib.platforms.all;
          maintainers = with maintainers; [ jwiegley ];
        };
      };
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.ledger);

  };
}
