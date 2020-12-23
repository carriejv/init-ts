#!/bin/sh

# Initializes a new Typescript repo with a minimal config.

INITTS_REPO="https://github.com/carriejv/init-ts.git"
SPDX_LICENSE_REPO="https://raw.githubusercontent.com/spdx/license-list-data/master/text/"

T_PROMPT=`tput setaf 6`
T_STEP=`tput setaf 2`
T_ERR=`tput setaf 1`
T_RESET=`tput sgr0`

# Error handler
# error [status-code=1] [cleanup]
error() {
    echo "$1"
    if [[ ! -z "$3" ]]; then
        cd ..
        rm -rf "$3"
    fi
    exit ${2:-1}
}

# Check dependencies
MISSING_DEPS=0
for dep in sed curl npm git; do
    if ! command -v $dep>/dev/null 2>&1; then
        echo "${T_ERR}Missing required dependency [${T_RESET}${dep}${T_ERR}]."
        MISSING_DEPS=1
    fi
done
if [[ 1 -eq $MISSING_DEPS ]]; then
    error "${T_ERR}Exiting...${T_RESET}"
fi

# Make project dir and get package info

read -p "${T_PROMPT}Enter package name: ${T_RESET}" PKGNAME
if [[ -z "$PKGNAME" ]]; then
    error "${T_ERR}Package name is required. Exiting...${T_RESET}"
fi
if [[ -d "$PKGNAME" ]]; then
    error "${T_ERR}Directory [${T_RESET}${PWD}/${PKGNAME}${T_ERR}] already exists. Exiting...${T_RESET}"
fi

read -p "${T_PROMPT}Enter project description: ${T_RESET}" PKGDESC
if [[ -z "$PKGDESC" ]]; then
    error "${T_ERR}Package description is required. Exiting...${T_RESET}"
fi

read -p "${T_PROMPT}Enter project license (spdx id) [${T_RESET}Apache-2.0${T_PROMPT}]: ${T_RESET}" PKGLICENSE
PKGLICENSE=${PKGLICENSE:-"Apache-2.0"}

read -p "${T_PROMPT}Enter remote repo url (not including .git) [${T_RESET}https://github.com/carriejv/${PKGNAME}${T_PROMPT}]: ${T_RESET}" REMOTEREPO
REMOTEREPO=${REMOTEREPO:-"https://github.com/carriejv/$PKGNAME"}

read -p "${T_PROMPT}Enter developer name [${T_RESET}Carrie J V${T_PROMPT}]: ${T_RESET}" DEVNAME
DEVNAME=${DEVNAME:-"Carrie J V"}

read -p "${T_PROMPT}Enter developer email [${T_RESET}carrie@carriejv.com${T_PROMPT}]: ${T_RESET}" DEVEMAIL
DEVEMAIL=${DEVEMAIL:-"carrie@carriejv.com"}

read -p "${T_PROMPT}Enter developer website url [${T_RESET}https://www.carriejv.com${T_PROMPT}]: ${T_RESET}" DEVURL
DEVURL=${DEVURL:-"https://www.carriejv.com"}

mkdir -p "$PKGNAME"
cd "$PKGNAME"

# Clone init-ts repo.

echo "[1/5] ${T_STEP}Cloning [${T_RESET}${INITTS_REPO}${T_STEP}] into project directory...${T_RESET}"
git clone $INITTS_REPO .
mv package-template.json package.json
rm init-ts.sh
rm package-lock.json

# Generate a README and LICENSE

echo "[2/5] ${T_STEP}Generating README and LICENSE files...${T_RESET}"

echo "# $PKGNAME
TODO: Everything (literally).

# License
[$PKGLICENSE]($REMOTEREPO/blob/master/LICENSE)" > README.md

curl -sL --write-out "%{http_code}" "$SPDX_LICENSE_REPO/$PKGLICENSE.txt" > LICENSE
STATUS_CODE=$(sed -n '$p' LICENSE)
if [[ "200" != "$STATUS_CODE" ]]; then
    error "${T_ERR}Could not find license text for [${T_RESET}${PKGLICENSE}${T_ERR}] at [${T_RESET}${SPDX_LICENSE_REPO}/${PKGLICENSE}.txt${T_ERR}]. Exiting...${T_RESET}" 1 "$PKGNAME"
fi
sed -i -E 's/[1-5][0-9]{2}//gm' LICENSE
# Warn about weird licenses.
if [[ "MIT ISC BSD GPL Apache-2.0" != *"$PKGLICENSE"* ]]; then
    echo "License autofill is untested with [$PKGLICENSE]."
    echo "The script will make its best effort, but please double check!"
fi
sed -i -E "s/\<copyright holders\>|\<owner\>/$DEVNAME/gm" LICENSE
sed -i -E "s/\<year\>/$(date +'%Y')/gm" LICENSE
# Stick Apache-2.0 header on index.ts
if [[ "Apache-2.0" == "$PKGLICENSE" ]]; then
    TEMP_FILE=$(mktemp)
    echo "/**
    *  Copyright [yyyy] [name of copyright owner]
    *
    *  Licensed under the Apache License, Version 2.0 (the \"License\");
    *  you may not use this file except in compliance with the License.
    *  You may obtain a copy of the License at
    *
    *  http://www.apache.org/licenses/LICENSE-2.0
    *
    *  Unless required by applicable law or agreed to in writing, software
    *  distributed under the License is distributed on an \"AS IS\" BASIS,
    *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    *  See the License for the specific language governing permissions and
    *  limitations under the License.
    */" > "$TEMP_FILE"

    sed -i -E "s/\[name of copyright owner\]/$DEVNAME/gm" "$TEMP_FILE"
    sed -i -E "s/\[yyyy\]/$(date +'%Y')/gm" "$TEMP_FILE"
    cat src/index.ts >> "$TEMP_FILE"
    cp "$TEMP_FILE" src/index.ts
fi

# Fill in package info.

echo "[3/5] ${T_STEP}Substiting package info...${T_RESET}"
# Recursively sed subsitute provided pkg info into default files from repo.
# _sub_user_info_item key value directory
_sub_user_info_item() {
    for file in "$3"/*; do
        if [[ -d "$file" ]]; then
            _sub_user_info_item "$1" "$2" "$3/$file"
        else
            sed -i "s#%$1%#$2#gm" "$file"
        fi
    done
}

for subitem in PKGNAME PKGDESC DEVNAME DEVEMAIL DEVURL REMOTEREPO PKGLICENSE; do
    _sub_user_info_item "$subitem" "${!subitem}" .
done

# Force update npm dependencies and build + test the base repo

echo "[4/5] ${T_STEP}Updating NPM dependencies to latest and validating build/test...${T_RESET}"
npm update --save/--save-dev --force
npm run test
if [[ 0 -ne $? ]]; then
    error "${T_ERR}Encountered an error running tests. Exiting...${T_RESET}" 1 "$PKGNAME"
fi

echo "[5/5] ${T_STEP}Scrapping init-ts .git and initializing a fresh git repo...${T_RESET}"
rm -rf .git
git init
echo "This script does not make an initial commit or set the a remote repo (in case ssh, etc. access is preferred to http)."

echo "${T_STEP}Successfully initialized [${T_RESET}${PKGNAME}${T_STEP}]!${T_RESET}"
