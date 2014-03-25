require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  #add_filter 'endoreportbot.rb'
end

require 'faker'
require_relative '../report'
require_relative '../endoreportbot'

#SimpleCov.minimum_coverage 90
