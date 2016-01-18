#!/usr/bin/env ruby

require "bundler/setup"
require "./spreadsheet"
require "./window"

sheet = Spreadsheet.new
[
  "Sum",
  10,
  20,
  30,
  "",
  "=A2 + A3 + A4",
  "=SUM(A2; A3; A4)",
  "=SUM(A2:A4)"
].each_with_index do |cel, index|
  sheet["A#{index + 1}"] = cel
end

# Fibonacci
sheet[:B1] = "Fibonacci"
sheet[:B2] = 0
sheet[:B3] = 1
4.upto(30).each do |n|
  sheet["B#{n}"] = "=B#{n - 1} + B#{n - 2}"
end

window = Window.new(sheet)
window.start
