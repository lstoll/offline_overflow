# More info at http://github.com/guard/guard#readme

guard 'coffeescript', :output => 'app/_attachments/js/compiled' do
  watch(%r(^app/_attachments/coffee/(.*)\.coffee))
end

guard 'shell' do
  watch(%r(app/(.*).(js|mustache|html|css))) {|m| `cd app && couchapp push vps` }
end
