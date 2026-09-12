# apm (Agent Package Manager) の CLI。コマンド名は `apm`。
# nixpkgs にも apm-cli は収録されているが、upstream のリリースから数週間遅れるため、
# nixpkgs の derivation をベースに自前で最新へ追従する。
# nixpkgs の version がこの derivation 以上へ追いついたら、このファイルと
# flake.nix の overlay を削除して nixpkgs 版へ戻す。
# ただし下記の 0.28.0 固定中はこの撤去条件を保留する (nixpkgs の 0.29.0 以降も
# 同じ退行を含むため、追いついたように見えても戻さない)。
{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "apm-cli";
  # 0.29.0 以降には、ルートに apm.yml / SKILL.md を持たない skill 集リポジトリの
  # `apm install` が "no apm.yml or SKILL.md" で失敗する退行がある
  # (microsoft/apm#2888、本リポジトリの issue #89)。修正 (microsoft/apm#2891) を含む
  # リリースが出るまで、退行前の 0.28.0 に固定する。出たら通常の bump で戻す。
  version = "0.30.0";
  pyproject = true;

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "apm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RbrqY7JampXAe3tfPnjx4FXSEi0K4b5fQ00yGeov5k8=";
  };

  # llm-github-models は nixpkgs 未収録のため依存から外す (nixpkgs と同じ措置)。
  # バージョン非依存の sed で行ごと削除し、行が見つからなくなったら (upstream が
  # 依存を落としたら) grep -q の非ゼロ終了でビルドを止めて知らせる。
  postPatch = ''
    grep -q 'llm-github-models' pyproject.toml
    sed -i '/llm-github-models/d' pyproject.toml
  '';

  build-system = with python3Packages; [
    setuptools
  ];

  # upstream の pyproject.toml の dependencies と手動同期する (llm-github-models を除く)。
  dependencies = with python3Packages; [
    click
    colorama
    filelock
    gitpython
    llm
    python-frontmatter
    pyyaml
    requests
    rich
    rich-click
    ruamel-yaml
    toml
    tomli
    tomlkit
    truststore
    watchdog
    websockets
  ];

  pythonImportsCheck = [
    "apm_cli"
  ];

  meta = {
    description = "Agent Package Manager";
    homepage = "https://github.com/microsoft/apm";
    changelog = "https://github.com/microsoft/apm/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "apm";
  };
})
