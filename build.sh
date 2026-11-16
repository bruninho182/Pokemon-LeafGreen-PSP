#!/usr/bin/env bash
set -euo pipefail

project="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$project/.build/FireRed-PSP"
revision=1d980c77eff6fde8ddd9fce548cf28ecbd89bc93
rom="${1:-}"

if [[ ! -f "$rom" ]]; then
    printf 'Usage: bash build.sh /path/to/LeafGreen.gba\n' >&2
    exit 1
fi
if ! printf '%s  %s\n' 7862c67bdecbe21d1d69ce082ce34327e1c6ed5e "$rom" | sha1sum --check --status; then
    printf 'Expected an English Pokémon LeafGreen revision 1 cartridge dump.\n' >&2
    exit 1
fi
if ! command -v psp-config >/dev/null; then
    printf 'Add the PSPDEV bin directory to PATH before building.\n' >&2
    exit 1
fi

mkdir -p "$source_dir"
if [[ ! -d "$source_dir/.git" ]]; then
    git -C "$source_dir" init --quiet
fi
if ! git -C "$source_dir" cat-file -e "$revision^{commit}" 2>/dev/null; then
    git -C "$source_dir" fetch --depth 1 https://github.com/JustKidding23/Pokemon-FireRed-PSP.git "$revision"
fi
git -C "$source_dir" checkout --quiet --detach "$revision"
if git -C "$source_dir" apply --check "$project/leafgreen-branding.patch" 2>/dev/null; then
    git -C "$source_dir" apply "$project/leafgreen-branding.patch"
else
    git -C "$source_dir" apply --reverse --check "$project/leafgreen-branding.patch"
fi
cp "$project/assets/ICON0.PNG" "$project/assets/PIC1.PNG" "$source_dir/psp/"
make -C "$source_dir" -j"$(nproc)" psp GAME_VERSION=LEAFGREEN GAME_REVISION=1 \
    'PSP_TITLE=Pokemon LeafGreen PSP'
mkdir -p "$project/out"
cp -R "$source_dir/build/psp32/PSP" "$project/out/"
