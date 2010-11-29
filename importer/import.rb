require 'rubygems'
require 'nokogiri'
require 'json'
require 'pp'
require 'couchrest'

unless @path = ARGV.shift
  puts "Provide the dump path on the command line"
  exit
end

unless File.directory? @path
  puts "Directory doesn't exist"
  exit
end

@db = CouchRest.database!("http://127.0.0.1:5984/stack_underflow")



class MyDoc < Nokogiri::XML::SAX::Document

  def initialize(block, limit_rows)
    @block = block
    @limit_rows = limit_rows
    @curr_row = 0
  end
  
  def start_element name, attributes = []
    if name == 'row'
      return if !@limit_rows.nil? && @limit_rows <= @curr_row
      begin
        @block.call Hash[*attributes.flatten(1)]
      rescue Exception => e
        puts "Error processing row: " + attributes.to_s
        puts e
        puts e.backtrace
      end
      @curr_row += 1
    end
  end
end


def get_rows(filename, limit_rows = nil, &block)
  parser = Nokogiri::HTML::SAX::Parser.new(MyDoc.new(block, limit_rows))
  parser.parse(File.open(filename))
end


# Get last updated date from DB MapRed Function


# Temp batch storage
batch = []

# Import users, using modified date and check if already exists, then update/delete. ID is user-SQLID
get_rows(@path + 'users.xml') do |row|
  row['_id'] = 'user_' + row['Id']
  row['kind'] = 'user' # for indexing
  row['CreationDate'] = row['CreationDate'] + '+0000'
  row['LastAccessDate'] = row['LastAccessDate'] + '+0000'
  batch << row
  # Load, compare elements, save.
  if batch.size > 2000
    puts "Batch Saving Posts"
    @db.bulk_save(batch)
    batch = []
  end
end

puts "(cleanup) Batch Saving Posts"
@db.bulk_save batch
batch = []

# So we can link to parent post ID in subpost comments
parent_ids = {}

get_rows(@path + 'posts.xml') do |row|
  # TODO - Lookup LastDate MapRedFun (for posts only). Only action if Creation or LastEdit date is greater
  row['kind'] = 'post' # for indexing
  row['CreationDate'] = row['CreationDate'] + '+0000'
  row['LastEditDate'] = row['LastEditDate'] + '+0000' if row['LastEditDate']
  row['LastActivityDate'] = row['LastActivityDate'] + '+0000'
  row['LastEditorUserId'] = 'user_' + row['LastEditorUserId'] if row['LastEditorUserId']
  row['OwnerUserId'] = 'user_' + row['OwnerUserId'] if row['OwnerUserId']
  if row['PostTypeId'] == "2" # Child post
    parent_ids[row['Id']] = row['ParentId']
    row['ParentId'] = 'post_' + row['ParentId']
  end
  row['_id'] = 'post_' + row['Id']
  batch << row
  if batch.size > 2000
    puts "Batch Saving Posts"
    @db.bulk_save batch
    batch = []
  end
end

puts "(cleanup) Batch Saving Posts"
@db.bulk_save batch
batch = []

# Import comments, similar to posts. Find by post ID, look up parent doc if child. Goes in comments[]
# Add the Add the ParentId if we have a ParentId for this row in the hash
get_rows(@path + 'comments.xml') do |row|
  row['CreationDate'] = row['CreationDate'] + '+0000'
  row['LastEditDate'] = row['LastEditDate'] + '+0000' if row['LastEditDate']
  row['kind'] = 'comment'

  # ParentId is the ID of the Parent post if in the Hash, otherwise it's nil
  row['ParentId'] = 'post_' + parent_ids[row['PostId']] if parent_ids[row['PostId']]
  row['UserId'] = 'user_' + row['UserId'] if row['UserId']

  row['PostId'] = 'post_' + row['PostId']

  row['_id'] = 'comment_' + row['Id']

  batch << row

  if batch.size > 2000
    puts "Batch Saving Comments"
    @db.bulk_save batch
    batch = []
  end

end

puts "(cleanup) Batch Saving Comments"
@db.bulk_save batch
batch = []

# Votes don't need to be imported, but we need to sort in the view by score.
