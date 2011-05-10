require 'waz-blobs'

#
# Constants for accessing your azure account
#
# access key is the really long guid that is generated
@access_key = ""
# account name is the name of the storage. So buddystore.blob.core.windows.net
# the account name would be buddystore
@account_name = ""
# what is the name of the container you want to put "stuff" in
# I usually use the name of the computer I am on
@main_container_name = ""

#
# helper methods
#

def all_filesystem_files
  `ls`.split("\n") 
end

def file_type(filename)
  `file -Ib #{filename}`.gsub(/\n/,"").split('; ')[0]
end

WAZ::Storage::Base.establish_connection!(:account_name => @account_name, :access_key => @access_key)

#
# Gets the container if it doesn't exist it creates it
#
container = WAZ::Blobs::Container.find(@main_container_name)

if container.nil? then
  WAZ::Blobs::Container.create(@main_container_name)
  container = WAZ::Blobs::Container.find(@main_container_name)
end

# 
# Gets a list of all the new files on the file system
# and is ready to upload them to azure
#

azure_files = container.blobs.map(&:name)
local_files = all_filesystem_files

intersection = azure_files & local_files

final_files = local_files - intersection
final_files.delete("azure-sync.rb")
final_files.delete("README")

# 
# Uploads the new files to azure
#
if final_files.size > 0 then
  final_files.each do |f|
    container.store(f, File.open(f), file_type(f))
  end
end
