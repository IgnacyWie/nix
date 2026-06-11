{ lib, pkgs, ... }:

let
  user = "ignacywielogorski";
  home = "/Users/${user}";
  kekaBundleId = "com.aone.keka";
  onlyofficeBundleId = "asc.onlyoffice.ONLYOFFICE";
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
  officeExtensions = [
    "csv"
    "doc"
    "docm"
    "docx"
    "dot"
    "dotm"
    "dotx"
    "fodp"
    "fods"
    "fodt"
    "key"
    "numbers"
    "odp"
    "ods"
    "odt"
    "otp"
    "ots"
    "ott"
    "pages"
    "pot"
    "potm"
    "potx"
    "pps"
    "ppsm"
    "ppsx"
    "ppt"
    "pptm"
    "pptx"
    "rtf"
    "tsv"
    "xls"
    "xlsb"
    "xlsm"
    "xlsx"
    "xlt"
    "xltm"
    "xltx"
  ];
  officeUtis = [
    "com.microsoft.excel.xls"
    "com.microsoft.powerpoint.ppt"
    "com.microsoft.powerpoint.pps"
    "com.microsoft.word.doc"
    "org.oasis-open.opendocument.presentation"
    "org.oasis-open.opendocument.presentation-template"
    "org.oasis-open.opendocument.spreadsheet"
    "org.oasis-open.opendocument.spreadsheet-template"
    "org.oasis-open.opendocument.text"
    "org.oasis-open.opendocument.text-template"
    "org.openxmlformats.presentationml.presentation"
    "org.openxmlformats.presentationml.slideshow"
    "org.openxmlformats.presentationml.template"
    "org.openxmlformats.spreadsheetml.sheet"
    "org.openxmlformats.spreadsheetml.template"
    "org.openxmlformats.wordprocessingml.document"
    "org.openxmlformats.wordprocessingml.template"
    "public.comma-separated-values-text"
    "public.rtf"
    "public.tab-separated-values-text"
  ];
  archiveDutiSettings = pkgs.writeText "keka-archive-defaults.duti" (
    lib.concatStringsSep "\n" (
      (map (extension: "${kekaBundleId} ${extension} all") archiveExtensions)
      ++ (map (uti: "${kekaBundleId} ${uti} all") archiveUtis)
    )
    + "\n"
  );
  officeDutiSettings = pkgs.writeText "onlyoffice-document-defaults.duti" (
    lib.concatStringsSep "\n" (
      (map (extension: "${onlyofficeBundleId} ${extension} all") officeExtensions)
      ++ (map (uti: "${onlyofficeBundleId} ${uti} all") officeUtis)
    )
    + "\n"
  );
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ -d /Applications/Keka.app ]; then
      echo "setting Keka as the default archive opener..."
      /usr/bin/sudo -u ${user} /usr/bin/env HOME=${home} ${pkgs.duti}/bin/duti ${archiveDutiSettings}
    else
      echo "Keka.app is not installed yet; skipping archive default handlers."
    fi

    if [ -d /Applications/ONLYOFFICE.app ]; then
      echo "setting ONLYOFFICE as the default office document opener..."
      /usr/bin/sudo -u ${user} /usr/bin/env HOME=${home} ${pkgs.duti}/bin/duti ${officeDutiSettings}
    else
      echo "ONLYOFFICE.app is not installed yet; skipping office document default handlers."
    fi
  '';
}
