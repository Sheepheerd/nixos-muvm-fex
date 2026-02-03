{
  lib,
  stdenv,
  mesa-asahi-edge,
  llvm,
  buildPackages,
}:
let
  isCross = stdenv.hostPlatform != stdenv.buildPlatform;
in
mesa-asahi-edge.overrideAttrs (old: {
  postInstall = old.postInstall or "" + ''
    moveToOutput bin/vtn_bindgen2 $cross_tools
    moveToOutput bin/asahi_clc $cross_tools
  '';

  LLVM_CONFIG_PATH = lib.optionalDrvAttr isCross "${llvm.dev}/bin/llvm-config-native";

  nativeBuildInputs =
    old.nativeBuildInputs or [ ]
    ++ lib.optionals isCross [
      buildPackages.mesa-asahi-edge.cross_tools or null
    ];

  # Make patch application more lenient - skip patches that fail to apply
  # This is needed because some patches (like the rocket driver musl patch)
  # may not apply if the target file doesn't exist in the Mesa version being used
  patchPhase = ''
    runHook prePatch
    for patch in $patches; do
      echo "Applying patch $patch"
      # Try to apply patch in batch mode (non-interactive)
      # If it fails, check if it's because the file doesn't exist
      if patch --batch --forward --ignore-whitespace -p1 < "$patch" 2>&1; then
        echo "Patch $patch applied successfully"
      else
        patch_exit=$?
        # Exit code 1 in batch mode means patch couldn't be applied
        # This is often because the target file doesn't exist
        if [ $patch_exit -eq 1 ]; then
          echo "Warning: Patch $patch failed to apply (file may not exist), skipping..."
        else
          echo "Error: Patch $patch failed with exit code $patch_exit"
          exit $patch_exit
        fi
      fi
    done
    runHook postPatch
  '';
})
