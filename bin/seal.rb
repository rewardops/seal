#!/usr/bin/env ruby

require 'dotenv'
Dotenv.load

require './lib/seal'
Seal.new(ARGV[0], ARGV[1]).bark
