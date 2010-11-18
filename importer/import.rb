require 'rubygems'
require 'xml'
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

def get_rows(filename, limit_rows = nil)
  curr_row = 0
  File.open(filename) do |io|
    dblp = XML::Reader.io(io, :options => XML::Reader::SUBST_ENTITIES)
    while dblp.read do
      if dblp.name == 'row'
          break if !limit_rows.nil? && limit_rows <= curr_row
          yield row = dblp.expand.attributes.to_h
          curr_row += 1
      end
    end
  end
end

# Get last updated date from DB MapRed Function

## Import users, using modified date and check if already exists, then update/delete. ID is user-SQLID
get_rows(@path + 'users.xml', 1500) do |row|
  row['_id'] = 'user_' + row['Id']
  row['kind'] = 'user' # for indexing
  row['CreationDate'] = row['CreationDate'] + '+0000'
  row['LastAccessDate'] = row['LastAccessDate'] + '+0000'
  # Load, compare elements, save.
  @db.batch_save_doc(row)
end


get_rows(@path + 'posts.xml', 1500) do |row|
  # TODO - Lookup LastDate MapRedFun (for posts only). Only action if Creation or LastEdit date is greater
  row['kind'] = 'post' # for indexing
  row['CreationDate'] = row['CreationDate'] + '+0000'
  row['LastEditDate'] = row['LastEditDate'] + '+0000' if row['LastEditDate']
  row['LastActivityDate'] = row['LastActivityDate'] + '+0000'
  row['LastEditorUserId'] = 'user_' + row['LastEditorUserId'] if row['LastEditorUserId']
  row['OwnerUserId'] = 'user_' + row['OwnerUserId'] if row['OwnerUserId']
  row['comments'] = []
  if row['PostTypeId'] != "2" # Wiki or parent post
    row['_id'] = 'post_' + row['Id']
    row['answers'] = []
    begin
      @db.save_doc(row)
    rescue RestClient::Conflict => e
      #ignore
    end
  else
    # Find parent doc, add to an array.
    begin
      parent = @db.get('post_' + row['ParentId'])
      unless parent['answers'].any? {|i| i['Id'] == row['Id']}
        parent['answers'] << row 
        @db.save_doc(parent)
      end
    rescue
      puts "Error loading parent doc ID " + row['ParentId']
    end
  end
end

# Import comments, similar to posts. Find by post ID, look up parent doc if child. Goes in comments[]
get_rows(@path + 'comments.xml', 500) do |row|
  row['CreationDate'] = row['CreationDate'] + '+0000'
  row['LastEditDate'] = row['LastEditDate'] + '+0000' if row['LastEditDate']
  # Find the post.
  res = @db.view('app/postsBySqlId', {:key => row['PostId'], :include_docs => true})
  if postdoc = res['rows'][0]
    postdoc = postdoc['doc']
    if postdoc['Id'] = row['PostId']
      postdoc['comments'] << row
      @db.save_doc(postdoc)
    else
      postdoc['answers'].each do |post|
        if postdoc['Id'] = row['PostId']
          post['comments'] << row
          @db.save_doc(postdoc)
        end
      end
    end
  end
end

# Votes don't need to be imported, but we need to sort in the view by score.
