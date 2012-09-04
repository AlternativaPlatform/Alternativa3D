require 'erb'
require "rexml/document"


erb = ERB.new(File.read("../../demoWrapperTemplate.erb"))
name = ARGV[0]
demoWidth = ARGV[1] || 600
demoHeight = ARGV[2] || 600
puts @demoHeight, @demoWidth

file = File.open("index.html", "w")
file.write( erb.result() )