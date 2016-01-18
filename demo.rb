#!/usr/bin/env ruby

require "bundler/setup"
require "./spreadsheet"
require "./window"

sheet = Spreadsheet.new
sheet[:A1] = 10
sheet[:A2] = 20
sheet[:A3] = 30
sheet[:A4] = "=A1 + A2 + A3"
sheet[:A5] = "=SUM(A1:A3)"

# Fibonacci
sheet[:B1] = 0
sheet[:B2] = 1
3.upto(300).each do |n|
  sheet["B#{n}"] = "=B#{n - 1} + B#{n - 2}"
end

window = Window.new(sheet)
window.start
