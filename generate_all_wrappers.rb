#!/usr/bin/ruby
require 'erb'
require "rexml/document"
erb = ERB.new(File.read("demoWrapperTemplate.erb"))
@dirname = "Demos"


def GetSubdirs()
  results = Array.new
  # both methods should work the same (I think one returns the  directory  names in addition to the files)
  Dir["#{@dirname}/*"].each do |file|
    #file.gsub!(/\//, '\\')
    if File.directory?(file)
      results.push(file)
    end
  end
  return results
end


GetSubdirs().each do |file|
  puts file

  Dir.chdir("#{file}")
  puts Dir["*.swf"][0]
  name = Dir["*.swf"][0]
  puts name, "name"
  demoWidth = 800
  demoHeight = 600
  file = File.open("index.html", "w")
  file.write( erb.result(binding) )
  Dir.chdir("../..")
  end