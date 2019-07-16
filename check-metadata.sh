#!/usr/bin/env bash

####################################################
# Parameters
####################################################
input_file_name=data.csv
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

mkdir -p $download_location
mkdir -p $unzipped_location

length=$(cat $input_file_name | wc -l)

IFS=,
i=0
while read userver_id unique_segment_id name file_name terminate; do
    ((i++))

    print_color blueb  "Processing file $file_name";
    print_color yellow    "|  Unique Segment ID: $unique_segment_id";
    print_color yellow -n "|  Percent Done: "; awk "BEGIN { print ($i/$length) * 100 }"

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
    metadata="--metadata 'advertiser-id=$advertiser_id,type=$type'"
    new_key="upload/$(date '+%Y-%m-%d')/$userver_id/$action/$(php -r ' echo bin2hex(random_bytes(12)); ')/$unzipped_file_name"

    print_work "Uploading the file to $destination_bucket"
    print_work "Will use key $new_key"
    print_work "Uploading..."

    aws s3 cp $unzipped_location/$unzipped_file_name s3://$destination_bucket/$new_key

    if [ $? -gt 0 ]; then
        print_color red "Unable to upload the file to $destination_bucket";
        break;
    fi

    list_check "File successfully uploaded. You can check its progress here: https://platform.liveintent.com/campaign-manager/audiences/$unique_segment_id";

    echo;
    echo;
done < $input_file_name
