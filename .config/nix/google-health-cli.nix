# Google Health CLI (コマンド名 ghealth)。
# Google Health API v4 の CLI。nixpkgs 未収録。
# upstream にタグ付きリリースが無いため、main ブランチの特定コミットに pin する。
#
# バージョンを上げる場合 (deno task bump:google-health-cli が下記 1〜3 を自動で行う):
#   1. main ブランチの HEAD コミットを解決し rev を更新する。
#   2. fetchFromGitHub の hash を nix flake prefetch で取得する。
#   3. version をコミット日時から 0-unstable-YYYY-MM-DD 形式で更新する。
#   4. vendorHash は go.mod / go.sum が変わったときのみずれる。ビルドエラーの
#      got: に出る hash へ手動で更新する。
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule {
  pname = "google-health-cli";
  version = "0-unstable-2026-07-10";

  src = fetchFromGitHub {
    owner = "Google-Health-API";
    repo = "google-health-cli";
    rev = "9cf02743d9ca051500b7c1c181eb88a9ae8988a5";
    hash = "sha256-InH3mYQT1TuyNKzvXKiD7XmKG08a8CODUbj6EhLdJJE=";
  };

  vendorHash = "sha256-rXAoAIis/4bhzDVswVfqpWdwFN72UOGKxUcA1fbCcAo=";

  meta = {
    description = "CLI for the Google Health API v4";
    homepage = "https://github.com/Google-Health-API/google-health-cli";
    license = lib.licenses.asl20;
    mainProgram = "ghealth";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
