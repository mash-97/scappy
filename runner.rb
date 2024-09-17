categories = {
  "Data Science & Analytics" => 531770282580668420,

  "Engineering & Architecture"  => 531770282584862722,

  "IT & Networking" => 531770282580668419,

  "Web, Mobile & Software Dev" => 531770282580668418
}


puts("> Start of the runner script")
puts("> Start Page: #{ARGV[0]}")
puts("> End Page: #{ARGV[1]}")
puts("> Run Count: #{ARGV[2]}")

s = Time.now
categories.each do |k, v|
  puts(">> start process for: #{k}")
  system("ruby scappy.rb scrap --start_page #{ARGV[0]} --end_page #{ARGV[1]} --category #{v} --output '#{k}.xlsx' --sheet_name 'Run #{ARGV[2]}")
  puts(">> finished process for: #{k}")
  puts
end
e = Time.now
puts("> End of the runner script")
puts("> Execution Time: #{(e-s).round(3)} seconds")
