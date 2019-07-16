#!/usr/bin/env bash

####################################################
# Parameters
####################################################
input_file_name=$1
origin_bucket=liveintent-samsclub
destination_bucket=liveaudience-uploader

download_location="$HOME/Downloads/sams-club"
unzipped_location="$download_location/unzipped"

####################################################
# Code
####################################################
set -o pipefail
. ./chalk.sh
. ./utils.sh
. ./spinner.sh
lay_traps

if [ -z $1 ]; then
    print_color redb "Please specify an input file."
    exit 1;
fi

mkdir -p $download_location
mkdir -p $unzipped_location

length=$(($(cat $input_file_name | wc -l)))

IFS=,
i=0
while read userver_id unique_segment_id name file_name terminate; do
    ((i++))
    SECONDS=0

    print_color blueb  "Processing file $file_name";
    print_color yellow "|  Unique Segment ID: $unique_segment_id";
    print_color yellow "|  File: $i out of $length";

    key=upload/$file_name
    unzipped_file_name=$(echo $file_name | sed -E 's/(.*).gz/\1/g')

    #
    # Download the file
    #
    location="s3://$origin_bucket/$key"
    print_work "Downloading file from $location"
    aws s3 cp "$location" $download_location/

    if [ $? -gt 0 ]; then
        print_color red "Unable to download $key";
        break;
    fi
    list_check "Download complete"
    echo;

    #
    # Unzip the file
    #
    print_work "Unzipping file to $unzipped_location"
    pv $download_location/$file_name | gunzip > $unzipped_location/$unzipped_file_name

    if [ $? -gt 0 ]; then
        print_color red "Unable to unzip $$download_location/$file_name";
        break;
    fi
    list_check "Unzip complete"
    echo;

    #
    # Fetch the metadata from the original file in s3
    #
    print_work "Fetching metdata from s3"
    metadata_bucket="liveintent-audience-uploader"
    metadata_bucket_key="upload/$unzipped_file_name"
    original_metadata=$(aws s3api head-object --bucket=$metadata_bucket --key=$metadata_bucket_key)

    if [ $? -gt 0 ]; then
        print_color red "Unable to fetch original metadata.";
        break;
    fi

    advertiser_id=$(echo "$original_metadata" | jq '.Metadata["advertiser-id"]' | sed 's/\"//g')
    notify=$(echo "$original_metadata" | jq '.Metadata["notify"]' | sed 's/\"//g')
    type=$(echo "$original_metadata" | jq '.Metadata["type"]' | sed 's/\"//g')
    segment_id=$(echo "$original_metadata" | jq '.Metadata["segment-id"]' | sed 's/\"//g')
    action=$(echo "$original_metadata" | jq '.Metadata["action"]' | sed 's/\"//g')

    list_check "Fetched metadata"
    echo;

    #
    # Upload the file
    #
    metadata="--metadata=advertiser-id=$advertiser_id,type=$type,segment-id=$segment_id,action=$action,unique-segment-id=$unique_segment_id"
    new_key="upload/$(date '+%Y-%m-%d')/$userver_id/$action/$(php -r ' echo bin2hex(random_bytes(12)); ')/$unzipped_file_name"

    print_work "Uploading the file to $destination_bucket"
    print_work "Will use key $new_key"
    print_work "Uploading..."

    IFS=
    aws s3 cp $unzipped_location/$unzipped_file_name s3://$destination_bucket/$new_key $metadata
    IFS=,

    if [ $? -gt 0 ]; then
        print_color red "Unable to upload the file to $destination_bucket";
        break;
    fi

    list_check "File successfully uploaded."
    print_color yellow    "|  Unique Segment ID: $unique_segment_id";
    print_color yellow    "|  File Size: $unique_segment_id";
    print_color yellow    "|  Hashes Count: $(printf %\'.f $(cat $unzipped_location/$unzipped_file_name | wc -l))";
    print_color yellow    "|  Link: https://platform.liveintent.com/campaign-manager/audiences/$unique_segment_id";
    print_color yellow    "|  Elapsed Time: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec";

    print_work "Cleaning up..."
    /bin/rm -f $download_location/$file_name
    /bin/rm -f $unzipped_location/$unzipped_file_name
    print_work "Removed temp files"
    list_check "Done"

    echo;
    echo;

    if [[ $i -gt 0 ]]; then
        break;
    fi
done < $input_file_name
