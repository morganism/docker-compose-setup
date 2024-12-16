#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'

require_relative '../lib/class_script'

options = OpenStruct.new 
options.number = 2
options.classes = 'apt'
cs = ClassScript.new(options)
cs.print
