{
  description = "A double-entry accounting system with a command-line reporting interface";

  nixConfig.bash-prompt = "ledger$ ";

  inputs.nixpkgsUnstable.url = "/Users/afh/Developer/nixpkgs";

  outputs = { self, nixpkgs, nixpkgsUnstable, ... }: let
    usePython = true;
    gpgmeSupport = true;
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    #nixpkgsUnstableFor = forAllSystems (system: import nixpkgsUnstable { inherit system; });
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in {

    packages = forAllSystems (system: let
        pkgs = nixpkgsFor.${system};
        python3 = pkgs.python311;
        #boost = nixpkgsUnstableFor.${system}.boost182;
      in rec {
      delocate = with python3.pkgs; buildPythonPackage rec {
        pname = "delocate";
        version = "0.10.4";
        doCheck = false;
        propagatedBuildInputs = [
          typing-extensions
          packaging
        ];
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-6ucS9G8jSBrIIlC53DVygLjNF6wOV9zghlTV9yJ5PJM=";
        };
      };

      ledger = with pkgs; stdenv.mkDerivation rec {
        pname = "ledger";
        version = "3.3.2-${self.shortRev or "dirty"}";

        src = self;

        outputs = [ "out" "dev" ] ++ lib.optionals usePython [ "py" ];

        buildInputs = [
          gmp mpfr libedit gnused
        ] ++ lib.optionals gpgmeSupport [
          gpgme
        ] ++ (if usePython
              then [ python3 (boost.override { enablePython = true; python = python3; }) ]
              else [ boost ]);

        nativeBuildInputs = [
          cmake texinfo tzdata
          python3.pkgs.pipx delocate
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
          substituteInPlace src/CMakeLists.txt \
            --replace ' ''${Python3_SITEARCH}' ' ${placeholder "py"}/${python3.sitePackages}'
          substituteInPlace src/CMakeLists.txt \
            --replace ' ''${Python3_SITEARCH}' ' ${placeholder "py"}/${python3.sitePackages}'
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
