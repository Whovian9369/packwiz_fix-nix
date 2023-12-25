let
  # Import nixpkgs if needed
  pkgs = import <nixpkgs> {};
in
  { lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
    # version and vendorSha256 should be specified by the caller
    version ? "latest",
    vendorSha256,
  }:
  buildGoModule {
    pname = "packwiz";
    inherit version vendorSha256;

    src = ./..;

    nativeBuildInputs = [
      installShellFiles
    ];

    # Install shell completions
    postInstall = ''
      installShellCompletion --cmd packwiz \
        --bash <($out/bin/packwiz completion bash) \
        --fish <($out/bin/packwiz completion fish) \
        --zsh <($out/bin/packwiz completion zsh)
    '';

    meta = {
      description = "A command line tool for editing and distributing Minecraft modpacks, using a git-friendly TOML format";
      homepage = "https://packwiz.infra.link/";
      license = lib.licenses.mit;
      mainProgram = "packwiz";
    };
  }
