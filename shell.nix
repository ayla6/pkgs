{
  nix-update,
  mkShellNoCC,
  nixfmt-tree,
}:
mkShellNoCC {
  packages = [
    nix-update
    nixfmt-tree
  ];
}
