#!/usr/bin/env bash
flutter packages pub run build_runner build --delete-conflicting-outputs

# git clone git@github.com:FloTechnologies/flo-strings.git
twine generate-all-localization-files flo-strings/strings.txt res/values --format jquery
bin/jquery2arb
flutter pub run gen_lang:generate --source-dir res/values
