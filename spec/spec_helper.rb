require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter 'endobot.rb'
end

require 'faker'
require_relative '../report'
require_relative '../endobot'

SimpleCov.minimum_coverage 90