#!/usr/bin/env python
# ref: https://galaxyproject.org/admin/tools/data-managers/how-to/define/

# Rewritten by H.E. Cicada Brokaw Dennis from a source downloaded from the toolshed and
# other example code on the web.
# This now allows downloading of a user selected library
# but only from the CTAT Genome Resource Library website.
# Ultimately we might want to allow the user to specify any location 
# from which to download.
# Users can create or download other libraries and use this tool to add them if they don't want
# to add them by hand.

import argparse
import os
#import tarfile
#import urllib
import subprocess

# Comment out the following line when testing without galaxy package.
from galaxy.util.json import to_json_string
# The following is not being used, but leaving as info
# in case we ever want to get input values using json.
# from galaxy.util.json import from_json_string

# datetime.now() is used to create the unique_id
from datetime import datetime

# The FileListParser is used by get_ctat_genome_filenames(),
# which is called by the Data Manager interface (.xml file) to get
# the filenames that are available online at broadinstitute.org
# Not sure best way to do it. 
# This object uses HTMLParser to look through the html 
# searching for the filenames within anchor tags.
import urllib2
from HTMLParser import HTMLParser

_CTAT_ResourceLib_URL = 'https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/'
_CTAT_MutationIndex_URL = 'https://data.broadinstitute.org/Trinity/CTAT/mutation/'
_CTAT_Build_dirname = 'ctat_genome_lib_build_dir'
_CTAT_ResourceLib_DisplayNamePrefix = 'CTAT_GenomeResourceLib_'
_CTAT_ResourceLib_DefaultGenome = 'Unspecified_Genome'
_CTAT_HumanFusionLib_FilenamePrefix = 'CTAT_HumanFusionLib'
_CTAT_RefGenome_Filename = 'ref_genome.fa'
_CTAT_MouseGenome_Prefix = 'Mouse'
_CTAT_HumanGenome_Prefix = 'GRCh'
_NumBytesNeededForBuild = 66571993088 # 62 Gigabytes. FIX - This might not be correct.
_NumBytesNeededForIndexes = 21474836480 # 20 Gigabytes. FIX - This might not be correct.
_Download_TestFile = "write_testfile.txt"
_DownloadSuccessFile = 'download_succeeded.txt'
_LibBuiltSuccessFile = 'build_succeeded.txt'
_MutationDownloadSuccessFile = 'mutation_index_download_succeeded.txt'

class FileListParser(HTMLParser):
    def __init__(self):
        # Have to use direct call to super class rather than using super():
        # super(FileListParser, self).__init__()
        # because HTMLParser is an "old style" class and its inheritance chain does not include object.
        HTMLParser.__init__(self)
        self.urls = set()
    def handle_starttag(self, tag, attrs):
        # Look for filename references in anchor tags and add them to urls.
        if tag == "a":
            # The tag is an anchor tag.
            for attribute in attrs:
                # print "Checking: {:s}".format(str(attribute))
                if attribute[0] == "href":
                    # Does the href have a tar.gz in it?
                    if ("tar.gz" in attribute[1]) and ("md5" not in attribute[1]):
                        # Add the value to urls.
                        self.urls.add(attribute[1])            
# End of class FileListParser

def get_ctat_genome_urls():
    # open the url and retrieve the urls of the files in the directory.
    resource = urllib2.urlopen(_CTAT_ResourceLib_URL)
    theHTML = resource.read()
    filelist_parser = FileListParser()
    filelist_parser.feed(theHTML)
    # For dynamic options need to return an interable with contents that are tuples with 3 items.
    # Item one is a string that is the display name put into the option list.
    # Item two is the value that is put into the parameter associated with the option list.
    # Item three is a True or False value, indicating whether the item is selected.
    options = []
    for i, url in enumerate(filelist_parser.urls):
        # The urls should look like: 
        # https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/GRCh37_v19_CTAT_lib_Feb092018.plug-n-play.tar.gz
        # https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/Mouse_M16_CTAT_lib_Feb202018.source_data.tar.gz
        # But in actuality, they are coming in looking like:
        # GRCh37_v19_CTAT_lib_Feb092018.plug-n-play.tar.gz
        # Mouse_M16_CTAT_lib_Feb202018.source_data.tar.gz
        # Write code to handle both situations, or an ftp: url.
        if (url.split(":")[0] == "http") or (url.split(":")[0] == "https") or (url.split(":")[0] == "ftp"):
            full_url_path = url
        else:
            # Assume the path is relative to the page location.
            full_url_path = "{:s}/{:s}".format(_CTAT_ResourceLib_URL, url)
        filename = url.split("/")[-1]
        # if filename.split("_")[0] != _CTAT_MouseGenome_Prefix:
        #     # Don't put in the mouse genome options for now.
        #     # The mouse genome option is not handled correctly yet
        #     options.append((filename, full_url_path, i == 0))
        # Mouse genomes should work now (we hope) - FIX - still not tested.
        options.append((filename, full_url_path, i == 0))
    options.sort() # So the list will be in alphabetical order.
    # return a tuple of the urls
    print "The list being returned as options is:"
    print "{:s}\n".format(str(options))
    return options

def get_mutation_index_urls():
    # open the url and retrieve the urls of the files in the directory.
    resource = urllib2.urlopen(_CTAT_MutationIndex_URL)
    theHTML = resource.read()
    filelist_parser = FileListParser()
    filelist_parser.feed(theHTML)
    # For dynamic options need to return an interable with contents that are tuples with 3 items.
    # Item one is a string that is the display name put into the option list.
    # Item two is the value that is put into the parameter associated with the option list.
    # Item three is a True or False value, indicating whether the item is selected.
    options = []
    for i, url in enumerate(filelist_parser.urls):
        # The urls should look like: 
        # https://data.broadinstitute.org/Trinity/CTAT/mutation/mc7.tar.gz
        # https://data.broadinstitute.org/Trinity/CTAT/mutation/hg19.tar.gz
        # But in actuality, they are coming in looking like:
        # hg19.tar.gz
        # mc7.tar.gz
        # Write code to handle both situations, or an ftp: url.
        if (url.split(":")[0] == "http") or (url.split(":")[0] == "https") or (url.split(":")[0] == "ftp"):
            full_url_path = url
        else:
            # Assume the path is relative to the page location.
            full_url_path = "{:s}/{:s}".format(_CTAT_MutationIndex_URL, url)
        filename = url.split("/")[-1]
        options.append((filename, full_url_path, i == 0))
    options.sort() # So the list will be in alphabetical order.
    # return a tuple of the urls
    print "The list being returned as options is:"
    print "{:s}\n".format(str(options))
    return options

# The following was used by the example program to get input parameters through the json.
# Just leaving here for reference.
# We are getting all of our parameter values through command line arguments.
#def get_reference_id_name(params):
#    genome_id = params['param_dict']['genome_id']
#    genome_name = params['param_dict']['genome_name']
#    return genome_id, genome_name
#
#def get_url(params):
#    trained_url = params['param_dict']['trained_url']
#    return trained_url

# The following procedure is used to help with debugging and for user information.
def print_directory_contents(dir_path, num_levels):
    if num_levels > 0:
        if os.path.exists(dir_path) and os.path.isdir(dir_path):
            print "\nDirectory {:s}:".format(dir_path)
            subprocess.call("ls -la {:s} 2>&1".format(dir_path), shell=True)
        else:
            print "Path either does not exist, or is not a directory:\n\t{:s}.".format(dir_path)
    if num_levels > 1:
        if os.path.exists(dir_path) and os.path.isdir(dir_path):
            for filename in os.listdir(dir_path):
                filename_path = "{:s}/{:s}".format(dir_path, filename)
                if os.path.exists(filename_path) and os.path.isdir(filename_path):
                    print_directory_contents(filename_path, num_levels-1)
        else:
            print "Path either does not exist, or is not a directory:\n\t{:s}.".format(dir_path)

def download_from_BroadInst(source, destination, force_download):
    # Input Parameters
    # source is the full URL of the file we want to download.
    #     It should look something like:
    #     https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/GRCh37_v19_CTAT_lib_Feb092018.plug-n-play.tar.gz
    # destination is the location where the source file will be unarchived.
    #     Relative paths are expanded using the current working directory, so within Galaxy,
    #     it is best to send in absolute fully specified path names so you know to where
    #     the source file going to be extracted.
    # force_download will cause a new download and extraction to occur, even if the destination
    #     has a file in it indicating that a previous download succeeded.
    #
    # Returns the following:
    # return (downloaded_directory, download_has_source_data, genome_build_directory, lib_was_downloaded)
    # downloaded_directory
    #     The directory which was created as a subdirectory of the destination directory
    #     when the download occurred, or if there was no download, 
    #     possibly the same directory as destination, if that is where the data resides.
    # download_has_source_data
    #     Is a boolean indicating whether the source file was "source_data" or was "plug-n-play".
    # genome_build_directory
    #     The directory where the genome resource library is or where it should be built. 
    #     It can be the same as the downloaded directory, but is sometimes a subdirectory of it.
    # lib_was_downloaded
    #     Since it doesn't always do the download, the function returns whether download occurred.
    lib_was_downloaded = False
    if len(source.split(":")) == 1:
        # Then we were given a source_url without a leading https: or similar.
        # Assume we only were given the filename and that it exists at _CTAT_ResourceLib_URL.
        source = "{:s}/{:s}".format(_CTAT_ResourceLib_URL, source)
    # else we might want to check that it is one of "http", "ftp", "file" or other accepted url starts.
    
    print "In download_from_BroadInst(). The source_url is:\n\t{:s}".format(str(source))

    # Get the root filename of the Genome Directory.
    src_filename = source.split("/")[-1]
    root_genome_dirname = src_filename.split(".")[0]
    # If the src_filename indicates it is a source file, as opposed to plug-n-play, 
    # then we may need to do some post processing on it.
    type_of_download = src_filename.split(".")[1]
    print "The file to be extracted is {:s}".format(src_filename)
    print "The type of download is {:s}".format(type_of_download)
    download_has_source_data = (type_of_download == "source_data")

    # We want to make sure that destination is absolute fully specified path.
    cannonical_destination = os.path.realpath(destination)
    if os.path.exists(cannonical_destination):
        if not os.path.isdir(cannonical_destination):
            raise ValueError("The destination is not a directory: " + \
                             "{:s}".format(cannonical_destination))
        # else all is good. It is a directory.
    else:
        # We need to create it.
        try:
            os.makedirs(cannonical_destination)
        except os.error:
            print "ERROR: Trying to create the following directory path:"
            print "\t{:s}".format(cannonical_destination)
            raise

    # Make sure the directory now exists and we can write to it.
    if not os.path.exists(cannonical_destination):
        # It should have been created, but if it doesn't exist at this point
        # in the code, something is wrong. Raise an error.
        raise OSError("The destination directory could not be created: " + \
                      "{:s}".format(cannonical_destination))
    test_writing_file = "{:s}/{:s}.{:s}".format(cannonical_destination, root_genome_dirname, _Download_TestFile)
    try:
        filehandle = open(test_writing_file, "w")
        filehandle.write("Testing writing to this file.")
        filehandle.close()
        os.remove(test_writing_file)
    except IOError:
        print "The destination directory could not be written into: " + \
                      "{:s}".format(cannonical_destination)
        raise
    
    # Get the list of files in the directory,
    # We use it to check for a previous download or extraction among other things.
    orig_files_in_destdir = set(os.listdir(cannonical_destination))
    # See whether the file has been downloaded already.
    # FIX - Try looking one or two directories above, as well as current directory,
    #     and maybe one directory below,
    #     for the download success file? 
    #     Not sure about this though...
    download_success_file = "{:s}.{:s}".format(root_genome_dirname, _DownloadSuccessFile)
    download_success_file_path = "{:s}/{:s}".format(cannonical_destination, download_success_file)
    if ((download_success_file not in orig_files_in_destdir) \
        or (root_genome_dirname not in orig_files_in_destdir) \
        or force_download):
        # Check whether there is enough space on the device for the library.
        statvfs = os.statvfs(cannonical_destination)
        # fs_size = statvfs.f_frsize * statvfs.f_blocks          # Size of filesystem in bytes
        # num_free_bytes = statvfs.f_frsize * statvfs.f_bfree    # Actual number of free bytes
        num_avail_bytes = statvfs.f_frsize * statvfs.f_bavail    # Number of free bytes that ordinary users
                                                                 # are allowed to use (excl. reserved space)
        if (num_avail_bytes < _NumBytesNeededForBuild):
            raise OSError("There is insufficient space ({:s} bytes)".format(str(num_avail_bytes)) + \
                          " on the device of the destination directory: " + \
                          "{:s}".format(cannonical_destination))
    
        #Previous code to download and untar. Not using anymore.
        #full_filepath = os.path.join(destination, src_filename)
        #
        #Download ref: https://dzone.com/articles/how-download-file-python
        #f = urllib2.urlopen(source)
        #data = f.read()
        #with open(full_filepath, 'wb') as code:
        #    code.write(data)
        #
        #Another way to download:
        #try: 
        #    urllib.urlretrieve(url=source, filename=full_filepath)
        #
        #Then untar the file.
        #try: 
        #    tarfile.open(full_filepath, mode='r:*').extractall()
    
        if (download_success_file in orig_files_in_destdir):
            # Since we are redoing the download, 
            # the success file needs to be removed
            # until the download has succeeded.
            os.remove(download_success_file_path)
        # We want to transfer and untar the file without storing the tar file, because that
        # adds all that much more space to the needed amount of free space on the disk.
        # Use subprocess to pipe the output of curl into tar.
        command = "curl --silent {:s} | tar -xzf - -C {:s}".format(source, cannonical_destination)
        try: # to send the command that downloads and extracts the file.
            command_output = subprocess.check_output(command, shell=True)
            # FIX - not sure check_output is what we want to use. If we want to have an error raised on
            # any problem, maybe we should not be checking output.
        except subprocess.CalledProcessError:
            print "ERROR: Trying to run the following command:\n\t{:s}".format(command)
            raise
        else:
            lib_was_downloaded = True

    # Some code to help us if errors occur.
    print "\n*******************************\nFinished download and extraction."
    print_directory_contents(cannonical_destination, 2)
    print "*******************************\n"
    
    newfiles_in_destdir = set(os.listdir(cannonical_destination)) - orig_files_in_destdir
    if (root_genome_dirname not in newfiles_in_destdir):
        # Perhaps it has a different name than what we expected it to be.
        # It will be the file that was not in the directory
        # before we did the download and extraction.
        found_filename = None
        if len(newfiles_in_destdir) == 1:
            found_filename = newfiles_in_destdir[0]
        else:
            for filename in newfiles_in_destdir:
                # In most cases, there will only be one new file, but some OS's might have created
                # other files in the directory.
                # Look for the directory that was downloaded and extracted.
                # The correct file's name should be a substring of the tar file that was downloaded.
                if filename in src_filename:
                    found_filename = filename
        if found_filename is not None:
            root_genome_dirname = found_filename

    downloaded_directory = "{:s}/{:s}".format(cannonical_destination, root_genome_dirname)

    if (os.path.exists(downloaded_directory)):
        try:
            # Create a file to indicate that the download succeeded.
            subprocess.check_call("touch {:s}".format(download_success_file_path), shell=True)
        except IOError:
            print "The download_success file could not be created: " + \
                      "{:s}".format(download_success_file_path)
            raise
        # Look for the build directory, or specify the path where it should be placed.
        if len(os.listdir(downloaded_directory)) == 1:
            # Then that one file is a subdirectory that should be the downloaded_directory.
            # That is how the plug-n-play directories are structured.
            subdir_filename = os.listdir(downloaded_directory)[0]
            genome_build_directory = "{:s}/{:s}".format(downloaded_directory, subdir_filename)
        else:
            # In this case, we have source_data in the directory. The default will be to create
            # the build directory in the downloaded_directory with the default _CTAT_Build_dirname.
            # In this case, this directory will not exist yet until the library is built.
            genome_build_directory = "{:s}/{:s}".format(downloaded_directory, _CTAT_Build_dirname)
    else:
        raise ValueError("ERROR: Could not find the extracted file in the destination directory:" + \
                             "\n\t{:s}".format(cannonical_destination))

    return (downloaded_directory, download_has_source_data, genome_build_directory, lib_was_downloaded)
        
def gmap_the_library(genome_build_directory):
        # This is the processing that needs to happen for gmap-fusion to work.
        # genome_build_directory should normally be a fully specified path, 
        # though this function should work even if it is relative.
        # The command prints messages out to stderr, even when there is not an error,
        # so route stderr to stdout. Otherwise, galaxy thinks an error occurred.
        command = "gmap_build -D {:s}/ -d ref_genome.fa.gmap -k 13 {:s}/ref_genome.fa 2>&1".format( \
                  genome_build_directory, genome_build_directory)
        try: # to send the gmap_build command.
            command_output = subprocess.check_output(command, shell=True)
        except subprocess.CalledProcessError:
            print "ERROR: While trying to run the gmap_build command on the library:\n\t{:s}".format(command)
            raise
        finally:
            # Some code to help us if errors occur.
            print "\n*******************************\nAfter running gmap_build."
            print_directory_contents(genome_build_directory, 2)
            print "*******************************\n"

def download_mutation_indexes(source_url, genome_build_directory, force_download):
    print "\n*****************************************************************"
    print "* The real mutation indexes have not yet been created. Just testing. *"
    print "*****************************************************************\n"
    # It is assumed that this procedure is only called with a valid genome_build_directory.
    # No checks are made to see whether it exists, whether we can write to it, etc.
    index_was_downloaded = False
    if len(source_url.split(":")) == 1:
        # Then we were given a source_url without a leading https: or similar.
        # Assume we only were given the filename and that it exists at _CTAT_MutationIndex_URL.
        source_url = "{:s}/{:s}".format(_CTAT_MutationIndex_URL, source_url)
    
    print "In download_mutation_indexes(). The source_url is:\n\t{:s}".format(str(source_url))

    # Get the root filename of the Genome Directory.
    src_filename = source.split("/")[-1]
    root_genome_dirname = src_filename.split(".")[0]
    print "The mutation index file to be downloaded and extracted is {:s}".format(src_filename)

    # Get the list of files in the directory,
    # We use it to check for a previous download or extraction among other things.
    orig_files_in_destdir = set(os.listdir(genome_build_directory))
    # See whether the index file has been downloaded already.
    download_success_file = "{:s}.{:s}".format(root_genome_dirname, _MutationDownloadSuccessFile)
    download_success_file_path = "{:s}/{:s}".format(genome_build_directory, download_success_file)
    if ((download_success_file not in orig_files_in_destdir) or force_download):
        # Check whether there is enough space on the device for the library.
        statvfs = os.statvfs(genome_build_directory)
        # fs_size = statvfs.f_frsize * statvfs.f_blocks          # Size of filesystem in bytes
        # num_free_bytes = statvfs.f_frsize * statvfs.f_bfree    # Actual number of free bytes
        num_avail_bytes = statvfs.f_frsize * statvfs.f_bavail    # Number of free bytes that ordinary users
                                                                 # are allowed to use (excl. reserved space)
        if (num_avail_bytes < _NumBytesNeededForIndexes):
            raise OSError("There is insufficient space ({:s} bytes)".format(str(num_avail_bytes)) + \
                          " for the indexes on the device of the destination directory: " + \
                          "{:s}".format(cannonical_destination))
        if (download_success_file in orig_files_in_destdir):
            # Since we are redoing the download, 
            # the success file needs to be removed
            # until the download has succeeded.
            os.remove(download_success_file_path)
        # We want to transfer and untar the file without storing the tar file, because that
        # adds all that much more space to the needed amount of free space on the disk.
        # Use subprocess to pipe the output of curl into tar.
        command = "curl --silent {:s} | tar -xzf - -C {:s}".format(source_url, genome_build_directory)
        try: # to send the command that downloads and extracts the file.
            command_output = subprocess.check_output(command, shell=True)
            # FIX - not sure check_output is what we want to use. If we want to have an error raised on
            # any problem, maybe we should not be checking output.
        except subprocess.CalledProcessError:
            print "ERROR: Trying to run the following command:\n\t{:s}".format(command)
            raise
        else:
            index_was_downloaded = True
    # Some code to help us if errors occur.
    print "/n*********************************************************"
    print "* Finished download and extraction of Mutation Indexes. *"
    print_directory_contents(genome_build_directory, 2)
    print "*********************************************************\n"
    try:
        # Create a file to indicate that the download succeeded.
        subprocess.check_call("touch {:s}".format(download_success_file_path), shell=True)
    except IOError:
        print "The download_success file could not be created: " + \
                    "{:s}".format(download_success_file_path)
        raise
    return index_was_downloaded

def build_the_library(genome_source_directory, genome_build_directory, build, gmap_build):
    """ genome_source_directory is the location of the source_data needed to build the library.
            Normally it is fully specified, but could be relative.
        genome_build_directory is the location where the library will be built.
            It can be relative to the current working directory or an absolute path.
        build specifies whether to run prep_genome_lib.pl even if it was run before.
        gmap_build specifies whether to run gmap_build or not.

        Following was the old way to do it. Before FusionFilter 0.5.0.
        prep_genome_lib.pl \
           --genome_fa ref_genome.fa \
           --gtf ref_annot.gtf \
           --blast_pairs blast_pairs.gene_syms.outfmt6.gz \
           --fusion_annot_lib fusion_lib.dat.gz
           --output_dir ctat_genome_lib_build_dir
        index_pfam_domain_info.pl  \
            --pfam_domains PFAM.domtblout.dat.gz \
            --genome_lib_dir ctat_genome_lib_build_dir
        gmap_build -D ctat_genome_lib_build_dir -d ref_genome.fa.gmap -k 13 ctat_genome_lib_build_dir/ref_genome.fa"
    """

    # Get the root filename of the Genome Directory.
    src_filename = genome_source_directory.split("/")[-1]
    root_genome_dirname = src_filename.split(".")[0]
    print "Building the CTAT Genome Resource Library from source data at:\n\t{:s}".format(genome_source_directory)
    # See whether the library has been built already. The success file is written into the source directory.
    files_in_sourcedir = set(os.listdir(genome_source_directory))
    build_success_file = "{:s}.{:s}".format(root_genome_dirname, _LibBuiltSuccessFile)
    build_success_file_path = "{:s}/{:s}".format(genome_source_directory, build_success_file)
    if (genome_source_directory != "" ) and \
        ((build_success_file not in files_in_sourcedir) or build):
        if os.path.exists(genome_source_directory):
            os.chdir(genome_source_directory)
            if (build_success_file in files_in_sourcedir):
                # Since we are redoing the build, 
                # the success file needs to be removed
                # until the build has succeeded.
                os.remove(build_success_file_path)
            # Create the command that builds the Genome Resource Library form the source data.
            command = "prep_genome_lib.pl --genome_fa ref_genome.fa --gtf ref_annot.gtf " + \
                      "--pfam_db PFAM.domtblout.dat.gz " + \
                      "--output_dir {:s} ".format(genome_build_directory)
            found_HumanFusionLib = False
            HumanFusionLib_filename = "NoFileFound"
            for filename in os.listdir(genome_source_directory):
                # At the time this was written, the filename was CTAT_HumanFusionLib.v0.1.0.dat.gz
                # We only check the prefix, in case other versions are used later.
                # I assume there is only one in the directory, but if there are more than one, 
                # the later one, alphabetically, will be used.
                if filename.split(".")[0] == _CTAT_HumanFusionLib_FilenamePrefix:
                    found_HumanFusionLib = True
                    filename_of_HumanFusionLib = filename
            if found_HumanFusionLib:
                # The mouse genomes do not have a fusion_annot_lib
                # so only add the following for Human genomes.
                command += "--fusion_annot_lib {:s} ".format(filename_of_HumanFusionLib) + \
                           "--annot_filter_rule AnnotFilterRule.pm "
            if gmap_build:
                command += "--gmap_build "
            # Send stderr of the command to stdout, because some functions may write to stderr,
            # even though no error has occurred. We will depend on error code return in order
            # to know if an error occurred.
            command += " 2>&1"
            print "About to run the following command:\n\t{:s}".format(command)
            try: # to send the prep_genome_lib command.
                command_output = subprocess.check_call(command, shell=True)
            except subprocess.CalledProcessError:
                print "ERROR: While trying to run the prep_genome_lib.pl command " + \
                    "on the CTAT Genome Resource Library:\n\t{:s}".format(command)
                raise
            finally:
                # Some code to help us if errors occur.
                print "\n*******************************"
                print "Contents of Genome Source Directory {:s}:".format(genome_source_directory)
                print_directory_contents(genome_source_directory, 2)
                print "\nContents of Genome Build Directory {:s}:".format(genome_build_directory)
                print_directory_contents(genome_build_directory, 2)
                print "*******************************\n"
        else:
            raise ValueError("Cannot build the CTAT Genome Resource Library. " + \
                "The source directory does not exist:\n\t{:s}".format(genome_source_directory))
    elif gmap_build:
        gmap_the_library(genome_build_directory)
    try:
        # Create a file to indicate that the build succeeded.
        subprocess.check_call("touch {:s}".format(build_success_file_path), shell=True)
    except IOError:
        print "The download_success file could not be created: " + \
                    "{:s}".format(build_success_file_path)
        raise

def search_for_genome_build_dir(top_dir_path):
    # If we do not download the directory, the topdir_path could be the
    # location of the genome resource library, but we also want to allow the
    # user to give the same value for top_dir_path that they do when a
    # build happens, so we need to handle all three cases:
    # 1) Is the top_dir_path the build directory,
    # 2) or is it inside of the given directory, 
    # 3) or is it inside a subdirectory of the given directory.
    # The source_data downloads are built to a directory named _CTAT_Build_dirname,
    # and the plug-n-play downloads contain a sub-directory named _CTAT_Build_dirname.
    # We also look for the genome name and return that, if we find it in the
    # directory name of the directory holding the build directory.
    top_dir_full_path = os.path.realpath(top_dir_path)
    genome_build_directory = None
    genome_name_from_dirname = None
    print_warning = False

    if not os.path.exists(top_dir_full_path):
        raise ValueError("Cannot find the CTAT Genome Resource Library. " + \
            "The given directory does not exist:\n\t{:s}".format(top_dir_full_path))
    elif not os.path.isdir(top_dir_full_path):
        raise ValueError("Cannot find the CTAT Genome Resource Library. " + \
            "The given directory is not a directory:\n\t{:s}".format(top_dir_full_path))
    if top_dir_full_path.split("/")[-1] == _CTAT_Build_dirname:
        print "Build directory is: {:s}".format(top_dir_full_path)
        # The top_dir_path is the path to the genome_build_directory.
        genome_build_directory = top_dir_full_path
    else:
        # Look for it inside of the top_dir_path directory.
        print "Looking inside of: {:s}".format(top_dir_full_path)
        top_dir_contents = os.listdir(top_dir_full_path)
        if (_CTAT_Build_dirname in top_dir_contents):
            # The genome_build_directory is inside of the top_dir_path directory.
            print "1. Found it."
            genome_build_directory = "{:s}/{:s}".format(top_dir_full_path,_CTAT_Build_dirname)
        else:
            # Find all subdirectories containing the _CTAT_Build_dirname or the _CTAT_RefGenome_Filename.
            # Look down the directory tree two levels.
            build_dirs_in_subdirs = list()
            subdirs_with_genome_files = list()
            build_dirs_in_sub_subdirs = list()
            sub_subdirs_with_genome_files = list()
            subdirs = [entry for entry in top_dir_contents if (os.path.isdir("{:s}/{:s}".format(top_dir_full_path,entry)))]
            for subdir in subdirs:
                subdir_path = "{:s}/{:s}".format(top_dir_full_path, subdir)
                subdir_path_contents = os.listdir(subdir_path)
                # print "Is it one of:\n\t" + "\n\t".join(subdir_path_contents)
                if (_CTAT_Build_dirname in subdir_path_contents):
                    # The genome_build_directory is inside of the subdir_path directory.
                    print "2a, Found one."
                    build_dirs_in_subdirs.append("{:s}/{:s}".format(subdir_path, _CTAT_Build_dirname))
                if (_CTAT_RefGenome_Filename in subdir_path_contents):
                    subdirs_with_genome_files.append(subdir_path)
                # Since we are already looping, loop through all dirs one level deeper as well.
                sub_subdirs = [entry for entry in subdir_path_contents if (os.path.isdir("{:s}/{:s}".format(subdir_path,entry)))]
                for sub_subdir in sub_subdirs:
                    sub_subdir_path = "{:s}/{:s}".format(subdir_path, sub_subdir)
                    sub_subdir_path_contents = os.listdir(sub_subdir_path)
                    # print "Is it one of:\n\t" + "\n\t".join(sub_subdir_path_contents)
                    if (_CTAT_Build_dirname in sub_subdir_path_contents):
                        # The genome_build_directory is inside of the sub_subdir_path directory.
                        print "3a. Found one."
                        build_dirs_in_sub_subdirs.append("{:s}/{:s}".format(sub_subdir_path, _CTAT_Build_dirname))
                    if (_CTAT_RefGenome_Filename in sub_subdir_path_contents):
                        sub_subdirs_with_genome_files.append(sub_subdir_path)
            # Hopefully there is one and only one found build directory.
            # If none are found we check for a directory containing the genome reference file,
            # but the build process sometimes causes more than one directory to have a copy,
            # so finding that file is not a sure thing.
            if (len(build_dirs_in_subdirs) + len(build_dirs_in_sub_subdirs)) > 1:
                print "\n***************************************"
                print "Found multiple CTAT Genome Resource Libraries " + \
                    "in the given directory:\n\t{:s}".format(top_dir_full_path)
                print_directory_contents(top_dir_full_path, 2)
                print "***************************************\n"
                raise ValueError("Found multiple CTAT Genome Resource Libraries " + \
                    "in the given directory:\n\t{:s}".format(top_dir_full_path))
            elif len(build_dirs_in_subdirs) == 1:
                # The genome_build_directory is inside of the subdir_path directory.
                print "2b, Found it."
                genome_build_directory = build_dirs_in_subdirs[0]
            elif len(build_dirs_in_sub_subdirs) == 1:
                # The genome_build_directory is inside of the subdir_path directory.
                print "3b, Found it."
                genome_build_directory = build_dirs_in_sub_subdirs[0]
            elif (len(sub_subdirs_with_genome_files) + len(subdirs_with_genome_files)) > 1:
                print "\n***************************************"
                print "Unable to find CTAT Genome Resource Library " + \
                      "in the given directory:\n\t{:s}".format(top_dir_full_path)
                print "And multiple directories contain {:s}".format(_CTAT_RefGenome_Filename)
                print_directory_contents(top_dir_full_path, 2)
                print "***************************************\n"
                raise ValueError("Unable to find CTAT Genome Resource Library " + \
                    "in the given directory:\n\t{:s}".format(top_dir_full_path))
            elif (len(sub_subdirs_with_genome_files) == 1):
                print "3c, Maybe found it."
                genome_build_directory = sub_subdirs_with_genome_files[0]
                print_warning = True
            elif (len(subdirs_with_genome_files) == 1):
                print "2c, Maybe found it."
                genome_build_directory = subdirs_with_genome_files[0]
                print_warning = True
            elif (_CTAT_RefGenome_Filename in top_dir_contents):
                print "1c. Maybe found it."
                genome_build_directory = top_dir_full_path
                print_warning = True
            else:
                print "\n***************************************"
                print "Unable to find CTAT Genome Resource Library " + \
                      "in the given directory:\n\t{:s}".format(top_dir_full_path)
                print_directory_contents(top_dir_full_path, 2)
                print "***************************************\n"
                raise ValueError("Unable to find CTAT Genome Resource Library " + \
                    "in the given directory:\n\t{:s}".format(top_dir_full_path))
        # end else
    # Check if the CTAT Genome Resource Lib has anything in it (and specifically ref_genome.fa).
    if (genome_build_directory is None):
        print "\n***************************************"
        print "Cannot find the CTAT Genome Resource Library " + \
            "in the given directory:\n\t{:s}".format(top_dir_full_path)
        print_directory_contents(top_dir_full_path, 2)
        print "***************************************\n"
        raise ValueError("Cannot find the CTAT Genome Resource Library " + \
            "in the given directory:\n\t{:s}".format(top_dir_full_path))
    else:
        if (_CTAT_RefGenome_Filename not in os.listdir(genome_build_directory)):
            print "\n***************************************"
            print "\nWARNING: Cannot find Genome Reference file {:s}".format(_CTAT_RefGenome_Filename) + \
                "in the genome build directory:\n\t{:s}".format(genome_build_directory)
            print_directory_contents(genome_build_directory, 2)
            print "***************************************\n"
        if print_warning and genome_build_directory:
            print "\n***************************************"
            print "\nWARNING: Cannot find the CTAT Genome Resource Library," + \
                "but found a {:s} file, so set its directory as the library.".format(_CTAT_RefGenome_Filename)
            print "This my not be the correct directory:\n\t{:s}".format(genome_build_directory)
            print_directory_contents(genome_build_directory, 2)
            print "***************************************\n"
    return genome_build_directory

def find_genome_name_in_path(path):
    # The form of the genome name in directory names (if present in the path) looks like:
    # GRCh37_v19_CTAT_lib_Feb092018
    # Mouse_M16_CTAT_lib_Feb202018
    genome_name = None
    if (path is not None) and (path != ""):
        for element in path.split("/"):
            # print "Looking for genome name in {:s}.".format(element)
            if (element[0:len(_CTAT_MouseGenome_Prefix)] == _CTAT_MouseGenome_Prefix) \
                or (element[0:len(_CTAT_HumanGenome_Prefix)] == _CTAT_HumanGenome_Prefix):
                # Remove any extension that might be in the filename.
                genome_name = element.split(".")[0]
    return genome_name

def main():
    #Parse Command Line. There are three basic ways to use this tool.
    # 1) Download and Build the CTAT Genome Resource Library from an archive.
    # 2) Build the library from source data files that are already downloaded.
    # 3) Specify the location of an already built library.
    # Any of these methods can be incorporate or be followed by a gmap build.
    # Choose arguments for only one method.
    # Do not use arguments in a mixed manner. I am not writing code to handle that at this time.
    parser = argparse.ArgumentParser()
    # Arguments for all methods:
    parser.add_argument('-o', '--output_filename', \
        help='Name of the output file, where the json dictionary will be written.')
    parser.add_argument('-y', '--display_name', default='', \
        help='Is used as the display name for the entry of this Genome Resource Library in the data table.')
    parser.add_argument('-g', '--gmap_build', \
        help='Must be selected if you want the library to be gmapped. ' + \
             'Will force gmap_build of the Genome Resource Library, even if previously gmapped.', action='store_true')
    parser.add_argument('-m', '--download_mutation_indexes_url', default='', \
        help='Set to the url of the mutation indexes for the Library. ' + \
             'Will download mutation indexes into the Genome Resource Library.', action='store_true')
    parser.add_argument('-i', '--new_mutation_indexes_download', \
        help='Forces the mutation indexes to download, ' + \
             'even if previously downloaded to this Library.', action='store_true')
    # Method 1) arguments - Download and Build.
    download_and_build_args = parser.add_argument_group('Download and Build arguments')
    download_and_build_args.add_argument('-u', '--download_url', default='', \
        help='This is the url of am archive file containing the library files. ' + \
            'These are located at https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/.')
    download_and_build_args.add_argument('-d', '--download_location', default='', \
        help='Full path of the CTAT Resource Library download location, where the download will be placed. If the archive file has already had been successfully downloaded, it will only be downloaded again if --new_download is selected.')
    download_and_build_args.add_argument('-a', '--new_archive_download', \
        help='Forces download of the Genome Resource Library, even if previously downloaded to the download_destination.', action='store_true')
    # Method 2) arguments - Specify location of source and build.
    specify_source_and_build_args = parser.add_argument_group('Specify Source and Build arguments')
    specify_source_and_build_args.add_argument('-s', '--source_location', default='', \
        help='Full path to the location of CTAT Resource Library source files. The --build_location must also be set.')
    specify_source_and_build_args.add_argument('-r', '--rebuild', \
        help='Forces build/rebuild the CTAT Genome Resource Library, even if previously built. ' + \
             'Must specify location of the source_data for this to work.', action='store_true')
    # Method 3) arguments - Specify the location of a built library.
    built_lib_location_arg = parser.add_argument_group('Specify location of built library arguments')
    built_lib_location_arg.add_argument('-b', '--build_location', default='', \
        help='Full path to the location of a built CTAT Genome Resource Library, either where it is, or where it will be placed.')

    args = parser.parse_args()

    # All of the input parameters are written by default to the output file prior to
    # this program being called.
    # But I do not get input values from the json file, but rather from command line.
    # Just leaving the following code as a comment, in case it might be useful to someone later.
    # params = from_json_string(open(filename).read())
    # target_directory = params['output_data'][0]['extra_files_path']
    # os.mkdir(target_directory)

    print "The value of download_url argument is:\n\t{:s}".format(str(args.download_url))

    # FIX - not sure lib_was_downloaded actually serves a purpose...
    # The original intent was to check whether an attempted download actually succeeded before proceeding,
    # but I believe that in those situations, currently, exceptions are raised.
    # FIX - Need to double check that. Sometimes, although we are told to download, the function
    # could find that the files are already there, successfully downloaded from a prior attempt,
    # and does not re-download them.
    lib_was_downloaded = False
    lib_was_built = False
    downloaded_directory = None
    source_data_directory = None
    genome_build_directory = None
    # FIX - need to make sure we are handling all "possible" combinations of arguments.
    # Probably would be good if we could simplify/remove some of them.
    # But I think the current interface is using them all.

    if (args.download_url != ""):
        if (args.source_location):
            raise ValueError("Argument --source_location cannot be used in combination with --download_url.")
        if (args.build_location):
            raise ValueError("Argument --build_location cannot be used in combination with --download_url.")
        if (args.download_location is None) or (args.download_location == ""):
            raise ValueError("Argument --download_url requires that --download_location be specified.")
        downloaded_directory, download_has_source_data, genome_build_directory, lib_was_downloaded = \
            download_from_BroadInst(source=args.download_url, \
                                    destination=args.download_location, \
                                    force_download=args.new_archive_download)
        print "\nThe location of the downloaded_directory is {:s}.\n".format(str(downloaded_directory))
        if download_has_source_data:
            print "It is source data."
            source_data_directory = downloaded_directory
            if (genome_build_directory == None) or (genome_build_directory == ""):
                raise ValueError("Programming Error: The location for building the genome_build_directory " + \
                    "was not returned by download_from_BroadInst()")
        else:
            print "It is plug-n-play data."
            genome_build_directory = search_for_genome_build_dir(downloaded_directory)
    elif (args.source_location):
        # Then the user wants to build the directory from the source data.
        if (args.build_location is None) or (args.build_location == ""):
            raise ValueError("Argument --source_location requires that --build_location be specified.")
        source_data_directory = os.path.realpath(args.source_location)
        genome_build_directory = os.path.realpath(args.build_location)
        print "\nThe location of the source data is {:s}.\n".format(str(source_data_directory))
    elif (args.build_location is not None) and (args.build_location != ""):
        genome_build_directory = args.build_location
    else:
        raise ValueError("One of --download_url, --source_location, or --build_location must be specified.")
        
    print "\nThe location where the CTAT Genome Resource Library exists " + \
        "or will be built is {:s}.\n".format(genome_build_directory)

    # FIX - We should leave a file indicating build success the same way we do for download success.
    # To take out builds for testing, comment out the lines that do the building.
    # The command that builds the ctat genome library also has an option for building the gmap indexes.
    # That is why the gmap_build value is sent to build_the_library(), but if we are not building the
    # library, the user might still be asking for a gmap_build. That is done after rechecking for the
    # genome_build_directory.
    if (source_data_directory is not None):
        build_the_library(source_data_directory, \
                          genome_build_directory, \
                          args.rebuild, \
                          args.gmap_build)
        lib_was_built = True
    elif genome_build_directory is None:
        raise ValueError("No CTAT Genome Resource Library was downloaded, " + \
            "there is no source data specified, " + \
            "and no build location has been set. " + \
            "This line of code should never execute.")
    # The following looks to see if the library actually exists after the build,
    # and raises an error if it cannot find the library files.
    # The reassignment of genome_build_directory should be superfluous, 
    # since genome_build_directory should already point to the correct directory,
    # unless I made a mistake somewhere above.

    genome_build_directory = search_for_genome_build_dir(genome_build_directory)

    if (args.gmap_build and not lib_was_built):
        # If we did not build the genome resource library
        # the user might still be asking for a gmap_build.
        gmap_the_library(genome_build_directory)

    if (args.download_mutation_indexes_url != ""):
        download_mutation_indexes(source_url=args.download_mutation_indexes_url, \
                                  genome_build_directory=genome_build_directory, \
                                  force_download=args.new_mutation_indexes_download)

    # Need to get the genome name.
    genome_name = find_genome_name_in_path(args.download_url)
    if genome_name is None:
        genome_name = find_genome_name_in_path(genome_build_directory)
    if genome_name is None:
        genome_name = find_genome_name_in_path(downloaded_directory)
    if genome_name is None:
        genome_name = find_genome_name_in_path(args.source_location)
    if genome_name is None:
        genome_name = find_genome_name_in_path(args.download_location)
    if genome_name is None:
        genome_name = find_genome_name_in_path(args.display_name)
    if genome_name is None:
        genome_name = _CTAT_ResourceLib_DefaultGenome
        print "WARNING: We could not find a genome name in any of the directory paths."

    # Determine the display_name for the library.
    if (args.display_name is None) or (args.display_name == ""):
        # Create the display_name from the genome_name.
        display_name = _CTAT_ResourceLib_DisplayNamePrefix + genome_name
    else:
        display_name = _CTAT_ResourceLib_DisplayNamePrefix + args.display_name
    display_name = display_name.replace(" ","_")

    # Create a unique_id for the library.
    datetime_stamp = datetime.now().strftime("_%Y_%m_%d_%H_%M_%S_%f")
    unique_id = genome_name + "." + datetime_stamp

    print "The Genome Resource Library's display_name will be set to: {:s}\n".format(display_name)
    print "Its unique_id will be set to: {:s}\n".format(unique_id)
    print "Its dir_path will be set to: {:s}\n".format(genome_build_directory)

    data_manager_dict = {}
    data_manager_dict['data_tables'] = {}
    data_manager_dict['data_tables']['ctat_genome_resource_libs'] = []
    data_table_entry = dict(value=unique_id, name=display_name, path=genome_build_directory)
    data_manager_dict['data_tables']['ctat_genome_resource_libs'].append(data_table_entry)

    # Temporarily the output file's dictionary is written for debugging:
    print "The dictionary for the output file is:\n\t{:s}".format(str(data_manager_dict))
    # Save info to json file. This is used to transfer data from the DataManager tool, to the data manager,
    # which then puts it into the correct .loc file (I think).
    # Comment out the following line when testing without galaxy package.
    open(args.output_filename, 'wb').write(to_json_string(data_manager_dict))

if __name__ == "__main__":
    main()
