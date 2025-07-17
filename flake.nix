{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  };

  outputs = { self, nixpkgs }: let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
    packages.x86_64-linux.gnucash =
      nixpkgs.legacyPackages.x86_64-linux.gnucash.overrideAttrs (prevAttrs: {
        patches = (prevAttrs.patches or []) ++ [
          ./python-env.patch
         ];
        cmakeFlags = [
          "-DWITH_PYTHON=\"ON\""
          "-DPYTHON_SYSCONFIG_BUILD=\"$out\""
        ];
        buildInputs = prevAttrs.buildInputs ++ (with pkgs; [
          python3
        ]);
        postPatch = ''
          substituteInPlace bindings/python/__init__.py \
          --subst-var-by gnc_dbd_dir "${pkgs.libdbiDrivers}/lib/dbd" \
          --subst-var-by gsettings_schema_dir ${pkgs.glib.makeSchemaPath "$out" "gnucash-${prevAttrs.version}"};
        '';
      });

    packages.x86_64-linux.default = self.packages.x86_64-linux.gnucash;
    packages.x86_64-linux.pymodule = pkgs.python3Packages.toPythonModule self.packages.x86_64-linux.gnucash;
    packages.x86_64-linux.import = pkgs.python3Packages.buildPythonApplication rec {
      pname = "gnucash-qif-import";
      version = "0.1";
      src = /home/steved/pkgs/gnucash-qif-import/gnucash-qif-import3;
      format = "other";
      propagatedBuildInputs = [ self.outputs.packages.x86_64-linux.pymodule ];
      installPhase = ''
        mkdir -p $out/bin
        cp qif.py import.py $out/bin
      '';
    };

  };
}

# vim: set ts=2 sw=2 et sta:
