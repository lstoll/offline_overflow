# More info at http://github.com/guard/guard#readme

guard 'coffeescript', :output => 'app/_attachments/js/compiled' do
  watch('^app/_attachments/coffee/(.*)\.coffee')
end

guard 'shell' do
  watch('app/(.*).(js|mustache|html|css)') {|m| `cd app && couchapp push` }
end
