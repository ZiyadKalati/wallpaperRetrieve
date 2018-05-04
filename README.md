# Wallpaper Downloader

I only know this works on Mac OS X, so this is to the Mac users.

This script downloads deviations from artists that you watch on DeviantArt.
It stores portrait images and landscape images in different folders and square images in both.
If the script is run more than once it will not re-download images it has downloaded in a previous run.
You will have to register this application in your account on DeviantArt, as this shell uses their API.

Go to DeviantArt.com and sign in. Scroll to the bottom of the page to the footer and click developers.
On the page that comes up click the green button saying "Register your Application".
Under "Application Settings", "OAuth2 Grant Type" is set to "Authorizaion Code" and in the first text box labeled "OAuth2 Redirect URI Whitelist (Required)" type in:
  
  http://localhost:8000/deviantart/auth

and then submit.

Open the credentials.json file and fill in the labeled spaces with the client_id and client_secret given to you when you completed the form on DeviantArt.

# Dependencies
jq to parse json objects

wget to download the images

ImageMagick to convert the image formats

To download them you use homebrew, which you first need to install. So type the following into the terminal:

  `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

Then type in:

  `brew install wget`
  
  `brew install jq`
  
  `brew install imagemagick`

# Arguments
There are two arguments passed to the script.
First is your DeviantArt username; this one is required.
The second is the absolute path to download the images to. This one is optional. If not supplied, the images will download to the folder with the shell script.
