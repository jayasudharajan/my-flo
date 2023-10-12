# Setup

1. Have ruby and gems installed. use brew or search it up to install them.

2. Install and setup cocoapods if you don't have it.
```
sudo gem install cocoapods
pod setup --verbose
```

3. Go the the project root directory and run this command to install all the dependencies.
```
pod install --verbose
```

# Localized Strings

## Setup

1. Get Twine toolkit (https://github.com/scelis/twine)
```
gem install twine
```

2. Get access to this repo: https://github.com/FloTechnologies/flo-strings

## For adding new strings

Just add the string in the https://github.com/FloTechnologies/flo-strings repo following the guidelines here https://github.com/FloTechnologies/flo-strings/blob/master/README.md

## For pulling new strings

1. Download the *strings.txt* file from the repo.

2. Run the following command to generate the localized files in iOS format. They will be updated directly in your project.
```
twine generate-all-localization-files strings.txt $FLOPATH/Flo --format apple
```

NOTE: $FLOPATH should be the path to the folder where the Flo.xcodeproj is located in your machine.

## References

* https://github.com/scelis/twine
* https://github.com/FloTechnologies/flo-strings
