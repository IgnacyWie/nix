{ lib, pkgs, ... }:

let
  user = "ignacywielogorski";
  home = "/Users/${user}";
  kekaBundleId = "com.aone.keka";
  archiveExtensions = [
    "7z"
    "ace"
    "apk"
    "ar"
    "bz2"
    "bzip2"
    "cab"
    "cb7"
    "cbr"
    "cbt"
    "cbz"
    "cpio"
    "deb"
    "ear"
    "gz"
    "gzip"
    "iso"
    "jar"
    "lha"
    "lzh"
    "lzma"
    "rar"
    "rpm"
    "tar"
    "tbz"
    "tbz2"
    "tgz"
    "tlz"
    "txz"
    "war"
    "xar"
    "xz"
    "z"
    "zip"
    "zipx"
    "zst"
  ];
  archiveUtis = [
    "com.pkware.zip-archive"
    "org.7-zip.7-zip-archive"
    "org.gnu.gnu-zip-archive"
    "public.archive"
    "public.bzip2-archive"
    "public.cpio-archive"
    "public.gzip-archive"
    "public.tar-archive"
    "public.xz-archive"
    "public.zip-archive"
  ];
  dutiSettings = pkgs.writeText "keka-archive-defaults.duti" (
    lib.concatStringsSep "\n" (
      (map (extension: "${kekaBundleId} ${extension} all") archiveExtensions)
      ++ (map (uti: "${kekaBundleId} ${uti} all") archiveUtis)
    )
    + "\n"
  );
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ -d /Applications/Keka.app ]; then
      echo "setting Keka as the default archive opener..."
      /usr/bin/sudo -u ${user} /usr/bin/env HOME=${home} ${pkgs.duti}/bin/duti ${dutiSettings}
    else
      echo "Keka.app is not installed yet; skipping archive default handlers."
    fi
  '';
}
