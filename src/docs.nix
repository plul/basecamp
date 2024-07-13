{ self, pkgs, ... }:

let
  inherit (pkgs) lib;
  options-markdown = self.packages.${pkgs.system}.options-markdown;
in
{
  # Exports the option set as markdown docs
  options-markdown =
    let
      options =
        (self.eval.components {
          inherit pkgs;
          config = { };
        }).options;

      basecampPath = toString ./..;
      gitHubDeclaration = user: repo: urlRef: subpath: {
        url = "https://github.com/${user}/${repo}/blob/${urlRef}/${subpath}";
        name = "<${repo}/${subpath}>";
      };

      optionsDoc = pkgs.nixosOptionsDoc {
        options = builtins.removeAttrs options [ "_module" ];
        transformOptions =
          opt:
          opt
          // {
            declarations = map (
              dec:
              if lib.hasPrefix basecampPath (toString dec) then
                gitHubDeclaration "plul" "basecamp" "master" (
                  lib.removePrefix "/" (lib.removePrefix basecampPath (toString dec))
                )
              else
                dec
            ) opt.declarations;
          };
      };
    in
    pkgs.runCommand "basecamp-options-markdown" { } ''
      cat ${optionsDoc.optionsCommonMark} > $out
    '';

  # Builds a documentation site to document the module options
  docs = pkgs.stdenv.mkDerivation {
    name = "basecamp-docs";
    dontUnpack = true;
    buildInput = [ options-markdown ];
    nativeBuildInputs = [ pkgs.pandoc ];
    buildPhase = ''
      pandoc --from commonmark ${options-markdown} -o out.html --metadata title="Basecamp Options Reference" --standalone
    '';
    installPhase = ''
      mv out.html $out
    '';
  };
}
