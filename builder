#!/bin/bash

function package_recipe
{
    package_recipe="$builder_directory/recipe/$package"

    if [ ! -f "$package_recipe" ]
    then
        echo "Error: Cannot find recipe for package: $package"
        exit 1
    fi

    source "$package_recipe"
}

function package_dependency
{
    for package_dependency in $package_dependencies
    do
        if ! bash "$0" "$package_dependency"
        then
            exit 1
        fi

        package_install
    done
}

function package_archive
{
    package_archive="$builder_build/archive/$(basename "$package_address")"

    if [ ! -f "$package_archive" ]
    then
        if ! wget                              \
            --quiet                            \
            --show-progress "$package_address" \
            --output-document "$package_archive"
        then
            echo "Error: Cannot download the package archive."
            exit 1
        fi
    fi
}

function package_source
{
    package_source="$builder_build/source/$package_name-$package_version"

    if [ ! -d "$package_source" ]
    then
        mkdir "$package_source"

        tar --extract                     \
            --file "$package_archive"     \
            --directory "$package_source" \
            --strip-components="1"
    fi
}

function package_directory
{
    package_directory="$builder_build/directory/$package_name-$package_version"

    if [ ! -d "$package_directory" ]
    then
        mkdir "$package_directory"
    fi
}

function package_build
{
    package_build="$builder_build/build/$package_name-$package_version"

    if [ ! -d "$package_build" ]
    then
        mkdir "$package_build" && cd "$package_build"

        package_log do_configure
        package_log do_build
        package_log do_install
    fi
}

function package_file
{
    package_file="$builder_build/file/$package_name.tar.gz"

    if [ ! -f "$package_file" ]
    then
        tar --create                         \
            --file "$package_file"           \
            --directory "$package_directory" \
            --gzip .
    fi
}

function package_install
{
    package_install="$builder_build/file/$package_dependency.tar.gz"

    tar --extract                 \
        --file "$package_install" \
        --directory "/"
}

function package_log
{
    package_log="$builder_build/log/$package_name-$package_version"

    echo "$package_name:$package_version - $1"

    if [ ! -d "$package_log" ]
    then
        mkdir "$package_log"
    fi

    "$1" &> "$package_log/$1.log"

    if [ $? -ne 0 ]
    then
        echo "Error: The subcommand: $1 has failed."
        exit 1
    fi
}

function builder_directory
{
    builder_directory="$(realpath "$0")"
    builder_directory="$(dirname "$builder_directory")"
}

function builder_build
{
    builder_build="$builder_directory/build"

    if [ ! -d "$builder_build" ]
    then
        mkdir --parents                \
            "$builder_build/archive"   \
            "$builder_build/build"     \
            "$builder_build/directory" \
            "$builder_build/file"      \
            "$builder_build/log"       \
            "$builder_build/source"
    fi
}

function builder
{
    package="$1"

    if [ -z "$package" ]
    then
        echo "Usage: $(basename "$0") <package>"
    else
        builder_directory
        builder_build

        package_recipe
        package_dependency
        package_archive
        package_source
        package_directory
        package_build
        package_file
    fi
}

builder "$@"
