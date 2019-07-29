#!/bin/bash


# generate list of source files and do a little conversion to jumpstart the destination list
srcList=()

dstList=()

# list of tokens to remove
remList=( "_" "Sleeklens-" "SleeklensStarter-" "Base-" "AllInOne-" "Tone-" "Polish-" "Exposure-" "Tint-" \
          "Vintage-" "Black&White-" "ColorCorrect-" "Toners-" "AllinOne-" )


SRCDIR="./xmpPresets/"
DSTDIR="../phixer/Config/Presets/"

# these are global because bash doesn't support return values in functions (!)
filename=""
dir=""


#---------------------------------
# updates global filename var
function cleanupFilename() {

    # remove spaces
    filename=${filename//[[:space:]]/}

    filename=${filename//Exposure-1/ExposureMinus1}

      # replace unwanted strings
      for str in ${remList[@]}; do
          filename=${filename//$str/}
      done

      # get rid of N- and prefixes
      if [[ "$filename" =~ ^[0-9]-.*  ]]; then
          filename=${filename:2:${#filename}}
      fi

      # get rid of N.NN- prefixes
      if [[ "$filename" =~ ^[0-9].[0-9][0-9]-.*  ]]; then
          filename=${filename:5:${#filename}}
      fi

      #return $filename
 }

#---------------------------------
function outputCommand() {
    echo "python convertXMP.py \"$1\" \"$2\""
}


#---------------------------------
# Main Program
#---------------------------------


# get the list of input files
while IFS=  read -r -d $'\0'; do
    srcList+=("$REPLY")
done < <(find ${SRCDIR} -name "*.xmp" -print0 | sort -z)

echo "#!/bin/bash"
echo ""

prevdir=""

# loop through./xmpPresets file list
for i in ${!srcList[@]}; do
    # extract the filename without directories or extension
    path="${srcList[$i]}"

    filename="${path##*/}"
    filename="${filename%.*}"

    # create output directory path
    dir="${path%/*}"
    dir=${dir/${SRCDIR}/${DSTDIR}}

    # insert newline tag if directory changes
    srcdir="${path%/*}"
    if [[ "$srcdir" != "$prevdir"  ]]; then
        dstList+=("##")
        prevdir=$srcdir
        printf '\n'
    fi

    # replace unwanted strings
    cleanupFilename

     # ignore if name begins and ends with "--"
     if [[ "$filename" =~ "--"  ]]; then
         echo "# Ignoring: " $filename
         continue
     fi

     # append to dstList for later processing
     dstList+=("${filename}")

     outputCommand "${srcList[$i]}" "${dir}/${filename}.json"

done

# loop through the destination list and create the associated JSON

# start bash block comment:
printf "\n\n\n: <<'JSON_END'\n\n"

printf "# Copy the following JSON to the config file.\n"
printf "# You'll need to manually fix titles and organise into categories\n\n\n"

# preset definitions:
for i in ${!dstList[@]}; do
    key="${dstList[$i]}"
    if [[ $key == '##' ]]; then
        printf '\n'
    else

        # create a title by inserting spaces before capital letters
        title="$(echo ${key} | sed -e 's/\([^[:blank:]]\)\([[:upper:]]\)/\1 \2/g')"
        # fix known issues
        title=${title//- /-}
        title=${title//( /(}
        title=${title//& /&}
        printf '{ "key": "%s",  "title": "%s", "slow": false, "show": true, "rating": 0 },\n' "${key}" "${title}"
    fi
done

# category list (just put in one for now):
printf '            {"key": "allpresets",\n'
printf '            "title": "Presets: All",\n'
printf '            "filters": [\n'
printf '                        '
for i in ${!dstList[@]}; do
    key="${dstList[$i]}"
    if [[ $key == '##' ]]; then
        printf '\n'
        printf '\n'
    else
        printf '"%s", ' "${key}"
        if [[ $(($i%8)) == 0 ]] ; then
            printf '\n'
        fi
    fi
done
printf '                       ]\n'
printf '        },\n'


# end bash block comment:
printf "\nJSON_END\n"
